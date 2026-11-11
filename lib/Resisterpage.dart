import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/onboarding_controller.dart';

class Resisterpage extends StatefulWidget {
  const Resisterpage({super.key});

  @override
  State<Resisterpage> createState() => _ResisterpageState();
}

class _ResisterpageState extends State<Resisterpage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  final OnboardingController _controller = Get.find();

  void _onNext() {
    if (_nameController.text.trim().isEmpty || _cityController.text.trim().isEmpty) {
      Get.snackbar('Required', 'Please enter name and city',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    _controller.name = _nameController.text.trim();
    _controller.city = _cityController.text.trim();
    _controller.referralCode = _referralController.text.trim();
    _controller.goToVehicleSelection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Container(width: double.infinity, color: const Color(0xffF8BE22)),
            Positioned(
              top: 190,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(23),
                    topRight: Radius.circular(23),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 30),
                              const Text(
                                'Registration is super simple.',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Please enter your details.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              customField('Name', _nameController),
                              customField('City', _cityController),
                              customField('Referral code (optional)', _referralController),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SafeArea(
                        top: false,
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _onNext,
                            child: const Text(
                              'Next',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget customField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xffF3F3F3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
