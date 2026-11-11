import '../models/document_type.dart';
import '../models/uploaded_document.dart';

/// Dev fallback only when `MOCK_UPLOAD=true`. Production uses the upload-url API.
class PresignedUploadConfig {
  /// Aadhaar front — update `uploadUrl` from Postman when expired.
  static const String aadharFrontUploadUrl =
      'https://cabdriver-bucket.s3.ap-south-1.amazonaws.com/drivers/f126cc3d-25c4-4246-bbab-43c35904b34e/aadhaar/b44dcd1f-9452-4893-9174-b9291b2967b8-front.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIASDZWV7PAU6WW2W7L%2F20260921%2Fap-south-1%2Fs3%2Faws4_request&X-Amz-Date=20260921T101644Z&X-Amz-Expires=300&X-Amz-Signature=c161cd2e75c732aa31286e77455c633e7844c1f4481f46d4dcb78841e868f039&X-Amz-SignedHeaders=host&x-amz-checksum-crc32=AAAAAA%3D%3D&x-amz-sdk-checksum-algorithm=CRC32&x-id=PutObject';

  static const String aadharFrontKey =
      'drivers/f126cc3d-25c4-4246-bbab-43c35904b34e/aadhaar/b44dcd1f-9452-4893-9174-b9291b2967b8-front.jpg';

  // Paste more URLs from Postman for other documents when needed:
  static const String aadharBackUploadUrl = '';
  static const String aadharBackKey = '';
  static const String vehicleRcFrontUploadUrl = '';
  static const String vehicleRcFrontKey = '';

  static PresignedUrlResponse get(DocumentKind kind, DocumentSide side) {
    final entry = _lookup(kind, side);
    if (entry.uploadUrl.isEmpty || entry.key.isEmpty) {
      throw PresignedUrlNotConfiguredException(
        'Paste presigned uploadUrl + key in presigned_upload_config.dart '
        'for ${kind.apiValue} ${side.apiValue}',
      );
    }
    return PresignedUrlResponse(
      status: true,
      message: 'Using presigned URL from config (no API)',
      uploadUrl: entry.uploadUrl,
      key: entry.key,
      expiresIn: 300,
    );
  }

  static _PresignedEntry _lookup(DocumentKind kind, DocumentSide side) {
    if (kind == DocumentKind.aadhar && side == DocumentSide.front) {
      return _PresignedEntry(aadharFrontUploadUrl, aadharFrontKey);
    }
    if (kind == DocumentKind.aadhar && side == DocumentSide.back) {
      return _PresignedEntry(aadharBackUploadUrl, aadharBackKey);
    }
    if (kind == DocumentKind.vehicleRc && side == DocumentSide.front) {
      return _PresignedEntry(vehicleRcFrontUploadUrl, vehicleRcFrontKey);
    }
    // Default: use aadhar front URL for testing other screens.
    if (aadharFrontUploadUrl.isNotEmpty) {
      return _PresignedEntry(aadharFrontUploadUrl, aadharFrontKey);
    }
    return const _PresignedEntry('', '');
  }
}

class _PresignedEntry {
  const _PresignedEntry(this.uploadUrl, this.key);
  final String uploadUrl;
  final String key;
}

class PresignedUrlNotConfiguredException implements Exception {
  PresignedUrlNotConfiguredException(this.message);
  final String message;
  @override
  String toString() => message;
}
