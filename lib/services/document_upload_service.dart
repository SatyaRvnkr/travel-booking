import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../config/api_config.dart';
import '../config/presigned_upload_config.dart';
import '../models/document_type.dart';
import '../models/uploaded_document.dart';
import '../utils/upload_flow_logger.dart';
import 'driver_api_client.dart';
import 's3_presigned_upload.dart';

class DocumentUploadException implements Exception {
  DocumentUploadException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Pick image → POST upload-url → PUT S3 → POST save document.
class DocumentUploadService extends GetxService {
  DocumentUploadService(this._apiClient);

  final DriverApiClient _apiClient;

  Future<UploadedDocument> uploadDocument({
    required File file,
    required DocumentKind kind,
    required DocumentSide side,
  }) async {
    if (kind == DocumentKind.vehicleRc) {
      UploadFlowLogger.step(1, 'Vehicle RC upload skipped — no API payload');
      return const UploadedDocument(
        objectKey: '',
        fileUrl: '',
        validDocument: true,
      );
    }

    final contentType = _detectContentType(file.path);
    final fileName = _fileNameFor(file, kind, side);

    UploadFlowLogger.step(1, 'User selected image');
    UploadFlowLogger.json('Local file', file.path);
    UploadFlowLogger.json('fileName', fileName);
    UploadFlowLogger.json('contentType', contentType);
    UploadFlowLogger.json('Document', '${kind.apiValue} / ${side.apiValue}');

    final presigned = ApiConfig.mockUpload
        ? PresignedUploadConfig.get(kind, side)
        : await getUploadUrl(
            kind: kind,
            side: side,
            fileName: fileName,
            contentType: contentType,
          );

    UploadFlowLogger.step(3, 'PUT image to S3 presigned URL');
    UploadFlowLogger.json('uploadUrl', presigned.uploadUrl);
    UploadFlowLogger.json('key', presigned.key);

    try {
      await S3PresignedUpload.putFile(
        uploadUrl: presigned.uploadUrl,
        file: file,
        contentType: contentType,
      );
    } on HttpException catch (e) {
      UploadFlowLogger.error('S3 PUT', e.message, StackTrace.current);
      throw DocumentUploadException(e.message);
    }

    UploadFlowLogger.step(4, 'S3 upload successful (HTTP 200/204)');

    final fileUrl = PresignedUrlResponse.publicFileUrlFromUploadUrl(
      presigned.uploadUrl,
      presigned.key,
    );

    print('[UploadFlow] >>> S3 UPLOADED: $fileUrl');
    print('[UploadFlow] >>> S3 KEY: ${presigned.key}');

    var validDocument = true;
    try {
      final saved = await saveDocument(
        kind: kind,
        side: side,
        key: presigned.key,
        fileUrl: fileUrl,
        fileName: fileName,
        contentType: contentType,
      );
      if (saved != null) {
        validDocument = saved.validDocument;
        if (saved.fileUrl != null && saved.fileUrl!.isNotEmpty) {
          UploadFlowLogger.json('Saved fileUrl', saved.fileUrl);
        }
      }
    } on DocumentUploadException {
      rethrow;
    }

    UploadFlowLogger.step(6, 'Done');

    return UploadedDocument(
      objectKey: presigned.key,
      fileUrl: fileUrl,
      validDocument: validDocument,
    );
  }

  /// POST /api/driver/document/upload-url
  Future<PresignedUrlResponse> getUploadUrl({
    required DocumentKind kind,
    required DocumentSide side,
    required String fileName,
    required String contentType,
  }) async {
    UploadFlowLogger.step(
      2,
      'POST ${ApiConfig.presignedUrlPath} — request fresh presigned URL',
    );

    // Matches Postman: { documentType, side, contentType }
    final body = {
      'documentType': kind.apiValue,
      'side': side.apiValue,
      'contentType': contentType,
    };
    UploadFlowLogger.json('upload-url request', body);

    try {
      final response = await _apiClient.dio.post(
        ApiConfig.presignedUrlPath,
        data: body,
      );
      final parsed = PresignedUrlResponse.fromJson(_asMap(response.data));
      if (parsed.uploadUrl.isEmpty || parsed.key.isEmpty) {
        throw DocumentUploadException(
          parsed.message.isNotEmpty
              ? parsed.message
              : 'Backend did not return uploadUrl and key',
        );
      }
      UploadFlowLogger.json('upload-url response key', parsed.key);
      return parsed;
    } on DocumentUploadException {
      rethrow;
    } on DioException catch (e) {
      UploadFlowLogger.error('upload-url', e, e.stackTrace);
      throw DocumentUploadException(_dioMessage(e, 'Could not get upload URL'));
    }
  }

  /// POST /api/driver/document after S3 PUT succeeds.
  Future<RegisterDocumentResponse?> saveDocument({
    required DocumentKind kind,
    required DocumentSide side,
    required String key,
    required String fileUrl,
    required String fileName,
    required String contentType,
  }) async {
    if (ApiConfig.skipBackendSaveDocument) {
      UploadFlowLogger.step(
        5,
        'Skipping document-save API (SKIP_SAVE_DOCUMENT=true)',
      );
      return null;
    }

    UploadFlowLogger.step(
      5,
      'POST ${ApiConfig.saveDocumentUrlPath} — save S3 key',
    );

    final body = <String, dynamic>{
      'documentType': kind.apiValue,
      'side': side.apiValue,
      'key': key,
      'objectKey': key,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'contentType': contentType,
    };
    if (side == DocumentSide.back) {
      body['backImageKey'] = key;
    } else {
      body['frontImageKey'] = key;
    }
    UploadFlowLogger.json('save-document request', body);

    try {
      final response = await _apiClient.dio.post(
        ApiConfig.saveDocumentUrlPath,
        data: body,
      );
      final data = response.data;
      if (data is! Map) {
        return RegisterDocumentResponse(validDocument: true);
      }
      final parsed = RegisterDocumentResponse.fromJson(_asMap(data));
      final root = _asMap(data);
      if (root['success'] == false || root['status'] == false) {
        throw DocumentUploadException(
          parsed.message ?? 'Document save failed',
        );
      }
      return parsed;
    } on DocumentUploadException {
      rethrow;
    } on DioException catch (e) {
      UploadFlowLogger.error('save-document', e, e.stackTrace);
      throw DocumentUploadException(
        _dioMessage(
          e,
          'S3 upload succeeded but document save failed (key: $key)',
        ),
      );
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw DocumentUploadException('Unexpected API response');
  }

  String _dioMessage(DioException e, String fallback) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String? apiMessage;
    if (data is Map) {
      apiMessage = data['message']?.toString() ?? data['error']?.toString();
    } else if (data is String && data.isNotEmpty) {
      apiMessage = data;
    }
    if (status == 401) {
      return apiMessage ?? 'Sign in required to upload documents';
    }
    if (apiMessage != null && apiMessage.isNotEmpty) {
      return status != null ? 'HTTP $status — $apiMessage' : apiMessage;
    }
    if (status != null) return 'HTTP $status — $fallback';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Upload timed out. Check your network.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach server. Check your network.';
    }
    return fallback;
  }

  String _fileNameFor(File file, DocumentKind kind, DocumentSide side) {
    final original = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : '';
    if (original.contains('.') && original.length <= 80) {
      return original;
    }
    final ext = _extension(file.path);
    final sideName = side == DocumentSide.back ? 'back' : 'front';
    return '${kind.apiValue.toLowerCase()}_$sideName$ext';
  }

  String _extension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.webp')) return '.webp';
    return '.jpg';
  }

  String _detectContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
