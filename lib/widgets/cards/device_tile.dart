import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../config/helpers.dart';
import '../../models/device.dart';

class DeviceTile extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;

  const DeviceTile({super.key, required this.device, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAgent = device.coverage == DeviceCoverage.withAgent;
    final isOnline = device.status == DeviceStatus.online;
    final statusColor = isOnline ? AppColors.healthy : AppColors.critical;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isAgent
                ? const Color(0xFF30363D)
                : AppColors.neutral.withValues(alpha: 0.3),
            width: isAgent ? 0.5 : 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isAgent
                    ? AppColors.brand.withValues(alpha: 0.12)
                    : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                device.icon,
                color: isAgent ? AppColors.brand : AppColors.neutral,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          device.name,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    device.ipAddress,
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isAgent && device.cpuUsage != null)
                    Row(
                      children: [
                        _miniMetric(
                          'CPU',
                          '${device.cpuUsage!.toInt()}%',
                          getCpuColor(device.cpuUsage!),
                        ),
                        const SizedBox(width: 10),
                        _miniMetric(
                          'RAM',
                          '${device.ramUsage!.toInt()}%',
                          getRamColor(device.ramUsage!),
                        ),
                        if (device.alertCount > 0) ...[
                          const SizedBox(width: 10),
                          _miniMetric(
                            '',
                            '${device.alertCount} alerts',
                            AppColors.warning,
                          ),
                        ],
                      ],
                    )
                  else
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.neutral.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ARP Only',
                            style: GoogleFonts.inter(
                              color: AppColors.neutral,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (device.alertCount > 0) ...[
                          const SizedBox(width: 8),
                          _miniMetric(
                            '',
                            '${device.alertCount} alerts',
                            AppColors.warning,
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMetric(String label, String value, Color color) {
    return Text(
      label.isNotEmpty ? '$label $value' : value,
      style: GoogleFonts.jetBrainsMono(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
