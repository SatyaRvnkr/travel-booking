import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/onboarding_controller.dart';
import 'widgets/onboarding_layout.dart';

class BankVerificationScreen extends StatefulWidget {
  const BankVerificationScreen({super.key});

  @override
  State<BankVerificationScreen> createState() => _BankVerificationScreenState();
}

class _BankVerificationScreenState extends State<BankVerificationScreen> {
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _confirmAccountController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _holderController = TextEditingController();
  final OnboardingController _controller = Get.find();

  bool get _isValid =>
      _bankNameController.text.trim().isNotEmpty &&
      _accountController.text.trim().length >= 8 &&
      _confirmAccountController.text.trim() == _accountController.text.trim() &&
      _ifscController.text.trim().length == 11 &&
      _holderController.text.trim().isNotEmpty;

  void _refresh() => setState(() {});

  void _onContinue() {
    _controller.bankName = _bankNameController.text.trim();
    _controller.accountNumber = _accountController.text.trim();
    _controller.ifscCode = _ifscController.text.trim();
    _controller.accountHolder = _holderController.text.trim();
    _controller.goToSubmitted();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      title: 'Bank account verification',
      subtitle: 'Enter your bank details for payouts',
      bottomButton: primaryButton(
        label: 'Continue',
        onPressed: _isValid ? _onContinue : null,
      ),
      child: Column(
        children: [
          onboardingField(
            hint: 'Bank name',
            controller: _bankNameController,
            onChanged: (_) => _refresh(),
          ),
          onboardingField(
            hint: 'Account number',
            controller: _accountController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _refresh(),
          ),
          onboardingField(
            hint: 'Confirm account number',
            controller: _confirmAccountController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _refresh(),
          ),
          onboardingField(
            hint: 'IFSC code',
            controller: _ifscController,
            onChanged: (_) => _refresh(),
          ),
          onboardingField(
            hint: 'Account holder name',
            controller: _holderController,
            onChanged: (_) => _refresh(),
          ),
        ],
      ),
    );
  }
}
