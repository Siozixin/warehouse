import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/sensor_reading.dart';
import '../theme/app_theme.dart';

class TemperatureChart extends StatelessWidget {
  final List<SensorReading> readings;
  final double maxThreshold;
  final String title;

  const TemperatureChart({
    super.key,
    required this.readings,
    required this.maxThreshold,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
  if (readings.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('Collecting data...', style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final spots = readings
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.temperature))
        .toList();

    final humiditySpots = readings
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.humidity))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(AppTheme.accent, 'Temperature (°C)'),
              const SizedBox(width: 16),
              _legendDot(AppTheme.info, 'Humidity (%)'),
              const SizedBox(width: 16),
              _legendDot(AppTheme.warning, 'Threshold'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.cardBorder.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.accent,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.accent.withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: humiditySpots,
                    isCurved: true,
                    color: AppTheme.info,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: List.generate(
                      readings.length,
                      (i) => FlSpot(i.toDouble(), maxThreshold),
                    ),
                    isCurved: false,
                    color: AppTheme.warning.withValues(alpha: 0.6),
                    barWidth: 1,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}
