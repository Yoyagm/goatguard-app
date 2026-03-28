import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/network_metrics.dart';

class IspHealthCard extends StatelessWidget {
  final IspHealthDetail data;

  const IspHealthCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
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
            'ISP Health Detail',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _metricCard('Latency', data.latency, 'ms'),
          const SizedBox(height: 8),
          _metricCard('Packet Loss', data.packetLoss, '%'),
          const SizedBox(height: 8),
          _metricCard('Jitter', data.jitter, 'ms'),
        ],
      ),
    );
  }

  Widget _metricCard(String name, IspMetricDetail metric, String unit) {
    final statusColor = _statusColor(metric.status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  metric.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${metric.current.toStringAsFixed(1)} $unit',
            style: GoogleFonts.jetBrainsMono(
              color: statusColor,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statLabel('Avg', metric.avg1h, unit),
              const SizedBox(width: 16),
              _statLabel('Min', metric.min1h, unit),
              const SizedBox(width: 16),
              _statLabel('Max', metric.max1h, unit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statLabel(String label, double value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'good':
        return AppColors.healthy;
      case 'warning':
        return AppColors.warning;
      case 'critical':
        return AppColors.critical;
      default:
        return AppColors.neutral;
    }
  }
}
