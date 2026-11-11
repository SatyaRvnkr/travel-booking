import 'dart:convert';
import 'dart:io';

import '../utils/upload_flow_logger.dart';

/// PUT file bytes to AWS S3 using a presigned URL.
/// For URLs signed with `X-Amz-SignedHeaders=host` only — sends NO Content-Type.
class S3PresignedUpload {
  static Set<String> signedHeaderNames(String uploadUrl) {
    final uri = Uri.parse(uploadUrl);
    final raw = uri.queryParameters['X-Amz-SignedHeaders'] ??
        uri.queryParameters['x-amz-signedheaders'] ??
        'host';
    return raw
        .split(';')
        .map((h) => h.trim().toLowerCase())
        .where((h) => h.isNotEmpty)
        .toSet();
  }

  /// Returns HTTP status code (200/204 = success for S3 PUT).
  static Future<int> putBytes({
    required String uploadUrl,
    required List<int> bytes,
    String? contentType,
  }) async {
    final uri = Uri.parse(uploadUrl);
    final signed = signedHeaderNames(uploadUrl);

    UploadFlowLogger.json('PUT target', uri.origin + uri.path);
    UploadFlowLogger.json('X-Amz-SignedHeaders', signed.join(';'));
    UploadFlowLogger.json('Body size (bytes)', bytes.length);

    final client = HttpClient();
    client.autoUncompress = true;
    try {
      final request = await client.putUrl(uri);
      request.persistentConnection = false;
      request.contentLength = bytes.length;

      // AWS presigned URL with X-Amz-SignedHeaders=host → do NOT add Content-Type.
      if (signed.contains('content-type') && contentType != null) {
        request.headers.set(HttpHeaders.contentTypeHeader, contentType);
        UploadFlowLogger.json('Content-Type header', contentType);
      } else {
        UploadFlowLogger.step(
          4,
          'X-Amz-SignedHeaders=host → PUT raw bytes, no extra headers',
        );
      }

      request.add(bytes);
      final response = await request.close();
      final statusCode = response.statusCode;

      UploadFlowLogger.json('S3 PUT HTTP status', statusCode);

      if (statusCode != 200 && statusCode != 204) {
        final body = await response
            .transform(utf8.decoder)
            .join()
            .catchError((_) => '');
        throw HttpException(
          'S3 PUT failed: HTTP $statusCode${body.isNotEmpty ? ' — $body' : ''}',
          uri: uri,
        );
      }

      await response.drain();
      return statusCode;
    } finally {
      client.close(force: true);
    }
  }

  static Future<int> putFile({
    required String uploadUrl,
    required File file,
    String? contentType,
  }) async {
    final bytes = await file.readAsBytes();
    return putBytes(
      uploadUrl: uploadUrl,
      bytes: bytes,
      contentType: contentType,
    );
  }
}
