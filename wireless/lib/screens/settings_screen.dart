import 'package:flutter/material.dart';

import '../services/sensor_simulator_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SensorSimulatorService();
  late double _maxTemp;
  late double _maxHumidity;
  late bool _autoCooling;
  late bool _autoDehumidify;

  @override
  void initState() {
    super.initState();
    _maxTemp = _service.maxTemperature;
    _maxHumidity = _service.maxHumidity;
    _autoCooling = _service.autoCoolingEnabled;
    _autoDehumidify = _service.autoDehumidifyEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings & Control',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Temperature Thresholds'),
          _settingsCard(
            child: Column(
              children: [
                _sliderRow(
                  label: 'Max Temperature',
                  value: _maxTemp,
                  min: 2,
                  max: 15,
                  unit: '°C',
                  color: AppTheme.accent,
                  onChanged: (v) => setState(() => _maxTemp = v),
                ),
                const Divider(color: AppTheme.cardBorder),
                _sliderRow(
                  label: 'Max Humidity',
                  value: _maxHumidity,
                  min: 50,
                  max: 95,
                  unit: '%',
                  color: AppTheme.info,
                  onChanged: (v) => setState(() => _maxHumidity = v),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _service.setThresholds(_maxTemp, _maxHumidity);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thresholds updated')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Apply Thresholds'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Automation'),
          _settingsCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Auto-Cooling',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  subtitle: const Text(
                    'Engage cooling when temperature exceeds threshold',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  value: _autoCooling,
                  activeColor: AppTheme.accent,
                  onChanged: (v) {
                    setState(() => _autoCooling = v);
                    _service.setAutoCooling(v);
                  },
                ),
                const Divider(color: AppTheme.cardBorder),
                SwitchListTile(
                  title: const Text(
                    'Auto-Dehumidify',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  subtitle: const Text(
                    'Engage ventilation/dehumidifier when humidity exceeds threshold',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  value: _autoDehumidify,
                  activeColor: AppTheme.accent,
                  onChanged: (v) {
                    setState(() => _autoDehumidify = v);
                    _service.setAutoDehumidify(v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Security'),
          _settingsCard(
            child: Column(
              children: [
                _securityRow(
                  icon: Icons.lock,
                  label: 'Data Encryption',
                  value: 'AES-256 / TLS 1.3',
                  status: 'Active',
                  color: AppTheme.success,
                ),
                const Divider(color: AppTheme.cardBorder),
                _securityRow(
                  icon: Icons.verified_user,
                  label: 'Multi-Factor Auth',
                  value: 'Manager Account',
                  status: 'Enabled',
                  color: AppTheme.success,
                ),
                const Divider(color: AppTheme.cardBorder),
                _securityRow(
                  icon: Icons.smart_toy,
                  label: 'AI Anomaly Detection',
                  value: 'Control & Login Monitor',
                  status: 'Active',
                  color: AppTheme.success,
                ),
                const Divider(color: AppTheme.cardBorder),
                _securityRow(
                  icon: Icons.history,
                  label: 'Audit Logs',
                  value: 'All changes tracked',
                  status: 'Recording',
                  color: AppTheme.info,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Connectivity'),
          _settingsCard(
            child: Column(
              children: [
                _securityRow(
                  icon: Icons.signal_cellular_alt,
                  label: '5G Gateway',
                  value: 'Edge Server #WS-001',
                  status: 'Connected',
                  color: AppTheme.success,
                ),
                const Divider(color: AppTheme.cardBorder),
                _securityRow(
                  icon: Icons.sensors,
                  label: 'Active Sensors',
                  value: '${_service.zones.length} zones monitored',
                  status: 'Online',
                  color: AppTheme.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _settingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: child,
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
              const Spacer(),
              Text(
                '${value.toStringAsFixed(1)}$unit',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: color,
            inactiveColor: AppTheme.cardBorder,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _securityRow({
    required IconData icon,
    required String label,
    required String value,
    required String status,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                Text(value, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
