import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/helpers.dart';
import '../../models/device.dart';
import '../../providers/alert_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/mock_data.dart';
import '../../widgets/common/resource_bar.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/charts/line_metric_chart.dart';
import '../../widgets/cards/alert_tile.dart';

class DeviceDetailScreen extends StatelessWidget {
  final Device device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final isAgent = device.coverage == DeviceCoverage.withAgent;

    // Alertas desde provider; filtro client-side porque GET /alerts no soporta device_id
    final alertProv = context.watch<AlertProvider>();
    final allAlerts = alertProv.alerts.isNotEmpty
        ? alertProv.alerts
        : MockData.alerts;
    final alerts = allAlerts
        .where((a) => a.deviceIp == device.ipAddress)
        .toList();

    // TimeSeries: MockData — GET /metrics/device/{id} no implementado aún
    // TODO(RF-17): reemplazar cuando el endpoint exista

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.navBar,
        title: Text(device.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 20),
            onPressed: () => _showAliasDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
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
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isAgent
                            ? AppColors.brand.withValues(alpha: 0.12)
                            : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        device.icon,
                        color: isAgent ? AppColors.brand : AppColors.neutral,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              StatusChip(
                                label: device.status == DeviceStatus.online
                                    ? 'Online'
                                    : 'Offline',
                                color: device.status == DeviceStatus.online
                                    ? AppColors.healthy
                                    : AppColors.critical,
                              ),
                              const SizedBox(width: 6),
                              StatusChip(
                                label: isAgent ? 'With Agent' : 'ARP Only',
                                color: isAgent
                                    ? AppColors.brand
                                    : AppColors.neutral,
                                outlined: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _infoRow('IP Address', device.ipAddress),
                _infoRow('MAC Address', device.macAddress),
                if (device.os != null) _infoRow('OS', device.os!),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Resources (only for agents)
          if (isAgent && device.cpuUsage != null) ...[
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
                  Text(
                    'Resources',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ResourceBar(
                    label: 'CPU',
                    value: device.cpuUsage!,
                    color: getCpuColor(device.cpuUsage!),
                  ),
                  const SizedBox(height: 14),
                  ResourceBar(
                    label: 'RAM',
                    value: device.ramUsage!,
                    color: getRamColor(device.ramUsage!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Network metrics (only for agents)
          if (isAgent) ...[
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
                  Text(
                    'Network',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _networkRow(
                    'Speed',
                    '${device.speedMbps?.toInt() ?? 0} Mbps',
                    AppColors.textPrimary,
                  ),
                  _networkRow(
                    'Latency',
                    '${device.latencyMs?.toInt() ?? 0} ms',
                    device.latencyMs != null
                        ? getLatencyColor(device.latencyMs!)
                        : AppColors.textPrimary,
                  ),
                  _networkRow(
                    'Retransmissions',
                    '${device.retransmissionsPerMin?.toStringAsFixed(1) ?? '0'}/min',
                    device.retransmissionsPerMin != null &&
                            device.retransmissionsPerMin! > 5
                        ? AppColors.critical
                        : AppColors.healthy,
                  ),
                  _networkRow(
                    'Failed Connections',
                    '${device.failedConnections ?? 0}',
                    (device.failedConnections ?? 0) > 0
                        ? AppColors.warning
                        : AppColors.healthy,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // TCP Retransmissions Chart (MockData — sin historial en API)
            LineMetricChart(
              title: 'TCP Retransmissions (1h)',
              data: MockData.generateTimeSeries(
                points: 30,
                baseValue: 5,
                variance: 8,
                withSpike: true,
              ),
              lineColor: AppColors.chartRed,
              unit: 'rt/m',
              warningThreshold: 5,
              criticalThreshold: 15,
            ),
            const SizedBox(height: 12),

            // Speed Chart (MockData — sin historial en API)
            LineMetricChart(
              title: 'Bandwidth Usage (1h)',
              data: MockData.generateTimeSeries(
                points: 30,
                baseValue: 120,
                variance: 60,
              ),
              lineColor: AppColors.chartTeal,
              unit: 'Mbps',
            ),
            const SizedBox(height: 12),
          ],

          // Alerts
          if (alerts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Alerts',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.critical.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${alerts.length}',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.critical,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...alerts.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: AlertTile(alert: a),
              ),
            ),
          ],

          // Empty state for ARP devices
          if (!isAgent)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.neutral.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.neutral,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Limited Data Available',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This device was discovered via ARP scan. Install a GOATGuard agent to get full metrics including CPU, RAM, traffic analysis and alerts.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkRow(
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

  void _showAliasDialog(BuildContext context) {
    final controller = TextEditingController(text: device.name);
    final deviceProv = context.read<DeviceProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Alias',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 64,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Device name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final alias = controller.text.trim();
              if (alias.isEmpty) return;
              Navigator.pop(ctx);
              final ok = await deviceProv.updateAlias(
                int.parse(device.id),
                alias,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surface,
                    content: Text(
                      ok ? 'Alias updated to "$alias"' : 'Error updating alias',
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
