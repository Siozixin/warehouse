import 'dart:async';
import 'dart:math';

import '../models/alert.dart';
import '../models/sensor_reading.dart';
import '../models/warehouse_zone.dart';

class SensorSimulatorService {
  static final SensorSimulatorService _instance =
      SensorSimulatorService._internal();
  factory SensorSimulatorService() => _instance;
  SensorSimulatorService._internal();

  final _random = Random();
  final _zonesController = StreamController<List<WarehouseZone>>.broadcast();
  final _alertsController = StreamController<List<Alert>>.broadcast();

  Stream<List<WarehouseZone>> get zonesStream => _zonesController.stream;
  Stream<List<Alert>> get alertsStream => _alertsController.stream;

  List<WarehouseZone> zones = [
    WarehouseZone(
      id: 'zone_a',
      name: 'Zone A',
      location: 'Vegetable Storage',
      temperature: 4.2,
      humidity: 72.0,
    ),
    WarehouseZone(
      id: 'zone_b',
      name: 'Zone B',
      location: 'Cold Storage',
      temperature: 2.8,
      humidity: 65.0,
    ),
    WarehouseZone(
      id: 'zone_c',
      name: 'Zone C',
      location: 'Loading Bay',
      temperature: 8.5,
      humidity: 58.0,
    ),
    WarehouseZone(
      id: 'zone_d',
      name: 'Zone D',
      location: 'Packaging Area',
      temperature: 6.1,
      humidity: 68.0,
    ),
  ];

  List<Alert> alerts = [
    Alert(
      id: 'init_1',
      title: 'System Online',
      message: 'All sensors connected via 5G gateway. TLS encryption active.',
      type: AlertType.system,
      severity: AlertSeverity.info,
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  double maxTemperature = 8.0;
  double maxHumidity = 80.0;
  bool autoCoolingEnabled = true;
  bool autoDehumidifyEnabled = true;
  bool isConnected = true;
  double _networkSpeed = 250.0;
  double _signalStrength = 4.0; // 0 (poor) - 4 (excellent)
  double _packetLoss = 0.5; // percent
  Timer? _timer;
  int _tick = 0;

  String get networkSpeedLabel =>
      isConnected ? '${_networkSpeed.toStringAsFixed(0)} Mbps' : 'Disconnected';

  int get devicesConnected => zones.length;

  String get signalLabel {
    if (!isConnected) return 'No signal';
    if (_signalStrength >= 3.5) return 'Excellent';
    if (_signalStrength >= 2.5) return 'Good';
    if (_signalStrength >= 1.5) return 'Fair';
    return 'Poor';
  }

  String get packetLossLabel => '${_packetLoss.toStringAsFixed(1)}%';

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _simulate());
    _zonesController.add(zones);
    _alertsController.add(alerts);
  }

  void stop() {
    _timer?.cancel();
  }

  void _simulate() {
    _tick++;

    for (final zone in zones) {
      final drift = (_random.nextDouble() - 0.45) * 0.8;
      zone.temperature = (zone.temperature + drift).clamp(1.0, 15.0);
      zone.humidity = (zone.humidity + (_random.nextDouble() - 0.5) * 2).clamp(
        40.0,
        95.0,
      );

      zone.history.add(
        SensorReading(
          timestamp: DateTime.now(),
          temperature: zone.temperature,
          humidity: zone.humidity,
        ),
      );
      if (zone.history.length > 30) {
        zone.history.removeAt(0);
      }

      final tempHigh = zone.temperature > maxTemperature;
      final humidityHigh = zone.humidity > maxHumidity;

      if (autoCoolingEnabled && tempHigh) {
        if (!zone.coolingActive) {
          zone.coolingActive = true;
          _addAlert(
            title: 'Auto-Cooling Activated',
            message:
                '${zone.name}: Temperature ${zone.temperature.toStringAsFixed(1)}°C exceeds ${maxTemperature.toStringAsFixed(1)}°C. Cooling engaged.',
            type: AlertType.temperature,
            severity: AlertSeverity.warning,
            zoneId: zone.id,
          );
        }
        zone.temperature = (zone.temperature - 0.5).clamp(1.0, 15.0);
      } else if (zone.coolingActive && !tempHigh) {
        zone.coolingActive = false;
        _addAlert(
          title: 'Cooling Deactivated',
          message: '${zone.name}: Temperature normalized. Cooling off.',
          type: AlertType.system,
          severity: AlertSeverity.info,
          zoneId: zone.id,
        );
      }

      if (autoDehumidifyEnabled && humidityHigh) {
        if (!zone.dehumidifierActive) {
          zone.dehumidifierActive = true;
          _addAlert(
            title: 'Auto-Dehumidifier Activated',
            message:
                '${zone.name}: Humidity ${zone.humidity.toStringAsFixed(0)}% exceeds ${maxHumidity.toStringAsFixed(0)}%. Ventilation/dehumidifier engaged.',
            type: AlertType.humidity,
            severity: AlertSeverity.warning,
            zoneId: zone.id,
          );
        }
        zone.humidity = (zone.humidity - 0.7).clamp(40.0, 95.0);
      } else if (zone.dehumidifierActive && !humidityHigh) {
        zone.dehumidifierActive = false;
        _addAlert(
          title: 'Dehumidifier Deactivated',
          message: '${zone.name}: Humidity normalized. Ventilation off.',
          type: AlertType.system,
          severity: AlertSeverity.info,
          zoneId: zone.id,
        );
      }
    }

    if (_tick % 5 == 0) {
      _networkSpeed = (_networkSpeed + (_random.nextDouble() - 0.5) * 40).clamp(
        60.0,
        500.0,
      );
      _signalStrength = (_signalStrength + (_random.nextDouble() - 0.5) * 1.0)
          .clamp(0.0, 4.0);
      _packetLoss = (_packetLoss + (_random.nextDouble() - 0.5) * 4.0).clamp(
        0.0,
        50.0,
      );
    }

    if (_tick % 5 == 0 && _random.nextDouble() > 0.6) {
      final zone = zones[_random.nextInt(zones.length)];
      if (zone.temperature > maxTemperature - 1) {
        _addAlert(
          title: 'Temperature Warning',
          message:
              '${zone.name} approaching limit: ${zone.temperature.toStringAsFixed(1)}°C (max ${maxTemperature.toStringAsFixed(1)}°C)',
          type: AlertType.temperature,
          severity: AlertSeverity.warning,
          zoneId: zone.id,
        );
      }
      if (zone.humidity > maxHumidity - 5) {
        _addAlert(
          title: 'Humidity Warning',
          message:
              '${zone.name} approaching limit: ${zone.humidity.toStringAsFixed(0)}% (max ${maxHumidity.toStringAsFixed(0)}%)',
          type: AlertType.humidity,
          severity: AlertSeverity.warning,
          zoneId: zone.id,
        );
      }
    }

    _zonesController.add(zones);
    _alertsController.add(alerts);
  }

