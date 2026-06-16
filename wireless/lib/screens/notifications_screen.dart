import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/alert.dart';
import '../services/sensor_simulator_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = SensorSimulatorService();
  final _timeFormat = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _service.markAllAlertsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<List<Alert>>(
        stream: _service.alertsStream,
        initialData: _service.alerts,
        builder: (context, snapshot) {
          final alerts = snapshot.data ?? [];
          if (alerts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _AlertTile(
                alert: alert,
                timeFormat: _timeFormat,
                onTap: () => _service.markAlertRead(alert.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final Alert alert;
  final DateFormat timeFormat;
  final VoidCallback onTap;

  const _AlertTile({
    required this.alert,
    required this.timeFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(alert.severity);
    final icon = _typeIcon(alert.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: alert.isRead ? AppTheme.surface : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.isRead
                ? AppTheme.cardBorder
                : color.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight:
                                alert.isRead ? FontWeight.normal : FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!alert.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.message,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeFormat.format(alert.timestamp),
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
    );
  }

  Color _severityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return AppTheme.info;
      case AlertSeverity.warning:
        return AppTheme.warning;
      case AlertSeverity.critical:
        return AppTheme.critical;
    }
  }

  IconData _typeIcon(AlertType type) {
    switch (type) {
      case AlertType.temperature:
        return Icons.thermostat;
      case AlertType.humidity:
        return Icons.water_drop;
      case AlertType.system:
        return Icons.settings;
      case AlertType.security:
        return Icons.security;
    }
  }
}
