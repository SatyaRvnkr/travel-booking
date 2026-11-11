import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/onboarding_controller.dart';
import 'models/document_type.dart';
import 'widgets/document_upload_card.dart';
import 'widgets/onboarding_layout.dart';

class PanVerificationScreen extends StatefulWidget {
  const PanVerificationScreen({super.key});

  @override
  State<PanVerificationScreen> createState() => _PanVerificationScreenState();
}

class _PanVerificationScreenState extends State<PanVerificationScreen> {
  final TextEditingController _panController = TextEditingController();
  final OnboardingController _controller = Get.find();
  bool _canContinue = false;

  void _onContinue() {
    _controller.panNumber = _panController.text.trim();
    _controller.goToPersonalDetails();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      title: 'PAN verification',
      subtitle: 'Upload front and back of your PAN card',
      bottomButton: primaryButton(
        label: 'Upload & continue',
        onPressed: _canContinue && _panController.text.trim().length == 10
            ? _onContinue
            : null,
      ),
      child: Column(
        children: [
          DocumentUploadCard(
            documentKind: DocumentKind.pan,
            onUploadStatusChanged: (complete) {
              setState(() => _canContinue = complete);
            },
          ),
          const SizedBox(height: 14),
          onboardingField(
            hint: 'PAN number',
            controller: _panController,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
