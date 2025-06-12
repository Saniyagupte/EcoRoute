class CarModelSpecs {
  static const Map<String, double> consumptionRates = {
    'Tesla Model 3': 0.2,
    'Nissan Leaf': 0.25,
    'Chevy Bolt': 0.22,
    'BMW i3': 0.3,
  };

  static const Map<String, double> batteryCapacities = {
    'Tesla Model 3': 60.0,
    'Nissan Leaf': 40.0,
    'Chevy Bolt': 66.0,
    'BMW i3': 42.2,
  };

  static double getConsumptionRate(String model) {
    return consumptionRates[model] ?? 0.25; // Default fallback
  }

  static double getBatteryCapacity(String model) {
    return batteryCapacities[model] ?? 50.0; // Default fallback
  }
}
