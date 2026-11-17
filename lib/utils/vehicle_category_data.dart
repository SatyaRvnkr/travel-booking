import '../models/vehicle.dart';

class VehicleCategoryData {
  static const List<VehicleCategory> categories = [
    VehicleCategory(
      id: 'a6672125-8ea7-47f5-a1f2-5320de8e72df',
      categoryName: 'Auto',
      vehicleType: 'AUTO',
      categoryType: 'ECONOMY',
    ),
    VehicleCategory(
      id: '6c4f0334-335f-440f-89f5-2f6b5e47eb4f',
      categoryName: 'Bike',
      vehicleType: 'BIKE',
      categoryType: 'ECONOMY',
    ),
    VehicleCategory(
      id: '789f458b-a543-48bc-bbae-a29ff5bb53df',
      categoryName: 'E-Rickshaw',
      vehicleType: 'E_RICKSHAW',
      categoryType: 'ECONOMY',
    ),
    VehicleCategory(
      id: 'c29f53c9-2f1a-4a18-af62-41d902399206',
      categoryName: 'Electric Cab',
      vehicleType: 'ELECTRIC_CAR',
      categoryType: 'ELECTRIC',
    ),
    VehicleCategory(
      id: '3c407e67-4d22-4602-9fcd-813492e02589',
      categoryName: 'Luxury',
      vehicleType: 'LUXURY_CAR',
      categoryType: 'PREMIUM',
    ),
    VehicleCategory(
      id: '5b17433c-e903-46ce-ae5f-d1ef55e88865',
      categoryName: 'Micro',
      vehicleType: 'CAR',
      categoryType: 'ECONOMY',
    ),
    VehicleCategory(
      id: '0e8522db-6141-4993-a77d-04859e1bd866',
      categoryName: 'Mini',
      vehicleType: 'CAR',
      categoryType: 'ECONOMY',
    ),
    VehicleCategory(
      id: 'd3363765-f9b7-453b-b55a-b76188891c8a',
      categoryName: 'Prime SUV',
      vehicleType: 'SUV',
      categoryType: 'PREMIUM',
    ),
    VehicleCategory(
      id: '67453771-dc21-4726-b978-c29166cc0bf8',
      categoryName: 'Prime Sedan',
      vehicleType: 'CAR',
      categoryType: 'PREMIUM',
    ),
    VehicleCategory(
      id: '504c2ce3-4cdb-49e7-9c1e-b7ed9eaa23a9',
      categoryName: 'SUV',
      vehicleType: 'SUV',
      categoryType: 'COMFORT',
    ),
    VehicleCategory(
      id: '270b787c-c06a-407f-afa3-f75f6aebfca8',
      categoryName: 'Sedan',
      vehicleType: 'CAR',
      categoryType: 'COMFORT',
    ),
    VehicleCategory(
      id: 'f8a503cb-9b01-4fbe-9e98-7eccea2f5f15',
      categoryName: 'XL Cab',
      vehicleType: 'SUV',
      categoryType: 'PREMIUM',
    ),
    VehicleCategory(
      id: 'ecfa9147-9e7c-4804-9f80-1024edb1a7cd',
      categoryName: 'Two Wheeler Parcel',
      vehicleType: 'TWO_WHEELER_PARCEL',
      categoryType: 'GOODS',
    ),
    VehicleCategory(
      id: '1d038848-c14d-442a-93d0-706ab7c5e0d7',
      categoryName: 'Electric Cargo Loader',
      vehicleType: 'ELECTRIC_CARGO',
      categoryType: 'GOODS',
    ),
    VehicleCategory(
      id: '1c52d46b-1c58-4b4a-b023-9ce90238e962',
      categoryName: 'Three Wheeler Cargo',
      vehicleType: 'THREE_WHEELER_CARGO',
      categoryType: 'GOODS',
    ),
    VehicleCategory(
      id: '2bac3505-643c-4cde-95dc-75f12bf92c4',
      categoryName: 'Mini Truck',
      vehicleType: 'MINI_TRUCK',
      categoryType: 'GOODS',
    ),
    VehicleCategory(
      id: '7c261c86-e211-42a4-9884-5346585c4166',
      categoryName: 'Pickup Truck',
      vehicleType: 'PICKUP',
      categoryType: 'GOODS',
    ),
    VehicleCategory(
      id: '1650dd08-0476-4bea-9a24-c1265920fb8b',
      categoryName: 'Delivery Van',
      vehicleType: 'DELIVERY_VAN',
      categoryType: 'GOODS',
    ),
    VehicleCategory(
      id: '7c5475e9-96c7-404f-b7ff-7b3dd73297f5',
      categoryName: 'Light Commercial Truck',
      vehicleType: 'LCV',
      categoryType: 'GOODS',
    ),
    VehicleCategory(
      id: '30d15222-afce-4d9a-91e7-9099b9eb9e4c',
      categoryName: 'Six Wheeler Truck',
      vehicleType: 'SIX_WHEELER',
      categoryType: 'GOODS',
    ),
    VehicleCategory(
      id: '211ab849-a318-413d-afb3-d17f910516fb',
      categoryName: 'Ten Wheeler Truck',
      vehicleType: 'TEN_WHEELER',
      categoryType: 'GOODS',
    ),
    VehicleCategory(
      id: '5c4fbec7-0042-42c7-9ef2-85d73927ae8b',
      categoryName: 'Multi Axle Truck',
      vehicleType: 'MULTI_AXLE',
      categoryType: 'GOODS',
    ),
  ];

  static List<VehicleCategory> getCategories(String vehicleName) {
    switch (vehicleName.toLowerCase()) {
      case 'auto-rickshaw':
        return categories
            .where((e) => e.categoryName == 'Auto')
            .toList();

      case 'two wheeler':
        return categories
            .where((e) => e.categoryName == 'Bike')
            .toList();

      case 'slow ev':
        return categories
            .where((e) =>
        e.categoryName == 'E-Rickshaw' ||
            e.categoryName == 'Electric Cab')
            .toList();

      case 'car':
        return categories
            .where((e) => [
          'Luxury',
          'Micro',
          'Mini',
          'Prime SUV',
          'Prime Sedan',
          'SUV',
          'Sedan',
          'XL Cab',
        ].contains(e.categoryName))
            .toList();

      case 'goods carrier':
        return categories
            .where((e) => [
          'Two Wheeler Parcel',
          'Electric Cargo Loader',
          'Three Wheeler Cargo',
          'Mini Truck',
          'Pickup Truck',
          'Delivery Van',
          'Light Commercial Truck',
          'Six Wheeler Truck',
          'Ten Wheeler Truck',
          'Multi Axle Truck',
        ].contains(e.categoryName))
            .toList();

      default:
        return [];
    }
  }
}