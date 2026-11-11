
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'controllers/onboarding_controller.dart';
import 'services/api_urls.dart';
import 'services/auth_session.dart';
import 'models/document_type.dart';
import 'widgets/document_upload_card.dart';
import 'widgets/onboarding_layout.dart';

class AadharVerificationScreen extends StatefulWidget {
  final bool showUpload;

  const AadharVerificationScreen({super.key, this.showUpload = false});

  @override
  State<AadharVerificationScreen> createState() =>
      _AadharVerificationScreenState();
}

class _AadharVerificationScreenState
    extends State<AadharVerificationScreen> {

  final TextEditingController _aadharController =
  TextEditingController();

  final OnboardingController _controller = Get.find();

  bool _isVerified = false;
  bool _isVerifying = false;
  bool _canContinue = false;

  String? _requestId;
  String? _transactionId;

  bool get _isValidAadhar {
    return RegExp(r'^[0-9]{12}$')
        .hasMatch(_aadharController.text.trim());
  }

  @override
  void initState() {
    super.initState();
    _isVerified = widget.showUpload || _controller.aadhaarReadyForUpload;
    _controller.onAadhaarDeepLink = _showPhotoUpload;
  }

  String _maskedAadhaar() {
    final number = _aadharController.text.trim().isNotEmpty
        ? _aadharController.text.trim()
        : _controller.aadharNumber.trim();
    if (number.length < 4) return 'Aadhaar verified';
    return 'XXXX XXXX ${number.substring(number.length - 4)}';
  }

  void _showPhotoUpload() {
    if (!mounted) return;
    setState(() {
      _isVerified = true;
      _isVerifying = false;
    });
  }

  // --------------------------------------------------
  // CREATE GRIDLINES VERIFICATION REQUEST
  // --------------------------------------------------

  Future<Map<String, dynamic>> _createGridlinesRequest(
      String aadhaarNumber) async {
    final headers = AuthSession.headers();
    debugPrint(
      'DigiLocker init Authorization: ${headers.containsKey('Authorization')}',
    );

    final response = await http
        .post(
          Uri.parse(ApiUrls.aadhaarDigilockerInit),
          headers: headers,
          body: jsonEncode({
            'aadhaarNumber': aadhaarNumber,
            'consent': 'Y',
            'pinless': 'false',
          }),
        )
        .timeout(const Duration(seconds: 30));

    debugPrint('DigiLocker init status: ${response.statusCode}');
    debugPrint('DigiLocker init response: ${response.body}');

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('The server returned an invalid response.');
    }

    final root = Map<String, dynamic>.from(decoded);
    final message = root['message']?.toString();

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        root['success'] == false) {
      throw Exception(
        message != null && message.isNotEmpty
            ? message
            : 'Unable to start Aadhaar verification.',
      );
    }

    final data = root['data'];
    if (data is! Map) {
      throw Exception('Authorization URL was not returned.');
    }

    return Map<String, dynamic>.from(data);
  }

  /// Opens the authorize URL only through `purpose=Know`.
  /// Drops `Your Customer`, `service_name`, and `req_doctype`.
  Uri _digiLockerUri(String raw) {
    var value = raw.trim();
    if (value.startsWith('"') && value.endsWith('"') && value.length > 1) {
      value = value.substring(1, value.length - 1);
    }
    value = value.replaceAll(r'\u0026', '&').replaceAll('&amp;', '&');

    const marker = 'purpose=Know';
    final index = value.indexOf(marker);
    if (index != -1) {
      value = value.substring(0, index + marker.length);
    }

    return Uri.parse(value.replaceAll(' ', '%20'));
  }

  void _logLong(String label, String value) {
    const chunk = 800;
    debugPrint('$label length=${value.length}');
    for (var i = 0; i < value.length; i += chunk) {
      final end = i + chunk > value.length ? value.length : i + chunk;
      debugPrint('$label ${value.substring(i, end)}');
    }
  }

  Future<bool> _openDigiLocker(Uri uri) async {
    const modes = [
      LaunchMode.inAppBrowserView,
      LaunchMode.externalApplication,
    ];
    for (final mode in modes) {
      try {
        final opened = await launchUrl(
          uri,
          mode: mode,
          webViewConfiguration: const WebViewConfiguration(enableJavaScript: true),
        );
        if (opened) return true;
      } catch (e) {
        debugPrint('DigiLocker launch ($mode) failed: $e');
      }
    }
    return false;
  }

  // --------------------------------------------------
  // VERIFY AADHAAR
  // --------------------------------------------------

  Future<void> _verifyAadhar() async {

    if (!_isValidAadhar) {
      Get.snackbar(
        'Invalid Aadhaar',
        'Please enter a valid 12-digit Aadhaar number.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isVerifying = true;
    });

    try {
      final String aadhaarNumber =
      _aadharController.text.trim();

      _controller.aadharNumber = aadhaarNumber;

      // Create verification request through backend.
      final response =
      await _createGridlinesRequest(aadhaarNumber);

      final String? authorizationUrl =
      response['authorizationUrl']?.toString();

      final String? requestId =
      response['requestId']?.toString();

      if (authorizationUrl == null ||
          authorizationUrl.isEmpty ||
          requestId == null ||
          requestId.isEmpty) {
        throw Exception(
          'Invalid Gridlines authorization response.',
        );
      }

      _requestId = requestId;
      _transactionId = response['transactionId']?.toString();

      final Uri authUri = _digiLockerUri(authorizationUrl);

      if (authUri.scheme != 'https' ||
          !authUri.host.contains('digitallocker.gov.in') ||
          !authUri.path.contains('/oauth2/1/authorize')) {
        throw Exception('Invalid DigiLocker authorization URL.');
      }

      _logLong(
        'Opening DigiLocker requestId=$_requestId transactionId=$_transactionId',
        authUri.toString(),
      );

      final bool opened = await _openDigiLocker(authUri);
      if (!opened) {
        throw Exception('Unable to open DigiLocker authorization page.');
      }
    } catch (e) {
      debugPrint('Aadhaar verification error: $e');

      if (mounted) {
        final raw = e.toString().replaceFirst('Exception: ', '');
        Get.snackbar(
          'Verification Error',
          raw.isEmpty ? 'Unable to start Aadhaar verification.' : raw,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // CONTINUE TO PAN SCREEN
  // --------------------------------------------------

  void _onContinue() {
    if (!_isVerified || !_canContinue) return;

    _controller.goToPan();
  }

  // --------------------------------------------------
  // DISPOSE
  // --------------------------------------------------

  @override
  void dispose() {
    if (_controller.onAadhaarDeepLink == _showPhotoUpload) {
      _controller.onAadhaarDeepLink = null;
    }
    _aadharController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {

    return OnboardingLayout(
      title: 'Aadhaar Verification',

      subtitle: _isVerified
          ? 'Upload front and back images of your Aadhaar card'
          : 'Enter your Aadhaar number to verify your identity',

      bottomButton: primaryButton(
        label: 'Upload & Continue',
        onPressed: _isVerified && _canContinue
            ? _onContinue
            : null,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // --------------------------------
          // STEP 1: ENTER AADHAAR NUMBER
          // --------------------------------

          if (!_isVerified) ...[

            const SizedBox(height: 10),

            const Text(
              'Aadhaar Number',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _aadharController,
              keyboardType: TextInputType.number,
              maxLength: 12,

              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],

              decoration: InputDecoration(
                hintText: 'Enter 12-digit Aadhaar number',
                counterText: '',
                prefixIcon: const Icon(Icons.credit_card),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade400,
                  ),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF033564),
                    width: 1.5,
                  ),
                ),
              ),

              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(height: 8),

            const Text(
              'Enter your Aadhaar number to proceed with verification.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed: _isValidAadhar && !_isVerifying
                    ? _verifyAadhar
                    : null,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF033564),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: _isVerifying
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Verify Aadhaar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          // --------------------------------
          // STEP 2: VERIFICATION SUCCESS
          // --------------------------------

          if (_isVerified) ...[

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),

                border: Border.all(
                  color: Colors.green.withOpacity(0.4),
                ),
              ),

              child: Row(
                children: [

                  const Icon(
                    Icons.verified,
                    color: Colors.green,
                    size: 28,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        const Text(
                          'Aadhaar Verified',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          _maskedAadhaar(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Upload Aadhaar Card',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Please upload clear images of both sides of your Aadhaar card.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------
            // STEP 3: UPLOAD FRONT AND BACK
            // --------------------------------

            DocumentUploadCard(
              documentKind: DocumentKind.aadhar,

              onUploadStatusChanged: (complete) {
                setState(() {
                  _canContinue = complete;
                });
              },
            ),

            const SizedBox(height: 16),

            if (_canContinue)
              const Row(
                children: [

                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),

                  SizedBox(width: 8),

                  Text(
                    'Aadhaar images uploaded successfully',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
