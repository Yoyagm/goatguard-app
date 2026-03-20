import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/alert.dart';
import '../../providers/alert_provider.dart';
import '../../providers/mock_data.dart';
import '../../widgets/cards/alert_tile.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  AlertSeverity? _filter;

  List<NetworkAlert> _applyFilter(List<NetworkAlert> alerts) {
    if (_filter == null) return alerts;
    return alerts.where((a) => a.severity == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final alertProv = context.watch<AlertProvider>();

    // Fallback a MockData si la API aún no responde
    final allAlerts = alertProv.alerts.isNotEmpty
        ? alertProv.alerts
        : MockData.alerts;
    final alerts = _applyFilter(allAlerts);
    final unread = alerts.where((a) => !a.isRead).length;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Text(
                'Alerts',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              if (unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.critical.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$unread new',
                    style: GoogleFonts.inter(
                      color: AppColors.critical,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Filter Chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _filterChip('All', null),
              _filterChip('Critical', AlertSeverity.critical),
              _filterChip('Warning', AlertSeverity.warning),
              _filterChip('Info', AlertSeverity.info),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Alert List
        Expanded(
          child: alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.healthy,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No alerts',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.brand,
                  backgroundColor: AppColors.surface,
                  onRefresh: () => alertProv.fetchAlerts(),
                  child: ListView.builder(
                    itemCount: alerts.length,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return AlertTile(
                        alert: alert,
                        onSeen: alert.isRead
                            ? null
                            : () => alertProv.markAsSeen(alert.id),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, AlertSeverity? severity) {
    final selected = _filter == severity;
    final chipColor = switch (severity) {
      AlertSeverity.critical => AppColors.critical,
      AlertSeverity.warning => AppColors.warning,
      AlertSeverity.info => AppColors.info,
      null => AppColors.brand,
    };

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(label),
        labelStyle: GoogleFonts.inter(
          color: selected ? AppColors.base : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: AppColors.surface,
        selectedColor: chipColor,
        side: BorderSide(
          color: selected ? chipColor : const Color(0xFF30363D),
          width: 0.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        showCheckmark: false,
        onSelected: (_) => setState(() => _filter = selected ? null : severity),
      ),
    );
  }
}
