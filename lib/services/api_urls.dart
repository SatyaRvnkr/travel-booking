class ApiUrls {
  static const String baseUrl = 'https://cab-parcel-api.yesgobus.com';

  /// POST driver registration.
  static const String registerDriver = '$baseUrl/api/driver';

  /// POST OTP request.
  static const String requestDriverOtp =
      '$baseUrl/api/auth/driver/request-otp';

  /// POST OTP verification.
  static const String verifyDriverOtp =
      '$baseUrl/api/auth/driver/verify-otp';
}
