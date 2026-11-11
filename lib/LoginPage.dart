import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:timelycabparcel_onboarding/services/api_urls.dart';

import 'controllers/onboarding_controller.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() =>
      _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {


  final OnboardingController _controller = Get.find();

  final TextEditingController _phoneController =
  TextEditingController();

  final TextEditingController _otpController =
  TextEditingController();

  final List<TextEditingController> _otpDigitControllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _otpFocusNodes =
  List.generate(6, (_) => FocusNode());

  bool _otpSent = false;
  bool _isLoading = false;
  bool _isVerifyingOtp = false;


  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();

    for (final controller in _otpDigitControllers) {
      controller.dispose();
    }

    for (final node in _otpFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }


  Future<void> _continueWithPhone() async {
    if (_isLoading || _otpSent) return;

    // Accept a 10-digit number, optionally prefixed with +91.
    final phone = _phoneController.text.trim();
    final mobile = phone.replaceAll(RegExp(r'\D'), '');

    final normalizedMobile =
    mobile.length == 12 && mobile.startsWith('91')
        ? mobile.substring(2)
        : mobile;

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(normalizedMobile)) {
      Get.snackbar(
        'Invalid Mobile Number',
        'Please enter a valid 10-digit Indian mobile number.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // STEP 1: Register driver.
      final registerResponse = await http
          .post(
        Uri.parse(ApiUrls.registerDriver),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'phoneNumber': normalizedMobile,
        }),
      )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        'Registration status: ${registerResponse.statusCode}',
      );
      debugPrint(
        'Registration response: ${registerResponse.body}',
      );

      if (registerResponse.statusCode < 200 ||
          registerResponse.statusCode >= 300) {
        _showError(
          'Registration Failed',
          _extractMessage(
            registerResponse.body,
            'Unable to register driver. Please try again.',
          ),
        );
        return;
      }

      // STEP 2: Request OTP.
      final otpResponse = await http
          .post(
        Uri.parse(ApiUrls.requestDriverOtp),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'phoneNumber': normalizedMobile,
        }),
      )
          .timeout(const Duration(seconds: 30));

      debugPrint('OTP status: ${otpResponse.statusCode}');
      debugPrint('OTP response: ${otpResponse.body}');

      if (otpResponse.statusCode >= 200 &&
          otpResponse.statusCode < 300) {
        _controller.phone = normalizedMobile;

        if (!mounted) return;

        setState(() {
          _otpSent = true;
          _otpController.clear();
        });

        Get.snackbar(
          'OTP Sent',
          'Please enter the six-digit OTP.',
          snackPosition: SnackPosition.BOTTOM,
        );

        // Do not navigate yet.
        // Wait until the user verifies the OTP.

        // Do not navigate yet.
        // Wait for the user to verify the OTP.
      } else {
        _showError(
          'OTP Request Failed',
          _extractMessage(
            otpResponse.body,
            'Unable to send OTP. Please try again.',
          ),
        );
      }
    } on http.ClientException catch (e) {
      debugPrint('HTTP error: $e');
      _showError(
        'Network Error',
        'Unable to connect to the server. Please try again.',
      );
    } on FormatException catch (e) {
      debugPrint('Response parsing error: $e');
      _showError(
        'Error',
        'The server returned an invalid response.',
      );
    } catch (e) {
      debugPrint('Registration or OTP error: $e');
      _showError(
        'Error',
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _verifyDriverOtp() async {
    if (_isVerifyingOtp) return;
    final otp = _otpDigitControllers
        .map((controller) => controller.text)
        .join();

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _showError(
        'Invalid OTP',
        'Please enter the complete six-digit OTP.',
      );
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      final response = await http
          .post(
        Uri.parse(ApiUrls.verifyDriverOtp),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'phoneNumber': _controller.phone,
          'otp': otp,
        }),
      )
          .timeout(const Duration(seconds: 30));

      debugPrint('Verify OTP status: ${response.statusCode}');
      debugPrint('Verify OTP response: ${response.body}');

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        if (!mounted) return;

        // Navigate only after successful verification.
        _controller.goToRegister();
      } else {
        _showError(
          'Verification Failed',
          _extractMessage(
            response.body,
            'Invalid OTP. Please try again.',
          ),
        );
      }
    } catch (e) {
      debugPrint('OTP verification error: $e');

      _showError(
        'Verification Error',
        'Unable to verify OTP. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
        });
      }
    }
  }


  String _extractMessage(String responseBody, String fallback) {
    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map<String, dynamic>) {
        final message =
            decoded['message'] ??
                decoded['msg'] ??
                decoded['error'];

        if (message != null && message.toString().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {
      // Use fallback if the response is not valid JSON.
    }

    return fallback;
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade50,
      colorText: Colors.black87,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom:
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height -
                  MediaQuery.of(context).padding.top -
                  32,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.06),

                  Center(
                    child: Image.asset(
                      'assets/images/phone.png',
                      height: size.height * 0.12,
                    ),
                  ),

                  SizedBox(height: size.height * 0.05),

                  const Text(
                    'Enter your phone number',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),


                  if (_otpSent) ...[
                    const SizedBox(height: 24),

                    const Text(
                      'Enter OTP',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Enter the 6-digit code sent to your mobile number.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 45,
                          height: 55,
                          child: TextField(
                            controller: _otpDigitControllers[index],
                            focusNode: _otpFocusNodes[index],
                            enabled: !_isVerifyingOtp,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(1),
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: Colors.green,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 5) {
                                _otpFocusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                _otpFocusNodes[index - 1].requestFocus();
                              }

                              setState(() {});
                            },
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _otpDigitControllers.every(
                              (controller) =>
                          controller.text.isNotEmpty,
                        ) &&
                            !_isVerifyingOtp
                            ? _verifyDriverOtp
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: _isVerifyingOtp
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          'VERIFY OTP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ],


                  const SizedBox(height: 15),

                  const Text(
                    'Payment info, ride details and important '
                        'updates will be sent to this number.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Container(
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),

                        Image.asset(
                          'assets/images/flag.png',
                          width: 35,
                        ),

                        const SizedBox(width: 12),

                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 13,
                            enabled: !_isLoading,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                              labelText: 'Phone number',
                              hintText: '+91 9876543210',
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              hintStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  const SizedBox(height: 30),


                  if (!_otpSent)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _continueWithPhone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          'CONTINUE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

