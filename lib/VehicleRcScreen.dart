import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/onboarding_controller.dart';
import 'widgets/onboarding_layout.dart';

class VehicleRcScreen extends StatefulWidget {
  const VehicleRcScreen({super.key});

  @override
  State<VehicleRcScreen> createState() => _VehicleRcScreenState();
}

class _VehicleRcScreenState extends State<VehicleRcScreen> {
  final OnboardingController _controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      title: 'Vehicle RC',
      subtitle: 'You can continue without uploading RC for now',
      bottomButton: primaryButton(
        label: 'Upload & continue',
        onPressed: () => _controller.goToDriverLicense(),
      ),
      child: const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Vehicle RC file upload is skipped. Continue to the next step.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
    );
  }
}