  void _addAlert({
    required String title,
    required String message,
    required AlertType type,
    required AlertSeverity severity,
    String? zoneId,
  }) {
    final duplicate = alerts.any(
      (a) =>
          a.title == title &&
          a.zoneId == zoneId &&
          DateTime.now().difference(a.timestamp).inSeconds < 15,
    );
    if (duplicate) return;

    alerts.insert(
      0,
      Alert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: type,
        severity: severity,
        timestamp: DateTime.now(),
        zoneId: zoneId,
      ),
    );
    if (alerts.length > 50) alerts.removeLast();
  }

  void toggleCooling(String zoneId) {
    final zone = zones.firstWhere((z) => z.id == zoneId);
    zone.coolingActive = !zone.coolingActive;
    _addAlert(
      title: zone.coolingActive ? 'Manual Cooling ON' : 'Manual Cooling OFF',
      message:
          '${zone.name} cooling ${zone.coolingActive ? "activated" : "deactivated"} by manager.',
      type: AlertType.system,
      severity: AlertSeverity.info,
      zoneId: zoneId,
    );
    _zonesController.add(zones);
    _alertsController.add(alerts);
  }

  void toggleDehumidifier(String zoneId) {
    final zone = zones.firstWhere((z) => z.id == zoneId);
    zone.dehumidifierActive = !zone.dehumidifierActive;
    _addAlert(
      title:
          zone.dehumidifierActive
              ? 'Manual Dehumidifier ON'
              : 'Manual Dehumidifier OFF',
      message:
          '${zone.name} ventilation/dehumidifier ${zone.dehumidifierActive ? "activated" : "deactivated"} by manager.',
      type: AlertType.system,
      severity: AlertSeverity.info,
      zoneId: zoneId,
    );
    _zonesController.add(zones);
    _alertsController.add(alerts);
  }

  void setAutoCooling(bool enabled) {
    autoCoolingEnabled = enabled;
    _addAlert(
      title: 'Auto-Cooling ${enabled ? "Enabled" : "Disabled"}',
      message:
          enabled
              ? 'System will automatically engage cooling when thresholds are exceeded.'
              : 'Manual control required for cooling systems.',
      type: AlertType.system,
      severity: AlertSeverity.info,
    );
    _zonesController.add(zones);
    _alertsController.add(alerts);
  }

  void setAutoDehumidify(bool enabled) {
    autoDehumidifyEnabled = enabled;
    _addAlert(
      title: 'Auto-Dehumidify ${enabled ? "Enabled" : "Disabled"}',
      message:
          enabled
              ? 'System will engage ventilation/dehumidifier when humidity exceeds threshold.'
              : 'Manual control required for humidity actuators.',
      type: AlertType.system,
      severity: AlertSeverity.info,
    );
    _zonesController.add(zones);
    _alertsController.add(alerts);
  }

  void setThresholds(double temp, double humidity) {
    maxTemperature = temp;
    maxHumidity = humidity;
    _addAlert(
      title: 'Thresholds Updated',
      message:
          'Max temperature: ${temp.toStringAsFixed(1)}°C, Max humidity: ${humidity.toStringAsFixed(0)}%',
      type: AlertType.system,
      severity: AlertSeverity.info,
    );
    _zonesController.add(zones);
    _alertsController.add(alerts);
  }

  void markAlertRead(String alertId) {
    final alert = alerts.firstWhere((a) => a.id == alertId);
    alert.isRead = true;
    _alertsController.add(alerts);
  }

  void markAllAlertsRead() {
    for (final alert in alerts) {
      alert.isRead = true;
    }
    _alertsController.add(alerts);
  }

  int get unreadCount => alerts.where((a) => !a.isRead).length;

  double get averageTemperature =>
      zones.map((z) => z.temperature).reduce((a, b) => a + b) / zones.length;

  double get averageHumidity =>
      zones.map((z) => z.humidity).reduce((a, b) => a + b) / zones.length;

  int get activeCoolingCount => zones.where((z) => z.coolingActive).length;

  int get activeDehumidifierCount =>
      zones.where((z) => z.dehumidifierActive).length;

  int get criticalZoneCount =>
      zones
          .where(
            (z) =>
                z.getStatus(maxTemperature, maxHumidity) == ZoneStatus.critical,
          )
          .length;
}
