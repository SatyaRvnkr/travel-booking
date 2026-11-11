import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/onboarding_controller.dart';
import 'widgets/onboarding_layout.dart';

class DocumentsReviewScreen extends StatelessWidget {
  const DocumentsReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return OnboardingLayout(
      title: 'Documents Under Review',
      subtitle: 'Please wait while we review your uploaded documents',
      bottomButton: primaryButton(
        label: 'Check status',
        onPressed: () => controller.goToPersonalDetails(rejected: true),
      ),
      child: Column(
        children: [
          _reviewTile('Vehicle RC', 'Pending', Colors.orange),
          _reviewTile('Driving license', 'Pending', Colors.orange),
          _reviewTile('Profile Photo', 'Pending', Colors.orange),
          _reviewTile('Aadhar', 'Verified', Colors.green),
          _reviewTile('PAN', 'Verified', Colors.green),
        ],
      ),
    );
  }

  Widget _reviewTile(String label, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            status == 'Verified' ? Icons.check_circle : Icons.schedule,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
