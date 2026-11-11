class Vehicle {
  final String name;
  final String image;

  Vehicle({required this.name, required this.image});
}

final List<Vehicle> vehicles = [
  Vehicle(name: 'Auto-rickshaw', image: 'assets/images/rickshaw.png'),
  Vehicle(name: 'Two Wheeler', image: 'assets/images/motorcycle.png'),
  Vehicle(name: 'Car', image: 'assets/images/car.png'),
  Vehicle(name: 'Slow EV', image: 'assets/images/electric-scooter.png'),
  Vehicle(name: 'Goods Carrier', image: 'assets/images/transport.png'),
  Vehicle(name: 'Tanga', image: 'assets/images/tanga.png'),
];
