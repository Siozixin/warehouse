import 'package:flutter/material.dart';

import '../models/warehouse_zone.dart';
import '../theme/app_theme.dart';
import 'sensor_charts.dart';

class ZoneCard extends StatelessWidget {
  final WarehouseZone zone;
  final double maxTemp;
  final double maxHumidity;
  final VoidCallback onToggleCooling;
  final VoidCallback onToggleDehumidifier;

  const ZoneCard({
    super.key,
    required this.zone,
    required this.maxTemp,
    required this.maxHumidity,
    required this.onToggleCooling,
    required this.onToggleDehumidifier,
  });

  @override
  Widget build(BuildContext context) {
    final status = zone.getStatus(maxTemp, maxHumidity);
    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              status == ZoneStatus.critical
                  ? AppTheme.critical.withValues(alpha: 0.5)
                  : AppTheme.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      zone.location,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  icon: Icons.thermostat,
                  label: 'Temperature',
                  value: '${zone.temperature.toStringAsFixed(1)}°C',
                  color:
                      zone.temperature > maxTemp
                          ? AppTheme.critical
                          : ChartColors.temperature,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricTile(
                  icon: Icons.water_drop,
                  label: 'Humidity',
                  value: '${zone.humidity.toStringAsFixed(0)}%',
                  color:
                      zone.humidity > maxHumidity
                          ? AppTheme.critical
                          : ChartColors.humidity,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _actuatorRow(
            icon: Icons.ac_unit,
            label: 'Cooling',
            active: zone.coolingActive,
            activeColor: AppTheme.success,
            onToggle: onToggleCooling,
          ),
          const SizedBox(height: 6),
          _actuatorRow(
            icon: Icons.air,
            label: 'Dehumidifier / Ventilation',
            active: zone.dehumidifierActive,
            activeColor: ChartColors.humidity,
            onToggle: onToggleDehumidifier,
          ),
        ],
      ),
    );
  }

  Widget _actuatorRow({
    required IconData icon,
    required String label,
    required bool active,
    required Color activeColor,
    required VoidCallback onToggle,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: active ? activeColor : AppTheme.textSecondary,
          size: 16,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            active ? '$label — ON' : '$label — OFF',
            style: TextStyle(
              color: active ? activeColor : AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onToggle,
          icon: Icon(active ? Icons.stop : Icons.play_arrow, size: 14),
          label: Text(
            active ? 'Stop' : 'Start',
            style: const TextStyle(fontSize: 11),
          ),
          style: TextButton.styleFrom(
            foregroundColor: active ? AppTheme.critical : AppTheme.accent,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Widget _metricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(ZoneStatus status) {
    switch (status) {
      case ZoneStatus.normal:
        return AppTheme.success;
      case ZoneStatus.warning:
        return AppTheme.warning;
      case ZoneStatus.critical:
        return AppTheme.critical;
    }
  }

  String _statusLabel(ZoneStatus status) {
    switch (status) {
      case ZoneStatus.normal:
        return 'NORMAL';
      case ZoneStatus.warning:
        return 'WARNING';
      case ZoneStatus.critical:
        return 'CRITICAL';
    }
  }
}
