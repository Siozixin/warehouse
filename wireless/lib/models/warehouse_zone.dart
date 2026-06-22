import 'sensor_reading.dart';

enum ZoneStatus { normal, warning, critical }

enum ZoneType { tropicalFruit, packagingLoading }

enum ThresholdMode { auto, manual }

class WarehouseZone {
  final String id;
  final String name;
  final String location;
  final ZoneType type;
  double temperature;
  double humidity;
  bool coolingActive;
  bool dehumidifierActive;
  ThresholdMode thresholdMode;
  double tempLower;
  double tempUpper;
  double humidityLower;
  double humidityUpper;
  final List<SensorReading> history;

  WarehouseZone({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.temperature,
    required this.humidity,
    this.coolingActive = false,
    this.dehumidifierActive = false,
    this.thresholdMode = ThresholdMode.auto,
    double? tempLower,
    double? tempUpper,
    double? humidityLower,
    double? humidityUpper,
    List<SensorReading>? history,
  }) : tempLower = tempLower ?? recommendedTempLower(type),
       tempUpper = tempUpper ?? recommendedTempUpper(type),
       humidityLower = humidityLower ?? recommendedHumidityLower(type),
       humidityUpper = humidityUpper ?? recommendedHumidityUpper(type),
       history = history ?? [];

  static double recommendedTempLower(ZoneType type) {
    switch (type) {
      case ZoneType.tropicalFruit:
        return 7.0;
      case ZoneType.packagingLoading:
        return 12.0;
    }
  }

  static double recommendedTempUpper(ZoneType type) {
    switch (type) {
      case ZoneType.tropicalFruit:
        return 13.0;
      case ZoneType.packagingLoading:
        return 15.0;
    }
  }

  static double recommendedHumidityLower(ZoneType type) {
    switch (type) {
      case ZoneType.tropicalFruit:
        return 85.0;
      case ZoneType.packagingLoading:
        return 60.0;
    }
  }

  static double recommendedHumidityUpper(ZoneType type) {
    switch (type) {
      case ZoneType.tropicalFruit:
        return 95.0;
      case ZoneType.packagingLoading:
        return 75.0;
    }
  }

  bool get isAuto => thresholdMode == ThresholdMode.auto;

  void applyAutoThresholds() {
    thresholdMode = ThresholdMode.auto;
    tempLower = recommendedTempLower(type);
    tempUpper = recommendedTempUpper(type);
    humidityLower = recommendedHumidityLower(type);
    humidityUpper = recommendedHumidityUpper(type);
  }

  ZoneStatus getStatus() {
    final tempCritical = temperature < tempLower || temperature > tempUpper;
    final humidityCritical =
        humidity < humidityLower || humidity > humidityUpper;
    if (tempCritical || humidityCritical) {
      return ZoneStatus.critical;
    }

    final tempWarning =
        temperature < tempLower + 1 || temperature > tempUpper - 1;
    final humidityWarning =
        humidity < humidityLower + 3 || humidity > humidityUpper - 3;
    if (tempWarning || humidityWarning) {
      return ZoneStatus.warning;
    }
    return ZoneStatus.normal;
  }
}
