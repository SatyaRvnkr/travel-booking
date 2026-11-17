import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:timelycabparcel_onboarding/widgets/custom_toast.dart';

import 'controllers/onboarding_controller.dart';
import 'services/api_urls.dart';
import 'services/auth_session.dart';
import 'widgets/onboarding_layout.dart';

class VehicalResistration extends StatefulWidget {
  const VehicalResistration({super.key});

  @override
  State<VehicalResistration> createState() => _VehicalResistrationState();
}

class _VehicalResistrationState extends State<VehicalResistration> {
  final TextEditingController _regController = TextEditingController();
  late final OnboardingController _controller;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<OnboardingController>();
  }
  //
  // void _goToRc() {
  //   _controller.registrationNumber = _regController.text.trim();
  //   _controller.category = _selectedCategory ?? '';
  //   _controller.goToVehicleRc();
  // }
  void _goToRc() {
    _controller.registrationNumber =
        _regController.text.trim();

    _controller.goToVehicleRc();
  }

  Future<void> _onNext() async {
    if (_isVerifying) return;

    final rcNumber = _regController.text.trim().toUpperCase();
    if (rcNumber.isEmpty || _controller.categoryId.isEmpty) {
      CustomToast.error(context,     'Required'
          'Please enter vehicle number and select vehicle category',);

      return;
    }

    setState(() => _isVerifying = true);
    try {
      final response = await http
          .post(
            Uri.parse(ApiUrls.verifyVehicleRc),
            headers: AuthSession.headers(),
            body: jsonEncode({
              'rcNumber': rcNumber,
              'categoryId': _controller.categoryId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('Vehicle RC verify status: ${response.statusCode}');
      debugPrint('Vehicle RC verify response: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        CustomToast.error(
          context,
          _messageFrom(
            response.body,
            'Unable to verify this vehicle RC.',
          ),
        );
        return;
      }

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (decoded is Map &&
          (decoded['success'] == false || decoded['status'] == false)) {
        CustomToast.error(
          context,
          'Unable to verify this vehicle RC.',
        );
        return;
      }

      _controller.registrationNumber = rcNumber;
      if (rcNumber.contains('MH')) {
        _showDuesDialog();
      } else {
        _goToRc();
      }
    } catch (e) {
      debugPrint('Vehicle RC verify error: $e');

      CustomToast.error(context, 'Verification failed'  'Unable to verify this vehicle RC. Please try again.',);

    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  String _messageFrom(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return fallback;
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
      bottomButton: primaryButton(
        label: _isVerifying ? 'Verifying...' : 'Next',
        onPressed: _isVerifying ? null : _onNext,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          onboardingField(
            hint: 'Vehicle registration number',
            controller: _regController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[A-Z0-9]'),
              ),
            ],
            textCapitalization: TextCapitalization.characters,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xffF3F3F3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _controller.category.isEmpty
                  ? 'Selected category'
                  : _controller.category,
              style: const TextStyle(fontWeight: FontWeight.w600),
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
