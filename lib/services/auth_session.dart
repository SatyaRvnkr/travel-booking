import 'package:get_storage/get_storage.dart';

/// Stores the access token from verify-OTP and builds auth headers for APIs.
class AuthSession {
  static const String tokenKey = 'access_token';

  static String? get token {
    final value = GetStorage().read(tokenKey)?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static void saveToken(String token) {
    GetStorage().write(tokenKey, token.trim());
  }

  static Map<String, String> headers({bool json = true}) {
    final headers = <String, String>{
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final value = token;
    if (value != null) {
      headers['Authorization'] = 'Bearer $value';
    }
    return headers;
  }

  /// Pulls a bearer token from common verify-OTP response shapes.
  static String? extractToken(dynamic decoded) {
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);

    const keys = [
      'accessToken',
      'access_token',
      'token',
      'jwt',
      'authToken',
      'idToken',
      'id_token',
    ];

    for (final key in keys) {
      final value = map[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') {
        return value.startsWith('Bearer ') ? value.substring(7).trim() : value;
      }
    }

    for (final nested in ['data', 'result', 'user', 'driver', 'tokens', 'auth']) {
      final found = extractToken(map[nested]);
      if (found != null) return found;
    }

    return null;
  }
}
