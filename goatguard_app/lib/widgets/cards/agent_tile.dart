import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../config/helpers.dart';
import '../../models/agent.dart';

class AgentTile extends StatelessWidget {
  final Agent agent;

  const AgentTile({super.key, required this.agent});

  @override
  Widget build(BuildContext context) {
    final isActive = agent.status == AgentStatus.active;
    final statusColor = isActive ? AppColors.healthy : AppColors.critical;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: const Color(0xFF30363D).withValues(alpha: 0.5), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              agent.hostname,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isActive) ...[
            Text(
              'CPU ${agent.cpuUsage.toInt()}%',
              style: GoogleFonts.jetBrainsMono(
                color: getCpuColor(agent.cpuUsage),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'RAM ${agent.ramUsage.toInt()}%',
              style: GoogleFonts.jetBrainsMono(
                color: getRamColor(agent.ramUsage),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else
            Text(
              'Last: ${timeAgo(agent.lastHeartbeat)}',
              style: GoogleFonts.inter(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
