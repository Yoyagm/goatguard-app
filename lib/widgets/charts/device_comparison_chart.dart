import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/network_metrics.dart';

class DeviceComparisonChart extends StatelessWidget {
  final List<DeviceComparison> devices;
  final String metric;
  final ValueChanged<String> onMetricChanged;

  const DeviceComparisonChart({
    super.key,
    required this.devices,
    required this.metric,
    required this.onMetricChanged,
  });

  static const _metrics = [
    'bandwidth_in',
    'bandwidth_out',
    'cpu_pct',
    'ram_pct',
    'tcp_retransmissions',
    'failed_connections',
    'unique_destinations',
    'disk_usage_pct',
  ];

  static const _labels = {
    'bandwidth_in': 'BW In',
    'bandwidth_out': 'BW Out',
    'cpu_pct': 'CPU',
    'ram_pct': 'RAM',
    'tcp_retransmissions': 'TCP Retx',
    'failed_connections': 'Failed Conn',
    'unique_destinations': 'Destinations',
    'disk_usage_pct': 'Disk',
  };

  static const _units = {
    'bandwidth_in': 'Mbps',
    'bandwidth_out': 'Mbps',
    'cpu_pct': '%',
    'ram_pct': '%',
    'tcp_retransmissions': '',
    'failed_connections': '',
    'unique_destinations': '',
    'disk_usage_pct': '%',
  };

  static const _colors = [
    AppColors.chartTeal,
    AppColors.chartBlue,
    AppColors.chartGreen,
    AppColors.chartOrange,
    AppColors.chartPurple,
  ];

  @override
  Widget build(BuildContext context) {
    final maxVal =
        devices.isEmpty ? 1.0 : devices.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final unit = _units[metric] ?? '';

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
            'Device Comparison',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Metric selector
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _metrics.map((m) {
              final selected = m == metric;
              return ChoiceChip(
                label: Text(_labels[m] ?? m),
                selected: selected,
                labelStyle: GoogleFonts.inter(
                  color: selected ? AppColors.base : AppColors.textSecondary,
                  fontSize: 11,
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
                visualDensity: VisualDensity.compact,
                onSelected: (_) => onMetricChanged(m),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (devices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No data available',
                  style: GoogleFonts.inter(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...devices.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              final ratio = maxVal > 0 ? (d.value / maxVal).clamp(0.0, 1.0) : 0.0;
              final color = _colors[i % _colors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            d.label.isNotEmpty ? d.label : d.ip,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${d.value.toStringAsFixed(1)}${unit.isNotEmpty ? ' $unit' : ''}',
                          style: GoogleFonts.jetBrainsMono(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
