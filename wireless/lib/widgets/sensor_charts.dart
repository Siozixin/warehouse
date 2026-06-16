import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sensor_reading.dart';
import '../theme/app_theme.dart';

/// Distinct colors so temperature and humidity are easy to distinguish.
class ChartColors {
  static const temperature = Color(0xFFFF6B35);
  static const humidity = Color(0xFF7C4DFF);
  static const threshold = Color(0xFFFFC107);
}

class SensorCharts extends StatelessWidget {
  final List<SensorReading> readings;
  final double maxTempThreshold;
  final double maxHumidityThreshold;
  final String zoneName;

  const SensorCharts({
    super.key,
    required this.readings,
    required this.maxTempThreshold,
    required this.maxHumidityThreshold,
    required this.zoneName,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: const Text(
          'Collecting sensor data...',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$zoneName — Live Sensor Data',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        _MetricChart(
          title: 'Temperature',
          unit: '°C',
          lineColor: ChartColors.temperature,
          threshold: maxTempThreshold,
          thresholdLabel: 'Max ${maxTempThreshold.toStringAsFixed(1)}°C',
          readings: readings,
          valueOf: (r) => r.temperature,
          minY: 0,
          maxY: 16,
        ),
        const SizedBox(height: 10),
        _MetricChart(
          title: 'Humidity',
          unit: '%',
          lineColor: ChartColors.humidity,
          threshold: maxHumidityThreshold,
          thresholdLabel: 'Max ${maxHumidityThreshold.toStringAsFixed(0)}%',
          readings: readings,
          valueOf: (r) => r.humidity,
          minY: 40,
          maxY: 100,
        ),
      ],
    );
  }
}

class _MetricChart extends StatelessWidget {
  final String title;
  final String unit;
  final Color lineColor;
  final double threshold;
  final String thresholdLabel;
  final List<SensorReading> readings;
  final double Function(SensorReading) valueOf;
  final double minY;
  final double maxY;

  const _MetricChart({
    required this.title,
    required this.unit,
    required this.lineColor,
    required this.threshold,
    required this.thresholdLabel,
    required this.readings,
    required this.valueOf,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');
    final spots =
        readings
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), valueOf(e.value)))
            .toList();

    final thresholdSpots = List.generate(
      readings.length,
      (i) => FlSpot(i.toDouble(), threshold),
    );

    final labelInterval = readings.length <= 6 ? 1 : (readings.length ~/ 5);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: lineColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(width: 16, height: 2, color: ChartColors.threshold),
              const SizedBox(width: 4),
              Text(
                thresholdLabel,
                style: const TextStyle(
                  color: ChartColors.threshold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine:
                      (value) => FlLine(
                        color: AppTheme.cardBorder.withValues(alpha: 0.4),
                        strokeWidth: 1,
                      ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (maxY - minY) / 4,
                      getTitlesWidget:
                          (value, meta) => Text(
                            '${value.toInt()}$unit',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: labelInterval.toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= readings.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            timeFormat.format(readings[index].timestamp),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 8,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: AppTheme.cardBorder.withValues(alpha: 0.5),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: readings.length <= 8,
                      getDotPainter:
                          (spot, percent, bar, index) => FlDotCirclePainter(
                            radius: 2,
                            color: lineColor,
                            strokeWidth: 0,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withValues(alpha: 0.12),
                    ),
                  ),
                  LineChartBarData(
                    spots: thresholdSpots,
                    isCurved: false,
                    color: ChartColors.threshold,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    dashArray: [6, 4],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
