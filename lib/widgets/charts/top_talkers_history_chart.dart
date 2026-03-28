import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/network_metrics.dart';

class TopTalkersHistoryChart extends StatelessWidget {
  final List<TopTalkerSnapshot> snapshots;

  const TopTalkersHistoryChart({super.key, required this.snapshots});

  static const _colors = [
    AppColors.chartTeal,
    AppColors.chartBlue,
    AppColors.chartGreen,
    AppColors.chartOrange,
    AppColors.chartPurple,
  ];

  @override
  Widget build(BuildContext context) {
    if (snapshots.isEmpty) return const SizedBox.shrink();

    // Group by deviceId
    final grouped = <int, List<TopTalkerSnapshot>>{};
    for (final s in snapshots) {
      grouped.putIfAbsent(s.deviceId, () => []).add(s);
    }

    // Top 5 devices by max consumption
    final sortedDevices = grouped.entries.toList()
      ..sort((a, b) {
        final maxA = a.value.map((s) => s.consumptionMbps).reduce((x, y) => x > y ? x : y);
        final maxB = b.value.map((s) => s.consumptionMbps).reduce((x, y) => x > y ? x : y);
        return maxB.compareTo(maxA);
      });
    final top5 = sortedDevices.take(5).toList();

    // Collect all unique timestamps sorted
    final allTimestamps = snapshots.map((s) => s.timestamp).toSet().toList()..sort();
    final timeIndex = {for (var i = 0; i < allTimestamps.length; i++) allTimestamps[i]: i};

    // Build line data
    final lineBars = <LineChartBarData>[];
    final legendEntries = <_LegendEntry>[];
    double maxY = 0;

    for (var i = 0; i < top5.length; i++) {
      final entry = top5[i];
      final color = _colors[i % _colors.length];
      final deviceSnapshots = entry.value..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final name = deviceSnapshots.first.hostname;

      final spots = deviceSnapshots.map((s) {
        final x = (timeIndex[s.timestamp] ?? 0).toDouble();
        final y = s.consumptionMbps;
        if (y > maxY) maxY = y;
        return FlSpot(x, y);
      }).toList();

      lineBars.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: color,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ));

      legendEntries.add(_LegendEntry(name: name, color: color));
    }

    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Talkers History',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xFF30363D),
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      'Mbps',
                      style: GoogleFonts.inter(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    axisNameSize: 16,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(1),
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textTertiary,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text(
                      'Time',
                      style: GoogleFonts.inter(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    axisNameSize: 20,
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (allTimestamps.length / 5).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= allTimestamps.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          DateFormat('HH:mm').format(allTimestamps[idx]),
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textTertiary,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxY,
                lineBarsData: lineBars,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceHigh,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final color = spot.bar.color ?? AppColors.textPrimary;
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(2)} Mbps',
                          GoogleFonts.jetBrainsMono(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: legendEntries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 3,
                    decoration: BoxDecoration(
                      color: e.color,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    e.name,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LegendEntry {
  final String name;
  final Color color;

  const _LegendEntry({required this.name, required this.color});
}
