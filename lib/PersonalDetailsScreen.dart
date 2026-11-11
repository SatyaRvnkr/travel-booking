import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/onboarding_controller.dart';
import 'widgets/onboarding_layout.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final OnboardingController _controller = Get.find();
  late bool rcVerified;
  late bool licenseVerified;
  late bool profileVerified;

  @override
  void initState() {
    super.initState();
    rcVerified = !_controller.rcRejected;
    licenseVerified = true;
    profileVerified = true;
  }

  @override
  Widget build(BuildContext context) {
    final allVerified = rcVerified && licenseVerified && profileVerified;

    return OnboardingLayout(
      title: 'Personal Details',
      subtitle: 'Review your details before submitting',
      bottomButton: primaryButton(
        label: _controller.rcRejected ? 'Re-Submit Application' : 'Submit Application',
        onPressed: allVerified ? () => _controller.goToBank() : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Full Name', _controller.name),
          _detailRow('Phone', _controller.phone),
          _detailRow('City', _controller.city),
          _detailRow('Vehicle Registration', _controller.registrationNumber),
          _detailRow('Category', _controller.category),
          _detailRow('Driving License', _controller.licenseNumber),
          _detailRow('Aadhar', _controller.aadharNumber),
          _detailRow('PAN', _controller.panNumber),
          _detailRow('Vehicle Type', _controller.vehicleName),
          const SizedBox(height: 20),
          const Text(
            'Document Status',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _statusTile(
            'Vehicle RC',
            rcVerified,
            onTap: () {
              if (!rcVerified) _controller.goToRcFailed();
            },
          ),
          _statusTile('Driving license', licenseVerified),
          _statusTile('Profile Photo', profileVerified),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _controller.goToDocumentsReview(),
            child: const Text('View documents under review'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTile(String label, bool verified, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: verified ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: verified ? Colors.green.shade200 : Colors.red.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              verified ? Icons.check_circle : Icons.error_outline,
              color: verified ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
            if (!verified)
              const Text(
                'Re-upload',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
