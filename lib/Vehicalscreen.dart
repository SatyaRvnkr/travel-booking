
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/onboarding_controller.dart';
import 'models/vehicle.dart';
import 'utils/vehicle_category_data.dart';

class Vehicalscreen extends StatelessWidget {
  const Vehicalscreen({super.key});

  void _handleVehicleTap(
      BuildContext context,
      OnboardingController controller,
      Vehicle vehicle,
      ) {
    final categories =
    VehicleCategoryData.getCategories(vehicle.name);

    if (categories.isEmpty) {
      Get.snackbar(
        'Category unavailable',
        'No database category is configured for ${vehicle.name}.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Auto and Bike: Direct selection.
    if (categories.length == 1) {
      controller.selectVehicleCategory(categories.first);
      controller.goToVehicleRegistration(vehicle);
      return;
    }

    // EV and Car: Ask the user to select a category.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(22),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Vehicle Category',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose your ${vehicle.name} category',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),

                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: const Color(0xffF5F5F5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            title: Text(
                              category.categoryName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${category.categoryType} • ${category.vehicleType}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              controller.selectVehicleCategory(category);
                              Navigator.pop(sheetContext);
                              controller.goToVehicleRegistration(vehicle);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(
              color: Color(0xffF8BE22),
              child: SizedBox(height: 220),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                ),
                onPressed: () => Get.back(),
              ),
            ),
            Positioned(
              top: 190,
              left: 0,
              right: 0,
              bottom: 0,
              child: Material(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(23),
                  topRight: Radius.circular(23),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Please select your vehicle',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Which vehicle will you be driving?',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              GridView.builder(
                                shrinkWrap: true,
                                physics:
                                const NeverScrollableScrollPhysics(),
                                itemCount: vehicles.length,
                                gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1.25,
                                ),
                                itemBuilder: (context, index) {
                                  final vehicle = vehicles[index];

                                  return InkWell(
                                    borderRadius:
                                    BorderRadius.circular(10),
                                    onTap: () {
                                      _handleVehicleTap(
                                        context,
                                        controller,
                                        vehicle,
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xffF5F5F5),
                                        borderRadius:
                                        BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            vehicle.image,
                                            height: 50,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            vehicle.name,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight:
                                              FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: const Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'You can add more vehicles after completing the onboarding process',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
}
