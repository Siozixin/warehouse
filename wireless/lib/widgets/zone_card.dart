import 'package:flutter/material.dart';

import '../models/warehouse_zone.dart';
import '../theme/app_theme.dart';

class ZoneCard extends StatelessWidget {
  final WarehouseZone zone;
  final double maxTemp;
  final double maxHumidity;
  final VoidCallback onToggleCooling;

  const ZoneCard({
    super.key,
    required this.zone,
    required this.maxTemp,
    required this.maxHumidity,
    required this.onToggleCooling,
  });

  @override
  Widget build(BuildContext context) {
    final status = zone.getStatus(maxTemp, maxHumidity);
    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == ZoneStatus.critical
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      zone.location,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  icon: Icons.thermostat,
                  label: 'Temperature',
                  value: '${zone.temperature.toStringAsFixed(1)}°C',
                  color: zone.temperature > maxTemp
                      ? AppTheme.critical
                      : AppTheme.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricTile(
                  icon: Icons.water_drop,
                  label: 'Humidity',
                  value: '${zone.humidity.toStringAsFixed(0)}%',
                  color: zone.humidity > maxHumidity
                      ? AppTheme.critical
                      : AppTheme.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                zone.coolingActive
                    ? Icons.ac_unit
                    : Icons.ac_unit_outlined,
                color: zone.coolingActive
                    ? AppTheme.success
                    : AppTheme.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                zone.coolingActive ? 'Cooling Active' : 'Cooling Off',
                style: TextStyle(
                  color: zone.coolingActive
                      ? AppTheme.success
                      : AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onToggleCooling,
                icon: Icon(
                  zone.coolingActive ? Icons.stop : Icons.play_arrow,
                  size: 16,
                ),
                label: Text(
                  zone.coolingActive ? 'Stop' : 'Start',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor:
                      zone.coolingActive ? AppTheme.critical : AppTheme.accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
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
                  fontSize: 16,
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
