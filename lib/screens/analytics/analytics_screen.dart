import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/helpers.dart';
import '../../models/network_metrics.dart';
import '../../providers/metrics_provider.dart';
import '../../widgets/charts/line_metric_chart.dart';
import '../../widgets/charts/bar_metric_chart.dart';
import '../../widgets/charts/isp_health_card.dart';
import '../../widgets/charts/top_talkers_history_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _timeRange = '1h';
  bool _historyLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  int get _hoursForRange {
    switch (_timeRange) {
      case '1h':
        return 1;
      case '6h':
        return 6;
      case '24h':
        return 24;
      case '7d':
        return 168;
      default:
        return 1;
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    final prov = context.read<MetricsProvider>();
    await Future.wait([
      prov.fetchNetworkHistory(hours: _hoursForRange),
      prov.fetchIspHealth(),

      prov.fetchTopTalkersHistory(hours: _hoursForRange),
    ]);
    if (mounted) setState(() => _historyLoading = false);
  }

  List<TimeSeriesPoint> _toSeries(
    List<NetworkSnapshot> snapshots,
    double Function(NetworkSnapshot) selector,
  ) {
    return snapshots
        .map((s) => TimeSeriesPoint(time: s.timestamp, value: selector(s)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final metricsProv = context.watch<MetricsProvider>();

    final metrics = metricsProv.metrics;
    final consumers = metricsProv.topConsumers;

    final history = metricsProv.networkHistory;
    final hasHistory = history.isNotEmpty;

    final latencySeries = hasHistory
        ? _toSeries(history, (s) => s.ispLatencyAvg)
        : <TimeSeriesPoint>[];
    final lossSeries = hasHistory
        ? _toSeries(history, (s) => s.packetLossPct)
        : <TimeSeriesPoint>[];
    final jitterSeries = hasHistory
        ? _toSeries(history, (s) => s.jitter)
        : <TimeSeriesPoint>[];

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
                onSelected: (_) {
                  setState(() => _timeRange = range);
                  _loadHistory();
                },
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Summary Card
        if (metrics != null)
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
                    const Icon(
                      Icons.analytics_rounded,
                      color: AppColors.brand,
                      size: 20,
                    ),
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
                _summaryRow(
                  'ISP Health',
                  '${metrics.healthScore.toInt()}%',
                  getHealthColor(metrics.healthScore),
                ),
                _summaryRow(
                  'Average Latency',
                  '${metrics.ispLatencyMs.toInt()} ms',
                  getLatencyColor(metrics.ispLatencyMs),
                ),
                _summaryRow(
                  'Packet Loss',
                  '${metrics.packetLossPercent}%',
                  getPacketLossColor(metrics.packetLossPercent),
                ),
                _summaryRow(
                  'Jitter',
                  '${metrics.jitterMs.toInt()} ms',
                  getJitterColor(metrics.jitterMs),
                ),
                _summaryRow(
                  'DNS Response',
                  '${metrics.dnsResponseTimeMs.toInt()} ms',
                  getDnsColor(metrics.dnsResponseTimeMs),
                ),
                _summaryRow(
                  'Top Consumer',
                  metrics.topConsumerName,
                  AppColors.brand,
                  isLast: true,
                ),
              ],
            ),
          ),

        // ISP Health Card
        if (metricsProv.ispHealth != null) ...[
          const SizedBox(height: 14),
          IspHealthCard(data: metricsProv.ispHealth!),
        ],

        const SizedBox(height: 14),

        // Loading indicator for history
        if (_historyLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),

        // ISP Latency Chart
        if (latencySeries.isNotEmpty)
          LineMetricChart(
            title: 'Average ISP Latency',
            data: latencySeries,
            lineColor: AppColors.chartGreen,
            unit: 'ms',
            warningThreshold: 100,
            criticalThreshold: 200,
          ),

        if (latencySeries.isNotEmpty) const SizedBox(height: 14),

        // Packet Loss Chart
        if (lossSeries.isNotEmpty)
          LineMetricChart(
            title: 'Global Packet Loss',
            data: lossSeries,
            lineColor: AppColors.chartRed,
            unit: '%',
            warningThreshold: 1.0,
            criticalThreshold: 5.0,
          ),

        if (lossSeries.isNotEmpty) const SizedBox(height: 14),

        // Jitter Chart
        if (jitterSeries.isNotEmpty)
          LineMetricChart(
            title: 'Jitter',
            data: jitterSeries,
            lineColor: AppColors.chartOrange,
            unit: 'ms',
            warningThreshold: 30,
            criticalThreshold: 50,
          ),

        const SizedBox(height: 14),

        // Top Talkers History
        if (metricsProv.topTalkersHistory.isNotEmpty) ...[
          TopTalkersHistoryChart(snapshots: metricsProv.topTalkersHistory),
          const SizedBox(height: 14),
        ],

        // No history data message
        if (!hasHistory && !_historyLoading)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF30363D), width: 0.5),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.show_chart_rounded,
                  color: AppColors.neutral,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'No historical data yet',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Charts will appear once the server starts collecting metrics.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

        if (!hasHistory && !_historyLoading) const SizedBox(height: 14),

        // Top Consumers (al final)
        if (consumers.isNotEmpty) TopConsumersChart(consumers: consumers),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _summaryRow(
    String label,
    String value,
    Color valueColor, {
    bool isLast = false,
  }) {
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
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
