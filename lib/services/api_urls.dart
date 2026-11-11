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

  /// POST DigiLocker Aadhaar authorization URL.
  static const String aadhaarDigilockerInit =
      '$baseUrl/api/driver/aadhaar/digilocker/init';

  /// Backend should redirect the phone browser here after DigiLocker.
  /// Opens the Aadhaar screen with front and back photo upload.
  static const String aadhaarAppRedirect = 'timelycab://aadhaar';
}
