
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

import 'controllers/onboarding_controller.dart';
import 'models/document_type.dart';
import 'widgets/document_upload_card.dart';
import 'widgets/onboarding_layout.dart';

class AadharVerificationScreen extends StatefulWidget {
  const AadharVerificationScreen({super.key});

  @override
  State<AadharVerificationScreen> createState() =>
      _AadharVerificationScreenState();
}

class _AadharVerificationScreenState
    extends State<AadharVerificationScreen> {

  final TextEditingController _aadharController =
  TextEditingController();

  final OnboardingController _controller = Get.find();

  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _linkSubscription;

  bool _isVerified = false;
  bool _isVerifying = false;
  bool _canContinue = false;

  String? _requestId;

  // Replace with your actual backend API integration.
  static const String backendBaseUrl =
      'https://YOUR-BACKEND-DOMAIN.com';

  bool get _isValidAadhar {
    return RegExp(r'^[0-9]{12}$')
        .hasMatch(_aadharController.text.trim());
  }

  @override
  void initState() {
    super.initState();
    _initializeDeepLinks();
  }

  // --------------------------------------------------
  // DEEP LINK INITIALIZATION
  // --------------------------------------------------

  Future<void> _initializeDeepLinks() async {
    // Handle app opened through deep link when terminated.
    try {
      final initialUri = await _appLinks.getInitialLink();

      if (initialUri != null) {
        await _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Initial deep link error: $e');
    }

    // Handle app returning from DigiLocker.
    _linkSubscription =
        _appLinks.uriLinkStream.listen(
              (Uri uri) {
            _handleDeepLink(uri);
          },
          onError: (error) {
            debugPrint('Deep link stream error: $error');
          },
        );
  }

  // --------------------------------------------------
  // HANDLE GRIDLINES CALLBACK
  // --------------------------------------------------

  Future<void> _handleDeepLink(Uri uri) async {

    debugPrint('Received deep link: $uri');

    if (uri.scheme != 'yourapp' ||
        uri.host != 'aadhar-callback') {
      return;
    }

    final String? requestId =
    uri.queryParameters['requestId'];

    if (requestId == null || requestId.isEmpty) {
      Get.snackbar(
        'Verification Error',
        'Verification request ID is missing.',
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _isVerifying = true;
      _requestId = requestId;
    });

    try {
      // Check actual verification status from your backend.
      final bool verified =
      await _checkGridlinesVerificationStatus(requestId);

      if (!mounted) return;

      if (verified) {
        setState(() {
          _isVerified = true;
          _isVerifying = false;
        });

        Get.snackbar(
          'Success',
          'Aadhaar verified successfully.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        setState(() {
          _isVerifying = false;
        });

        Get.snackbar(
          'Verification Pending',
          'Aadhaar verification is not yet complete.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      Get.snackbar(
        'Error',
        'Unable to check verification status.',
      );

      debugPrint('Verification status error: $e');
    }
  }

  // --------------------------------------------------
  // CREATE GRIDLINES VERIFICATION REQUEST
  // --------------------------------------------------

  Future<Map<String, dynamic>> _createGridlinesRequest(
      String aadhaarNumber) async {

    /*
      TODO: Connect your actual backend API here.

      Backend should:
      1. Create Gridlines DigiLocker verification request.
      2. Send the configured HTTPS callback URL to Gridlines.
      3. Return authorizationUrl and requestId.

      Expected response shape for this screen:

      {
        "requestId": "GRIDLINES_REQUEST_ID",
        "authorizationUrl": "https://..."
      }

      Do not send Gridlines secret keys from Flutter.
    */

    throw UnimplementedError(
      'Connect your Create Verification Request API here.',
    );
  }

  // --------------------------------------------------
  // CHECK GRIDLINES VERIFICATION STATUS
  // --------------------------------------------------

  Future<bool> _checkGridlinesVerificationStatus(
      String requestId) async {

    /*
      TODO: Connect your actual backend status API here.

      Backend should:
      1. Fetch the Gridlines verification status.
      2. Validate the final result.
      3. Return true only when verification is successful.

      Do not consider the deep link itself as proof of success.
    */

    throw UnimplementedError(
      'Connect your Verification Status API here.',
    );
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

      final Uri authUri = Uri.parse(authorizationUrl);

      if (!authUri.hasScheme ||
          authUri.scheme != 'https') {
        throw Exception('Invalid authorization URL.');
      }

      // Open Gridlines DigiLocker authorization page.
      final bool opened = await launchUrl(
        authUri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw Exception(
          'Unable to open DigiLocker authorization page.',
        );
      }

    } catch (e) {
      debugPrint('Aadhaar verification error: $e');

      if (mounted) {
        Get.snackbar(
          'Verification Error',
          'Unable to start Aadhaar verification.',
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
    _linkSubscription?.cancel();
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
                          'XXXX XXXX ${_aadharController.text.substring(8)}',
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
