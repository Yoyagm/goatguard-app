import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../config/helpers.dart';
import '../../providers/mock_data.dart';
import '../../widgets/common/health_bar.dart';
import '../../widgets/common/metric_card.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/cards/agent_tile.dart';
import '../../widgets/charts/bar_metric_chart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = MockData.networkMetrics;
    final agents = MockData.agents;
    final consumers = MockData.topConsumers;
    final activeAgents = agents.where((a) => a.status.name == 'active').length;
    final inactiveAgents = agents.length - activeAgents;

    return RefreshIndicator(
      color: AppColors.brand,
      backgroundColor: AppColors.surface,
      onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Network Health Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: HealthBar(score: metrics.healthScore),
          ),

          // Metric Cards Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                MetricCard(
                  label: 'ISP Latency',
                  value: metrics.ispLatencyMs.toInt().toString(),
                  unit: 'ms',
                  statusColor: getLatencyColor(metrics.ispLatencyMs),
                  statusLabel: getStatusLabel(
                      metrics.ispLatencyMs, 50, 100),
                  icon: Icons.speed_rounded,
                ),
                MetricCard(
                  label: 'Packet Loss',
                  value: metrics.packetLossPercent.toStringAsFixed(1),
                  unit: '%',
                  statusColor: getPacketLossColor(metrics.packetLossPercent),
                  statusLabel: getStatusLabel(
                      metrics.packetLossPercent, 0.5, 1.0),
                  icon: Icons.wifi_off_rounded,
                ),
                MetricCard(
                  label: 'Jitter',
                  value: metrics.jitterMs.toInt().toString(),
                  unit: 'ms',
                  statusColor: getJitterColor(metrics.jitterMs),
                  statusLabel: getStatusLabel(metrics.jitterMs, 10, 30),
                  icon: Icons.signal_cellular_alt_rounded,
                ),
                MetricCard(
                  label: 'DNS Response',
                  value: metrics.dnsResponseTimeMs.toInt().toString(),
                  unit: 'ms',
                  statusColor: getDnsColor(metrics.dnsResponseTimeMs),
                  statusLabel: getStatusLabel(
                      metrics.dnsResponseTimeMs, 50, 100),
                  icon: Icons.dns_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Agents Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Agents',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    StatusChip(
                      label: '$activeAgents active',
                      color: AppColors.healthy,
                    ),
                    const SizedBox(width: 6),
                    if (inactiveAgents > 0)
                      StatusChip(
                        label: '$inactiveAgents down',
                        color: AppColors.critical,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF30363D), width: 0.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: agents.map((a) => AgentTile(agent: a)).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Top Consumers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TopConsumersChart(consumers: consumers),
          ),

          const SizedBox(height: 8),

          // Last updated
          Center(
            child: Text(
              'Updated ${timeAgo(metrics.lastUpdated)}',
              style: GoogleFonts.inter(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
