import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/onboarding_controller.dart';
import 'widgets/onboarding_layout.dart';

class VehicalResistration extends StatefulWidget {
  const VehicalResistration({super.key});

  @override
  State<VehicalResistration> createState() => _VehicalResistrationState();
}

class _VehicalResistrationState extends State<VehicalResistration> {
  final TextEditingController _regController = TextEditingController();
  late final OnboardingController _controller;
  String? _selectedCategory;

  final List<String> _categories = [
    'Private',
    'Commercial',
    'Goods Carrier',
    'Passenger',
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.find<OnboardingController>();
  }

  void _goToRc() {
    _controller.registrationNumber = _regController.text.trim();
    _controller.category = _selectedCategory ?? '';
    _controller.goToVehicleRc();
  }

  void _onNext() {
    if (_regController.text.trim().isEmpty || _selectedCategory == null) {
      Get.snackbar(
        'Required',
        'Please enter vehicle number and select category',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_regController.text.trim().toUpperCase().contains('MH')) {
      _showDuesDialog();
    } else {
      _goToRc();
    }
  }

  void _showDuesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vehicle pending dues for vehicle number',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _regController.text.trim().toUpperCase(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'There are pending dues on this vehicle. Please pay before continuing registration.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Get.snackbar(
                      'Payment',
                      'Redirecting to payment...',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    Future.delayed(const Duration(seconds: 1), _goToRc);
                  },
                  child: const Text('Pay Now', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _goToRc();
                  },
                  child: const Text('Continue anyway'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      title: 'Vehicle registration number',
      subtitle: 'Enter your vehicle details to continue',
      bottomButton: primaryButton(label: 'Next', onPressed: _onNext),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          onboardingField(
            hint: 'Vehicle registration number',
            controller: _regController,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xffF3F3F3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Categories'),
                value: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (_controller.vehicleImage.isNotEmpty)
                  Image.asset(_controller.vehicleImage, height: 36),
                if (_controller.vehicleImage.isNotEmpty) const SizedBox(width: 12),
                Text(
                  _controller.vehicleName.isEmpty
                      ? 'Selected vehicle'
                      : _controller.vehicleName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
