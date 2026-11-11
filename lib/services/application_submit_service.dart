import 'dart:developer' as developer;

import 'package:get/get.dart';

import '../config/api_config.dart';
import '../controllers/onboarding_controller.dart';
import '../controllers/onboarding_document_store.dart';
import 'driver_api_client.dart';

class ApplicationSubmitService extends GetxService {
  ApplicationSubmitService(this._apiClient);

  final DriverApiClient _apiClient;

  Future<void> submitApplication() async {
    final onboarding = Get.find<OnboardingController>();
    final documents = Get.find<OnboardingDocumentStore>();

    final payload = {
      'phone': onboarding.phone,
      'name': onboarding.name,
      'city': onboarding.city,
      'referralCode': onboarding.referralCode,
      'vehicleName': onboarding.vehicleName,
      'registrationNumber': onboarding.registrationNumber,
      'category': onboarding.category,
      'licenseNumber': onboarding.licenseNumber,
      'aadharNumber': onboarding.aadharNumber,
      'panNumber': onboarding.panNumber,
      'bankName': onboarding.bankName,
      'accountNumber': onboarding.accountNumber,
      'ifscCode': onboarding.ifscCode,
      'accountHolder': onboarding.accountHolder,
      'documents': documents.toSubmitPayload(),
    };

    developer.log('Step 7: Submit application with documents', name: 'DocumentUpload');

    final response = await _apiClient.dio.post(
      ApiConfig.submitApplicationPath,
      data: payload,
    );

    final data = response.data;
    if (data is Map) {
      final valid = data['validDocument'] == true ||
          data['valid'] == true ||
          data['success'] == true;
      if (!valid) {
        final message = data['message']?.toString() ??
            'Please upload the correct document';
        throw Exception(message);
      }

      final urls = data['documentUrls'];
      if (urls is List) {
        for (final url in urls) {
          print('[DocumentUpload] Application document URL: $url');
          developer.log('Application document URL: $url', name: 'DocumentUpload');
        }
      }
    }
  }
}
