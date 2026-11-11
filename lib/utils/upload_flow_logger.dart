import 'dart:developer' as developer;

/// Prints every step of: select → presigned URL → S3 PUT → file URL → backend.
class UploadFlowLogger {
  static void step(int number, String message) {
    final line = '[UploadFlow] Step $number: $message';
    print(line);
    developer.log(message, name: 'UploadFlow-Step$number');
  }

  static void json(String label, Object? data) {
    print('[UploadFlow] $label: $data');
    developer.log('$label: $data', name: 'UploadFlow');
  }

  static void error(String step, Object error, [StackTrace? stack]) {
    print('[UploadFlow] ERROR at $step: $error');
    developer.log('ERROR at $step: $error', name: 'UploadFlow', error: error, stackTrace: stack);
  }
}
