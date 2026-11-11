import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/onboarding_controller.dart';
import 'models/document_type.dart';
import 'widgets/document_upload_card.dart';
import 'widgets/onboarding_layout.dart';

class DriverLicenseScreen extends StatefulWidget {
  const DriverLicenseScreen({super.key});

  @override
  State<DriverLicenseScreen> createState() => _DriverLicenseScreenState();
}

class _DriverLicenseScreenState extends State<DriverLicenseScreen> {
  final TextEditingController _licenseController = TextEditingController();
  final OnboardingController _controller = Get.find();
  bool _canContinue = false;

  void _onContinue() {
    _controller.licenseNumber = _licenseController.text.trim();
    _controller.goToProfilePhoto();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      title: 'Driver license',
      subtitle: 'Upload front and back of your driving license',
      bottomButton: primaryButton(
        label: 'Upload & continue',
        onPressed: _canContinue && _licenseController.text.trim().isNotEmpty
            ? _onContinue
            : null,
      ),
      child: Column(
        children: [
          DocumentUploadCard(
            documentKind: DocumentKind.drivingLicense,
            onUploadStatusChanged: (complete) {
              setState(() => _canContinue = complete);
            },
          ),
          const SizedBox(height: 14),
          onboardingField(
            hint: 'License number',
            controller: _licenseController,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
