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
