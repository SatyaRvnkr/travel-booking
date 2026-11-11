import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/onboarding_controller.dart';
import 'widgets/onboarding_layout.dart';

class VehicleRcFailedScreen extends StatefulWidget {
  const VehicleRcFailedScreen({super.key});

  @override
  State<VehicleRcFailedScreen> createState() => _VehicleRcFailedScreenState();
}

class _VehicleRcFailedScreenState extends State<VehicleRcFailedScreen> {
  final OnboardingController _controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      title: 'Vehicle RC Verification Failed',
      subtitle: 'RC re-upload is skipped. Continue to the next step.',
      bottomButton: primaryButton(
        label: 'Continue',
        onPressed: () {
          _controller.rcRejected = false;
          _controller.goToDriverLicense();
        },
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Vehicle RC upload is skipped for now.',
                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
