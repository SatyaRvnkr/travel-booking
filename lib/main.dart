import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'Splashscreen.dart';
import 'controllers/onboarding_controller.dart';
import 'controllers/onboarding_document_store.dart';
import 'services/document_upload_service.dart';
import 'services/driver_api_client.dart';
import 'utils/upload_flow_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  final apiClient = DriverApiClient();
  Get.put(apiClient);
  Get.put(OnboardingController());
  Get.put(OnboardingDocumentStore());
  Get.put(DocumentUploadService(apiClient));

  UploadFlowLogger.step(
    0,
    'App started — presigned URL from API, then S3 PUT',
  );

  WakelockPlus.enable();
  WakelockPlus.disable();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _listenForAadhaarRedirect();
  }

  Future<void> _listenForAadhaarRedirect() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _openAadhaarIfRedirect(initialUri);
      }
    } catch (e) {
      debugPrint('Initial app link error: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _openAadhaarIfRedirect,
      onError: (Object error) {
        debugPrint('App link stream error: $error');
      },
    );
  }

  void _openAadhaarIfRedirect(Uri uri) {
    final isAadhaarRedirect = uri.scheme == 'timelycab' && uri.host == 'aadhaar';
    if (!isAadhaarRedirect) return;
    debugPrint('DigiLocker redirected to app: $uri');
    Get.find<OnboardingController>().openAadhaarUpload();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Yesgo Cab Driver',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      theme: ThemeData(useMaterial3: true),
    );
  }
}
