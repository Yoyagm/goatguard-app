import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/helpers.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/mock_data.dart';
import '../../widgets/charts/line_metric_chart.dart';
import '../../widgets/charts/bar_metric_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _timeRange = '1h';

  @override
  Widget build(BuildContext context) {
    final metricsProv = context.watch<MetricsProvider>();

    // Métricas actuales desde API; fallback a MockData
    final metrics = metricsProv.metrics ?? MockData.networkMetrics;
    final consumers = metricsProv.topConsumers.isNotEmpty
        ? metricsProv.topConsumers
        : MockData.topConsumers;

    // TimeSeries: MockData como fallback — GET /metrics/history no implementado aún
    // TODO(RF-17): reemplazar cuando el endpoint exista
    final latencySeries = MockData.generateTimeSeries(
      points: 30, baseValue: 35, variance: 20,
    );
    final lossSeries = MockData.generateTimeSeries(
      points: 30, baseValue: 0.3, variance: 0.5,
    );
    final jitterSeries = MockData.generateTimeSeries(
      points: 30, baseValue: 6, variance: 8, withSpike: true,
    );
    final dnsSeries = MockData.generateTimeSeries(
      points: 30, baseValue: 40, variance: 25,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Time Range Selector
        Row(
          children: ['1h', '6h', '24h', '7d'].map((range) {
            final selected = _timeRange == range;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(range),
                selected: selected,
                labelStyle: GoogleFonts.inter(
                  color: selected ? AppColors.base : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.brand,
                side: BorderSide(
                  color: selected ? AppColors.brand : const Color(0xFF30363D),
                  width: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                showCheckmark: false,
                onSelected: (_) => setState(() => _timeRange = range),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF30363D), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_rounded,
                      color: AppColors.brand, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Network Summary',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _summaryRow('ISP Health', '${metrics.healthScore.toInt()}%',
                  getHealthColor(metrics.healthScore)),
              _summaryRow('Average Latency', '${metrics.ispLatencyMs.toInt()} ms',
                  getLatencyColor(metrics.ispLatencyMs)),
              _summaryRow(
                  'Packet Loss',
                  '${metrics.packetLossPercent}%',
                  getPacketLossColor(metrics.packetLossPercent)),
              _summaryRow('Jitter', '${metrics.jitterMs.toInt()} ms',
                  getJitterColor(metrics.jitterMs)),
              _summaryRow('DNS Response', '${metrics.dnsResponseTimeMs.toInt()} ms',
                  getDnsColor(metrics.dnsResponseTimeMs)),
              _summaryRow('Top Consumer', metrics.topConsumerName,
                  AppColors.brand, isLast: true),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ISP Latency Chart
        LineMetricChart(
          title: 'Average ISP Latency',
          data: latencySeries,
          lineColor: AppColors.chartGreen,
          unit: 'ms',
          warningThreshold: 100,
          criticalThreshold: 200,
        ),

        const SizedBox(height: 14),

        // Packet Loss Chart
        LineMetricChart(
          title: 'Global Packet Loss',
          data: lossSeries,
          lineColor: AppColors.chartRed,
          unit: '%',
          warningThreshold: 1.0,
          criticalThreshold: 5.0,
        ),

        const SizedBox(height: 14),

        // Jitter Chart
        LineMetricChart(
          title: 'Jitter',
          data: jitterSeries,
          lineColor: AppColors.chartOrange,
          unit: 'ms',
          warningThreshold: 30,
          criticalThreshold: 50,
        ),

        const SizedBox(height: 14),

        // DNS Response Time
        LineMetricChart(
          title: 'DNS Response Time',
          data: dnsSeries,
          lineColor: AppColors.chartBlue,
          unit: 'ms',
          warningThreshold: 100,
          criticalThreshold: 200,
        ),

        const SizedBox(height: 14),

        // Top Consumers
        TopConsumersChart(consumers: consumers),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
