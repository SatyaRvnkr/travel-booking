class UploadedDocument {
  final String objectKey;
  final String fileUrl;
  final bool validDocument;

  const UploadedDocument({
    required this.objectKey,
    required this.fileUrl,
    required this.validDocument,
  });
}

/// Matches backend:
/// `{ "status": true, "message": "...", "data": { "uploadUrl", "key", "expiresIn" } }`
class PresignedUrlResponse {
  final bool status;
  final String message;
  final String uploadUrl;
  final String key;
  final int? expiresIn;

  PresignedUrlResponse({
    required this.status,
    required this.message,
    required this.uploadUrl,
    required this.key,
    this.expiresIn,
  });

  /// Alias used by upload service.
  String get presignedUrl => uploadUrl;
  String get objectKey => key;

  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) {
    final root = Map<String, dynamic>.from(json);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;

    final uploadUrl = data['uploadUrl']?.toString() ??
        data['presignedUrl']?.toString() ??
        '';
    final key =
        data['key']?.toString() ?? data['objectKey']?.toString() ?? '';

    return PresignedUrlResponse(
      status: root['status'] == true || root['success'] == true,
      message: root['message']?.toString() ?? '',
      uploadUrl: uploadUrl,
      key: key,
      expiresIn: data['expiresIn'] is int
          ? data['expiresIn'] as int
          : int.tryParse(data['expiresIn']?.toString() ?? ''),
    );
  }

  /// Public file URL (no query params) from presigned upload URL + key.
  static String publicFileUrlFromUploadUrl(String uploadUrl, String key) {
    if (uploadUrl.isEmpty || key.isEmpty) return '';
    final uri = Uri.parse(uploadUrl);
    final normalizedKey = key.startsWith('/') ? key.substring(1) : key;
    return '${uri.scheme}://${uri.host}/$normalizedKey';
  }
}

class RegisterDocumentResponse {
  final bool validDocument;
  final String? fileUrl;
  final String? message;

  RegisterDocumentResponse({
    required this.validDocument,
    this.fileUrl,
    this.message,
  });

  factory RegisterDocumentResponse.fromJson(Map<String, dynamic> json) {
    final root = Map<String, dynamic>.from(json);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;

    return RegisterDocumentResponse(
      validDocument: root['status'] == true ||
          root['success'] == true ||
          data['validDocument'] == true ||
          data['valid'] == true ||
          data['isValid'] == true,
      fileUrl: data['fileUrl']?.toString() ?? data['url']?.toString(),
      message: root['message']?.toString() ?? data['message']?.toString(),
    );
  }
}
