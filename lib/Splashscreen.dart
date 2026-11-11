import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/onboarding_controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            children: [

              const Spacer(),

              // Logo
              Image.asset(
                "assets/images/timelycablogo.png",
                width: 180,
              ),

              const Spacer(),

              // Building Image
              Image.asset(
                "assets/images/timebiuldlogo.png",
                width: Get.width,
                height: 220,
                fit: BoxFit.contain,
              ),

              // Login/Register Button

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Get.find<OnboardingController>().goToLogin();
                  },
                  child: const Text(
                    "LOGIN/REGISTER",

                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),

                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

}