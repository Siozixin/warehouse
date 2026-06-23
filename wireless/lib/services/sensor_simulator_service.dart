import 'dart:async';
import 'dart:math';

import '../models/alert.dart';
import '../models/cctv_analysis.dart';
import '../models/fruit_batch.dart';
import '../models/rfid_log.dart';
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

  final List<CctvAnalysis> cctvAnalyses = [];
  final List<FruitBatch> batches = [];
  final List<RfidLog> rfidLogs = [];

  Stream<List<WarehouseZone>> get zonesStream => _zonesController.stream;
  Stream<List<Alert>> get alertsStream => _alertsController.stream;

  List<WarehouseZone> zones = [
    WarehouseZone(
      id: 'zone_a',
      name: 'Zone A',
      location: 'Tropical Fruit Storage',
      type: ZoneType.tropicalFruit,
      temperature: 9.2,
      humidity: 88.0,
    ),
    WarehouseZone(
      id: 'zone_b',
      name: 'Zone B',
      location: 'Tropical Fruit Storage',
      type: ZoneType.tropicalFruit,
      temperature: 11.3,
      humidity: 91.0,
    ),
    WarehouseZone(
      id: 'zone_c',
      name: 'Zone C',
      location: 'Loading Bay',
      type: ZoneType.packagingLoading,
      temperature: 13.2,
      humidity: 63.0,
    ),
    WarehouseZone(
      id: 'zone_d',
      name: 'Zone D',
      location: 'Packaging Area',
      type: ZoneType.packagingLoading,
      temperature: 13.8,
      humidity: 67.0,
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
    _initializeCctvAndBatchData();
    _initializeRfidLogs();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _simulate());
    _zonesController.add(zones);
    _alertsController.add(alerts);
  }

  void stop() {
    _timer?.cancel();
  }

  void _initializeCctvAndBatchData() {
    cctvAnalyses.clear();
    final initialAnalysis = CctvAnalysis(
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      goodPercentage: 72.0,
      partialPercentage: 18.0,
      spoiledPercentage: 10.0,
      healthScore: 84.0,
      spoilageProbability: 12.0,
      healthStatus: 'Good',
      imageAsset: 'assets/images/papaya.png',
      batchId: 'BATCH-001',
    );
    cctvAnalyses.add(initialAnalysis);

    batches.clear();
    batches.addAll([
      FruitBatch(
        batchId: 'BATCH-001',
        arrivalTime: DateTime.now().subtract(
          const Duration(hours: 4, minutes: 20),
        ),
        firstInspectionTime: initialAnalysis.timestamp,
        status: BatchStatus.good,
        expiryDate: DateTime.now().add(const Duration(days: 7)),
        notes: 'Papaya shipment arrived. First scan complete.',
        history: [initialAnalysis],
      ),
      FruitBatch(
        batchId: 'BATCH-002',
        arrivalTime: DateTime.now().subtract(
          const Duration(hours: 12, minutes: 15),
        ),
        firstInspectionTime: DateTime.now().subtract(
          const Duration(hours: 11, minutes: 30),
        ),
        status: BatchStatus.risk,
        expiryDate: DateTime.now().add(const Duration(days: 4)),
        notes: 'Mango batch showing rising humidity risk.',
      ),
      FruitBatch(
        batchId: 'BATCH-003',
        arrivalTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        firstInspectionTime: DateTime.now().subtract(
          const Duration(days: 1, hours: 1, minutes: 45),
        ),
        status: BatchStatus.spoiled,
        expiryDate: DateTime.now().add(const Duration(days: 1)),
        notes: 'Banana batch marked for immediate exit.',
      ),
    ]);
  }

  void _initializeRfidLogs() {
    rfidLogs.clear();
    rfidLogs.addAll([
      RfidLog(
        userId: 'WKR-1001',
        entryTime: DateTime.now().subtract(
          const Duration(hours: 2, minutes: 22),
        ),
        exitTime: DateTime.now().subtract(
          const Duration(hours: 1, minutes: 50),
        ),
        zoneAccess: ['Zone A', 'Zone B'],
      ),
      RfidLog(
        userId: 'WKR-1007',
        entryTime: DateTime.now().subtract(
          const Duration(hours: 1, minutes: 34),
        ),
        exitTime: DateTime.now().subtract(const Duration(hours: 0, minutes: 8)),
        zoneAccess: ['Zone C'],
      ),
      RfidLog(
        userId: 'WKR-1023',
        entryTime: DateTime.now().subtract(const Duration(minutes: 48)),
        exitTime: null,
        zoneAccess: ['Zone D', 'Zone A'],
      ),
    ]);
  }

  CctvAnalysis _defaultAnalysis() {
    return CctvAnalysis(
      timestamp: DateTime.now(),
      goodPercentage: 0,
      partialPercentage: 0,
      spoiledPercentage: 0,
      healthScore: 0,
      spoilageProbability: 0,
      healthStatus: 'Unknown',
      imageAsset: 'assets/images/papaya.png',
      batchId: 'BATCH-000',
    );
  }

  CctvAnalysis get latestCctvAnalysis =>
      cctvAnalyses.isNotEmpty ? cctvAnalyses.first : _defaultAnalysis();

  double get goodHealthPercentage => latestCctvAnalysis.goodPercentage;
  double get partialHealthPercentage => latestCctvAnalysis.partialPercentage;
  double get spoiledHealthPercentage => latestCctvAnalysis.spoiledPercentage;
  double get overallHealthScore => latestCctvAnalysis.healthScore;
  double get spoilageProbability => latestCctvAnalysis.spoilageProbability;
  String get aiStatus => latestCctvAnalysis.healthStatus;
  String get latestCctvImageAsset => latestCctvAnalysis.imageAsset;
  List<FruitBatch> get recentBatches => batches;
  List<RfidLog> get recentRfidLogs => rfidLogs;

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

      final tempHigh = zone.temperature > zone.tempUpper;
      final tempLow = zone.temperature < zone.tempLower;
      final humidityHigh = zone.humidity > zone.humidityUpper;
      final humidityLow = zone.humidity < zone.humidityLower;

      if (autoCoolingEnabled && tempHigh) {
        if (!zone.coolingActive) {
          zone.coolingActive = true;
          _addAlert(
            title: 'Auto-Cooling Activated',
            message:
                '${zone.name}: Temperature ${zone.temperature.toStringAsFixed(1)}°C exceeds upper threshold ${zone.tempUpper.toStringAsFixed(1)}°C. Cooling engaged.',
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
                '${zone.name}: Humidity ${zone.humidity.toStringAsFixed(0)}% exceeds upper threshold ${zone.humidityUpper.toStringAsFixed(0)}%. Ventilation/dehumidifier engaged.',
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

      if (autoDehumidifyEnabled && humidityLow) {
        zone.humidity = (zone.humidity + 0.7).clamp(40.0, 95.0);
      }

      if (autoCoolingEnabled && tempLow) {
        zone.temperature = (zone.temperature + 0.3).clamp(1.0, 15.0);
      }

      if ((tempLow || humidityLow) && zone.history.isNotEmpty) {
        if (tempLow) {
          _addAlert(
            title: 'Low Temperature Alert',
            message:
                '${zone.name}: Temperature ${zone.temperature.toStringAsFixed(1)}°C below lower threshold ${zone.tempLower.toStringAsFixed(1)}°C.',
            type: AlertType.temperature,
            severity: AlertSeverity.warning,
            zoneId: zone.id,
          );
        }
        if (humidityLow) {
          _addAlert(
            title: 'Low Humidity Alert',
            message:
                '${zone.name}: Humidity ${zone.humidity.toStringAsFixed(0)}% below lower threshold ${zone.humidityLower.toStringAsFixed(0)}%.',
            type: AlertType.humidity,
            severity: AlertSeverity.warning,
            zoneId: zone.id,
          );
        }
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

    _simulateCctvAnalysis();
    _simulateRfidActivity();

    _zonesController.add(zones);
    _alertsController.add(alerts);
  }

  void _simulateCctvAnalysis() {
    final averageTemp = averageTemperature;
    final averageHumidityValue = averageHumidity;
    final spoilageBase = ((averageTemp - 8) * 2.2 +
            (averageHumidityValue - 85) * 0.8)
        .clamp(0.0, 40.0);
    final randomSwing = (_random.nextDouble() - 0.4) * 15;
    final spoilageProbability = (spoilageBase + randomSwing).clamp(4.0, 88.0);

    final good =
        (100 - spoilageProbability) * (0.55 + _random.nextDouble() * 0.15);
    final partial = (100 - good) * (0.35 + _random.nextDouble() * 0.15);
    final spoiled = (100 - good - partial).clamp(0.0, 99.0);
    final healthScore = (100 - spoilageProbability - (_random.nextDouble() * 3))
        .clamp(18.0, 100.0);

    final status =
        healthScore > 75
            ? 'Good'
            : healthScore > 45
            ? 'Risk'
            : 'Spoiled';

    final analysis = CctvAnalysis(
      timestamp: DateTime.now(),
      goodPercentage: good,
      partialPercentage: partial,
      spoiledPercentage: spoiled,
      healthScore: healthScore,
      spoilageProbability: spoilageProbability,
      healthStatus: status,
      imageAsset: 'assets/images/papaya.png',
      batchId: batches.isNotEmpty ? batches.first.batchId : 'BATCH-001',
    );

    cctvAnalyses.insert(0, analysis);
    if (cctvAnalyses.length > 10) cctvAnalyses.removeLast();

    if (batches.isNotEmpty) {
      final batch = batches.first;
      batch.status =
          status == 'Good'
              ? BatchStatus.good
              : status == 'Risk'
              ? BatchStatus.risk
              : BatchStatus.spoiled;
      batch.history.insert(0, analysis);
      if (batch.history.length > 10) {
        batch.history.removeLast();
      }
      if (status == 'Spoiled') {
        batch.expiryDate = DateTime.now().add(const Duration(days: 1));
      }
    }

    if (status == 'Risk' && _random.nextDouble() > 0.7) {
      _addAlert(
        title: 'AI Fruit Risk Detected',
        message:
            'CCTV batch ${analysis.batchId}: fruit health is at ${analysis.healthScore.toStringAsFixed(0)}%.',
        type: AlertType.system,
        severity: AlertSeverity.warning,
      );
    }

    if (status == 'Spoiled' && _random.nextDouble() > 0.55) {
      _addAlert(
        title: 'AI Spoilage Alert',
        message:
            'CCTV batch ${analysis.batchId} shows ${analysis.spoiledPercentage.toStringAsFixed(0)}% spoiled fruits.',
        type: AlertType.temperature,
        severity: AlertSeverity.critical,
      );
    }
  }

  void _simulateRfidActivity() {
    if (_random.nextBool() && _random.nextDouble() > 0.45) {
      final userId = 'WKR-${1000 + _random.nextInt(90)}';
      final entryTime = DateTime.now().subtract(const Duration(minutes: 5));
      final exitTime =
          _random.nextBool()
              ? DateTime.now().subtract(const Duration(minutes: 1))
              : null;
      final zones = ['Zone A', 'Zone B', 'Zone C', 'Zone D'];
      final accessCount = 1 + _random.nextInt(2);
      final zoneAccess = List.generate(
        accessCount,
        (_) => zones[_random.nextInt(zones.length)],
      );

      rfidLogs.insert(
        0,
        RfidLog(
          userId: userId,
          entryTime: entryTime,
          exitTime: exitTime,
          zoneAccess: zoneAccess,
        ),
      );
      if (rfidLogs.length > 12) {
        rfidLogs.removeLast();
      }

      _addAlert(
        title: 'RFID Event Recorded',
        message:
            '$userId ${exitTime == null ? 'entered' : 'exited'} warehouse.',
        type: AlertType.security,
        severity: AlertSeverity.info,
      );
    }
  }

  WarehouseZone _findZone(String zoneId) =>
      zones.firstWhere((zone) => zone.id == zoneId);

  void setZoneThresholds(
    String zoneId, {
    required double tempLower,
    required double tempUpper,
    required double humidityLower,
    required double humidityUpper,
  }) {
    final zone = _findZone(zoneId);
    zone.thresholdMode = ThresholdMode.manual;
    zone.tempLower = tempLower;
    zone.tempUpper = tempUpper;
    zone.humidityLower = humidityLower;
    zone.humidityUpper = humidityUpper;
    _addAlert(
      title: '${zone.name} Thresholds Updated',
      message:
          'Manual thresholds set: ${tempLower.toStringAsFixed(1)}°C–${tempUpper.toStringAsFixed(1)}°C, ${humidityLower.toStringAsFixed(0)}%–${humidityUpper.toStringAsFixed(0)}%.',
      type: AlertType.system,
      severity: AlertSeverity.info,
      zoneId: zoneId,
    );
    _zonesController.add(zones);
    _alertsController.add(alerts);
  }

  void setZoneThresholdMode(String zoneId, ThresholdMode mode) {
    final zone = _findZone(zoneId);
    if (mode == ThresholdMode.auto) {
      zone.applyAutoThresholds();
      _addAlert(
        title: '${zone.name} Auto Thresholds Applied',
        message:
            'Recommended ${zone.type == ZoneType.tropicalFruit ? 'Tropical Fruit' : 'Packaging/Loading Bay'} thresholds were applied.',
        type: AlertType.system,
        severity: AlertSeverity.info,
        zoneId: zoneId,
      );
    } else {
      zone.thresholdMode = ThresholdMode.manual;
      _addAlert(
        title: '${zone.name} Manual Threshold Mode',
        message: 'Manual threshold adjustments are now enabled for this zone.',
        type: AlertType.system,
        severity: AlertSeverity.info,
        zoneId: zoneId,
      );
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
      zones.where((z) => z.getStatus() == ZoneStatus.critical).length;
}
