import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/alert.dart';
import '../models/fruit_batch.dart';
import '../models/rfid_log.dart';
import '../models/warehouse_zone.dart';
import '../services/sensor_simulator_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sensor_charts.dart';
import '../widgets/stat_card.dart';
import '../widgets/zone_card.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = SensorSimulatorService();
  final _timeFormat = DateFormat('HH:mm:ss');
  int _selectedZoneIndex = 0;
  late ThresholdMode _selectedThresholdMode;
  late TextEditingController _tempLowerController;
  late TextEditingController _tempUpperController;
  late TextEditingController _humidityLowerController;
  late TextEditingController _humidityUpperController;

  @override
  void initState() {
    super.initState();
    _service.start();
    _selectedThresholdMode = ThresholdMode.auto;
    _tempLowerController = TextEditingController();
    _tempUpperController = TextEditingController();
    _humidityLowerController = TextEditingController();
    _humidityUpperController = TextEditingController();
    _syncSelectedZoneInputs(_service.zones[_selectedZoneIndex]);
    // alerts stream handled via direct reads in RecentAlerts; no header badge
  }

  @override
  void dispose() {
    _service.stop();
    _tempLowerController.dispose();
    _tempUpperController.dispose();
    _humidityLowerController.dispose();
    _humidityUpperController.dispose();
    super.dispose();
  }

  void _syncSelectedZoneInputs(WarehouseZone zone) {
    _selectedThresholdMode = zone.thresholdMode;
    _tempLowerController.text = zone.tempLower.toStringAsFixed(1);
    _tempUpperController.text = zone.tempUpper.toStringAsFixed(1);
    _humidityLowerController.text = zone.humidityLower.toStringAsFixed(0);
    _humidityUpperController.text = zone.humidityUpper.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<WarehouseZone>>(
          stream: _service.zonesStream,
          initialData: _service.zones,
          builder: (context, snapshot) {
            final zones = snapshot.data ?? _service.zones;
            final selectedZone = zones[_selectedZoneIndex];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildConnectionBar()),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(zones),
                        const SizedBox(height: 12),
                        _buildAiSummaryCards(zones),
                        const SizedBox(height: 10),
                        _buildAIPanel(),
                        const SizedBox(height: 14),
                        _buildZoneSelector(zones),
                        const SizedBox(height: 10),
                        _buildSelectedZoneControl(selectedZone),
                        const SizedBox(height: 10),
                        SensorCharts(
                          readings: selectedZone.history,
                          minTempThreshold: selectedZone.tempLower,
                          maxTempThreshold: selectedZone.tempUpper,
                          minHumidityThreshold: selectedZone.humidityLower,
                          maxHumidityThreshold: selectedZone.humidityUpper,
                          zoneName: selectedZone.name,
                        ),
                        const SizedBox(height: 12),
                        ...zones.map(
                          (zone) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ZoneCard(
                              zone: zone,
                              autoCoolingEnabled: _service.autoCoolingEnabled,
                              autoDehumidifyEnabled:
                                  _service.autoDehumidifyEnabled,
                              onToggleCooling:
                                  () => _service.toggleCooling(zone.id),
                              onToggleDehumidifier:
                                  () => _service.toggleDehumidifier(zone.id),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStorageLog(),
                        const SizedBox(height: 12),
                        _buildSecurityPanel(),
                        const SizedBox(height: 16),
                        _buildRecentAlerts(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warehouse,
              color: AppTheme.accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warehouse Monitor',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '5G IoT Temperature Control',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildConnectionBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '5G Connected',
            style: TextStyle(
              color: AppTheme.success,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.lock, color: AppTheme.success, size: 14),
          const SizedBox(width: 4),
          const Text(
            'TLS Encrypted',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(width: 12),
          Text(
            _service.networkSpeedLabel,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(width: 12),
          Text(
            'Devices: ${_service.devicesConnected}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.network_cell, color: AppTheme.textSecondary, size: 14),
              const SizedBox(width: 4),
              Text(
                _service.signalLabel,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Loss: ${_service.packetLossLabel}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Updated ${_timeFormat.format(DateTime.now())}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<WarehouseZone> zones) {
    final cards = [
      StatCard(
        label: 'Avg Temp',
        value: _service.averageTemperature.toStringAsFixed(1),
        unit: '°C',
        icon: Icons.thermostat,
        color: ChartColors.temperature,
        subtitle: '≤${_service.maxTemperature.toStringAsFixed(1)}°C',
      ),
      StatCard(
        label: 'Avg Humidity',
        value: _service.averageHumidity.toStringAsFixed(0),
        unit: '%',
        icon: Icons.water_drop,
        color: ChartColors.humidity,
        subtitle: '≤${_service.maxHumidity.toStringAsFixed(0)}%',
      ),
      StatCard(
        label: 'Cooling/Heating',
        value: '${_service.activeCoolingCount}',
        unit: '/${zones.length}',
        icon: Icons.ac_unit,
        color: AppTheme.success,
      ),
      StatCard(
        label: 'Humidifier/Dehumidifier',
        value: '${_service.activeDehumidifierCount}',
        unit: '/${zones.length}',
        icon: Icons.air,
        color: ChartColors.humidity,
      ),
      StatCard(
        label: 'Critical',
        value: '${_service.criticalZoneCount}',
        icon: Icons.warning_amber_rounded,
        color:
            _service.criticalZoneCount > 0
                ? AppTheme.critical
                : AppTheme.success,
      ),
    ];

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => SizedBox(width: 228, child: cards[index]),
      ),
    );
  }

  Widget _buildAiSummaryCards(List<WarehouseZone> zones) {
    final cards = [
      StatCard(
        label: 'AI Fruit Health',
        value: _service.overallHealthScore.toStringAsFixed(0),
        unit: '%',
        icon: Icons.health_and_safety,
        color: AppTheme.accent,
        subtitle: _service.aiStatus,
      ),
      StatCard(
        label: 'Good Condition',
        value: _service.goodHealthPercentage.toStringAsFixed(0),
        unit: '%',
        icon: Icons.check_circle,
        color: AppTheme.success,
      ),
      StatCard(
        label: 'Risk Condition',
        value: _service.partialHealthPercentage.toStringAsFixed(0),
        unit: '%',
        icon: Icons.report_problem,
        color: AppTheme.warning,
      ),
      StatCard(
        label: 'Spoiled',
        value: _service.spoiledHealthPercentage.toStringAsFixed(0),
        unit: '%',
        icon: Icons.cancel,
        color: AppTheme.critical,
      ),
    ];

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => SizedBox(width: 228, child: cards[index]),
      ),
    );
  }

  Widget _buildAIPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI CCTV Fruit Monitoring',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest analysis: ${_service.aiStatus}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildMiniLabel(
                      'Good',
                      _service.goodHealthPercentage,
                      AppTheme.success,
                    ),
                    const SizedBox(height: 6),
                    _buildMiniLabel(
                      'Partial',
                      _service.partialHealthPercentage,
                      AppTheme.warning,
                    ),
                    const SizedBox(height: 6),
                    _buildMiniLabel(
                      'Spoiled',
                      _service.spoiledHealthPercentage,
                      AppTheme.critical,
                    ),
                    const SizedBox(height: 6),
                    _buildMiniLabel(
                      'Spoilage Risk',
                      _service.spoilageProbability,
                      AppTheme.accent,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Batch: ${_service.latestCctvAnalysis.batchId}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  _service.latestCctvImageAsset,
                  height: 130,
                  width: 130,
                  fit: BoxFit.cover,
                  // errorBuilder: (context, error, stackTrace) {
                  //   // Show placeholder and a small label when asset fails to load
                  //   return Container(
                  //     height: 130,
                  //     width: 130,
                  //     color: AppTheme.surfaceLight,
                  //     alignment: Alignment.center,
                  //     child: Column(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: const [
                  //         Icon(
                  //           Icons.broken_image,
                  //           color: AppTheme.textSecondary,
                  //           size: 36,
                  //         ),
                  //         SizedBox(height: 6),
                  //         Text(
                  //           'Image not found',
                  //           style: TextStyle(
                  //             color: AppTheme.textSecondary,
                  //             fontSize: 10,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   );
                  // },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniLabel(String label, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: ${value.toStringAsFixed(0)}%',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildStorageLog() {
    final batches = _service.recentBatches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Storage Log System',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            children: [
              _buildStorageLogHeader(),
              ...batches.map(_buildStorageLogRow),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStorageLogHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Row(
        children: const [
          Expanded(
            child: Text(
              'Batch ID',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              'Arrival',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              'Inspection',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              'Status',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              'Expiry',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageLogRow(FruitBatch batch) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              batch.batchId,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              _timeFormat.format(batch.arrivalTime),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _timeFormat.format(batch.firstInspectionTime),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              batch.status.name.toUpperCase(),
              style: TextStyle(
                color:
                    batch.status == BatchStatus.good
                        ? AppTheme.success
                        : batch.status == BatchStatus.risk
                        ? AppTheme.warning
                        : AppTheme.critical,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              DateFormat('MM/dd').format(batch.expiryDate),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityPanel() {
    final logs = _service.recentRfidLogs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RFID Security Panel',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            children: [_buildSecurityHeader(), ...logs.map(_buildSecurityRow)],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Row(
        children: const [
          Expanded(
            child: Text(
              'User ID',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              'Entry',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              'Exit',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              'Zones',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityRow(RfidLog log) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              log.userId,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              _timeFormat.format(log.entryTime),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              log.exitTime != null ? _timeFormat.format(log.exitTime!) : '-',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              log.zoneAccess.join(', '),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneSelector(List<WarehouseZone> zones) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            zones.asMap().entries.map((entry) {
              final index = entry.key;
              final zone = entry.value;
              final isSelected = index == _selectedZoneIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(zone.name),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedZoneIndex = index;
                      _syncSelectedZoneInputs(zone);
                    });
                  },
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSelectedZoneControl(WarehouseZone zone) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${zone.name} Threshold Control',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${zone.location} • ${zone.type == ZoneType.tropicalFruit ? 'Tropical Fruit Storage' : 'Packaging/Loading Bay'}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _modeChip(zone, ThresholdMode.auto, 'Auto'),
              const SizedBox(width: 8),
              _modeChip(zone, ThresholdMode.manual, 'Manual'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _thresholdInput(
                  label: 'Temp lower',
                  controller: _tempLowerController,
                  suffix: '°C',
                  enabled: _selectedThresholdMode == ThresholdMode.manual,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _thresholdInput(
                  label: 'Temp upper',
                  controller: _tempUpperController,
                  suffix: '°C',
                  enabled: _selectedThresholdMode == ThresholdMode.manual,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _thresholdInput(
                  label: 'RH lower',
                  controller: _humidityLowerController,
                  suffix: '%',
                  enabled: _selectedThresholdMode == ThresholdMode.manual,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _thresholdInput(
                  label: 'RH upper',
                  controller: _humidityUpperController,
                  suffix: '%',
                  enabled: _selectedThresholdMode == ThresholdMode.manual,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _selectedThresholdMode == ThresholdMode.manual
                          ? () => _applyZoneThresholds(zone)
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply Manual Thresholds'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _service.setZoneThresholdMode(
                        zone.id,
                        ThresholdMode.auto,
                      );
                      _syncSelectedZoneInputs(zone);
                    });
                  },
                  child: const Text('Use Recommended'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeChip(WarehouseZone zone, ThresholdMode mode, String label) {
    final active = _selectedThresholdMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) {
        setState(() {
          _selectedThresholdMode = mode;
          _service.setZoneThresholdMode(zone.id, mode);
          _syncSelectedZoneInputs(zone);
        });
      },
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      labelStyle: TextStyle(
        color: active ? Colors.white : AppTheme.textSecondary,
        fontSize: 12,
      ),
      side: BorderSide(color: active ? AppTheme.primary : AppTheme.cardBorder),
    );
  }

  Widget _thresholdInput({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required bool enabled,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  void _applyZoneThresholds(WarehouseZone zone) {
    final tempLower = double.tryParse(_tempLowerController.text);
    final tempUpper = double.tryParse(_tempUpperController.text);
    final humidityLower = double.tryParse(_humidityLowerController.text);
    final humidityUpper = double.tryParse(_humidityUpperController.text);

    if (tempLower == null ||
        tempUpper == null ||
        humidityLower == null ||
        humidityUpper == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid threshold values.')),
      );
      return;
    }
    if (tempLower >= tempUpper || humidityLower >= humidityUpper) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lower values must be below upper values.'),
        ),
      );
      return;
    }

    setState(() {
      _service.setZoneThresholds(
        zone.id,
        tempLower: tempLower,
        tempUpper: tempUpper,
        humidityLower: humidityLower,
        humidityUpper: humidityUpper,
      );
      _selectedThresholdMode = ThresholdMode.manual;
      _syncSelectedZoneInputs(zone);
    });
  }

  Widget _buildRecentAlerts() {
    final recent = _service.alerts.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Alerts',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
              child: const Text('View all', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        ...recent.map(
          (alert) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                Icon(
                  _alertIcon(alert.severity),
                  color: _alertColor(alert.severity),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _timeFormat.format(alert.timestamp),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
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
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: BottomNavigationBar(
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: AppTheme.textSecondary,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          }
        },
      ),
    );
  }

  IconData _alertIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.error;
      case AlertSeverity.warning:
        return Icons.warning;
      case AlertSeverity.info:
        return Icons.info;
    }
  }

  Color _alertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return AppTheme.critical;
      case AlertSeverity.warning:
        return AppTheme.warning;
      case AlertSeverity.info:
        return AppTheme.info;
    }
  }
}
