import 'sensor_reading.dart';

enum ZoneStatus { normal, warning, critical }

class WarehouseZone {
  final String id;
  final String name;
  final String location;
  double temperature;
  double humidity;
  bool coolingActive;
  final List<SensorReading> history;

  WarehouseZone({
    required this.id,
    required this.name,
    required this.location,
    required this.temperature,
    required this.humidity,
    this.coolingActive = false,
    List<SensorReading>? history,
  }) : history = history ?? [];

  ZoneStatus getStatus(double maxTemp, double maxHumidity) {
    if (temperature > maxTemp || humidity > maxHumidity) {
      return ZoneStatus.critical;
    }
    if (temperature > maxTemp - 2 || humidity > maxHumidity - 5) {
      return ZoneStatus.warning;
    }
    return ZoneStatus.normal;
  }
}
