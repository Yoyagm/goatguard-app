import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../config/helpers.dart';
import '../../models/alert.dart';

class AlertTile extends StatefulWidget {
  final NetworkAlert alert;

  const AlertTile({super.key, required this.alert});

  @override
  State<AlertTile> createState() => _AlertTileState();
}

class _AlertTileState extends State<AlertTile> {
  bool _expanded = false;

  Color get _severityColor {
    switch (widget.alert.severity) {
      case AlertSeverity.critical:
        return AppColors.critical;
      case AlertSeverity.warning:
        return AppColors.warning;
      case AlertSeverity.info:
        return AppColors.info;
    }
  }

  IconData get _severityIcon {
    switch (widget.alert.severity) {
      case AlertSeverity.critical:
        return Icons.error_rounded;
      case AlertSeverity.warning:
        return Icons.warning_rounded;
      case AlertSeverity.info:
        return Icons.info_rounded;
    }
  }

  String get _severityLabel {
    switch (widget.alert.severity) {
      case AlertSeverity.critical:
        return 'CRITICAL';
      case AlertSeverity.warning:
        return 'WARNING';
      case AlertSeverity.info:
        return 'INFO';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.alert.isRead
                ? const Color(0xFF30363D)
                : _severityColor.withValues(alpha: 0.3),
            width: widget.alert.isRead ? 0.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _severityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_severityIcon, color: _severityColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _severityColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _severityLabel,
                                style: GoogleFonts.inter(
                                  color: _severityColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              timeAgo(widget.alert.timestamp),
                              style: GoogleFonts.inter(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.alert.title,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.alert.deviceName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${widget.alert.deviceName} - ${widget.alert.deviceIp}',
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
            if (_expanded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(62, 0, 14, 14),
                child: Text(
                  widget.alert.description,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
