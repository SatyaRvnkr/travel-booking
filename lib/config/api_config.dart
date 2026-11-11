import '../services/api_urls.dart';

class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: ApiUrls.baseUrl,
  );

  static const String s3PublicBaseUrl = String.fromEnvironment(
    'S3_PUBLIC_BASE_URL',
    defaultValue: 'https://cabdriver-bucket.s3.ap-south-1.amazonaws.com',
  );

  /// Dev-only mock. Production: keep false (default).
  static const bool mockUpload = bool.fromEnvironment(
    'MOCK_UPLOAD',
    defaultValue: false,
  );

  /// Register uploaded document key with backend after S3 PUT succeeds.
  /// Pass `--dart-define=SKIP_SAVE_DOCUMENT=true` to skip while save API is not ready.
  static const bool skipBackendSaveDocument = bool.fromEnvironment(
    'SKIP_SAVE_DOCUMENT',
    defaultValue: true,
  );

  /// POST { documentType, side, contentType } — Postman "driver document upload presigned url"
  static const String presignedUrlPath = '/api/driver/document/upload-url';

  /// POST { documentType, side, key, fileUrl, contentType, frontImageKey|backImageKey }
  static const String saveDocumentUrlPath = '/api/driver/document';

  static const String submitApplicationPath = '/driver/application/submit';

  static const String mockDriverId = 'f126cc3d-25c4-4246-bbab-43c35904b34e';
}
