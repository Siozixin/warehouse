import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/alert.dart';
import '../models/warehouse_zone.dart';
import '../services/sensor_simulator_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/temperature_chart.dart';
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
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _service.start();
    _unreadCount = _service.unreadCount;
    _service.alertsStream.listen((alerts) {
      if (mounted) {
        setState(() => _unreadCount = alerts.where((a) => !a.isRead).length);
      }
    });
  }

  @override
  void dispose() {
    _service.stop();
    super.dispose();
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
                        const SizedBox(height: 16),
                        TemperatureChart(
                          readings: selectedZone.history,
                          maxThreshold: _service.maxTemperature,
                          title:
                              '${selectedZone.name} — Live Sensor Data',
                        ),
                        const SizedBox(height: 16),
                        _buildZoneSelector(zones),
                        const SizedBox(height: 12),
                        ...zones.map(
                          (zone) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ZoneCard(
                              zone: zone,
                              maxTemp: _service.maxTemperature,
                              maxHumidity: _service.maxHumidity,
                              onToggleCooling: () =>
                                  _service.toggleCooling(zone.id),
                            ),
                          ),
                        ),
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
            child: const Icon(Icons.warehouse, color: AppTheme.accent, size: 28),
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
          _notificationButton(),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _notificationButton() {
    return Stack(
      children: [
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          icon: const Icon(Icons.notifications_outlined,
              color: AppTheme.textSecondary),
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppTheme.critical,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$_unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
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
            style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.lock, color: AppTheme.success, size: 14),
          const SizedBox(width: 4),
          const Text(
            'TLS Encrypted',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        StatCard(
          label: 'Avg Temperature',
          value: _service.averageTemperature.toStringAsFixed(1),
          unit: '°C',
          icon: Icons.thermostat,
          color: AppTheme.accent,
          subtitle: 'Target: ≤${_service.maxTemperature}°C',
        ),
        StatCard(
          label: 'Avg Humidity',
          value: _service.averageHumidity.toStringAsFixed(0),
          unit: '%',
          icon: Icons.water_drop,
          color: AppTheme.info,
          subtitle: 'Target: ≤${_service.maxHumidity}%',
        ),
        StatCard(
          label: 'Cooling Active',
          value: '${_service.activeCoolingCount}',
          unit: '/ ${zones.length} zones',
          icon: Icons.ac_unit,
          color: AppTheme.success,
        ),
        StatCard(
          label: 'Critical Zones',
          value: '${_service.criticalZoneCount}',
          icon: Icons.warning_amber_rounded,
          color: _service.criticalZoneCount > 0
              ? AppTheme.critical
              : AppTheme.success,
        ),
      ],
    );
  }

  Widget _buildZoneSelector(List<WarehouseZone> zones) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: zones.asMap().entries.map((entry) {
          final index = entry.key;
          final zone = entry.value;
          final isSelected = index == _selectedZoneIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(zone.name),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedZoneIndex = index),
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              child: const Text('View all', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        ...recent.map((alert) => Container(
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
            )),
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
