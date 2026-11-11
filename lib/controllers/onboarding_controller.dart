import 'package:get/get.dart';

import '../AadharVerificationScreen.dart';
import '../ApplicationSubmittedScreen.dart';
import '../BankVerificationScreen.dart';
import '../DocumentsReviewScreen.dart';
import '../DriverLicenseScreen.dart';
import '../LoginPage.dart';
import '../PanVerificationScreen.dart';
import '../PersonalDetailsScreen.dart';
import '../ProfilePhotoScreen.dart';
import '../Resisterpage.dart';
import '../VehicalResistration.dart';
import '../Vehicalscreen.dart';
import '../VehicleRcFailedScreen.dart';
import '../models/vehicle.dart';

class OnboardingController extends GetxController {
  String phone = '';
  String name = '';
  String city = '';
  String referralCode = '';
  String vehicleName = '';
  String vehicleImage = '';
  String registrationNumber = '';
  String category = '';
  String licenseNumber = '';
  String aadharNumber = '';
  String panNumber = '';
  String bankName = '';
  String accountNumber = '';
  String ifscCode = '';
  String accountHolder = '';
  bool rcRejected = false;
  bool aadhaarReadyForUpload = false;
  void Function()? onAadhaarDeepLink;

  /// DigiLocker returned to the app. Show Aadhaar photo upload.
  void openAadhaarUpload() {
    final alreadyWaiting = aadhaarReadyForUpload;
    aadhaarReadyForUpload = true;
    final handler = onAadhaarDeepLink;
    if (handler != null) {
      handler();
      return;
    }
    if (alreadyWaiting) return;
    Get.to(() => const AadharVerificationScreen(showUpload: true));
  }

  void goToLogin() => Get.to(() => const LoginRegisterScreen());

  void goToRegister() => Get.to(() => const Resisterpage());

  void goToVehicleSelection() => Get.to(() => const Vehicalscreen());

  void goToVehicleRegistration(Vehicle vehicle) {
    vehicleName = vehicle.name;
    vehicleImage = vehicle.image;
    Get.to(() => const VehicalResistration());
  }

  void goToVehicleRc() => goToAadhar();

  void goToDriverLicense() => Get.to(() => const DriverLicenseScreen());

  void goToProfilePhoto() => Get.to(() => const ProfilePhotoScreen());

  void goToAadhar() => Get.to(
        () => AadharVerificationScreen(showUpload: aadhaarReadyForUpload),
      );

  void goToPan() => Get.to(() => const PanVerificationScreen());

  void goToPersonalDetails({bool rejected = false}) {
    rcRejected = rejected;
    Get.to(() => const PersonalDetailsScreen());
  }

  void goToDocumentsReview() => Get.to(() => const DocumentsReviewScreen());

  void goToRcFailed() => Get.to(() => const VehicleRcFailedScreen());

  void goToBank() => Get.to(() => const BankVerificationScreen());

  void goToSubmitted() => Get.offAll(() => const ApplicationSubmittedScreen());
}
