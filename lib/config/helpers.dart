import 'package:flutter/material.dart';
import 'constants.dart';
import 'theme.dart';

Color getHealthColor(double score) {
  if (score >= AppConstants.healthGood) return AppColors.healthy;
  if (score >= AppConstants.healthWarning) return AppColors.warning;
  return AppColors.critical;
}

Color getLatencyColor(double ms) {
  if (ms <= AppConstants.latencyGood) return AppColors.healthy;
  if (ms <= AppConstants.latencyWarning) return AppColors.warning;
  return AppColors.critical;
}

Color getPacketLossColor(double percent) {
  if (percent <= AppConstants.packetLossGood) return AppColors.healthy;
  if (percent <= AppConstants.packetLossWarning) return AppColors.warning;
  return AppColors.critical;
}

Color getJitterColor(double ms) {
  if (ms <= AppConstants.jitterGood) return AppColors.healthy;
  if (ms <= AppConstants.jitterWarning) return AppColors.warning;
  return AppColors.critical;
}

Color getDnsColor(double ms) {
  if (ms <= AppConstants.dnsGood) return AppColors.healthy;
  if (ms <= AppConstants.dnsWarning) return AppColors.warning;
  return AppColors.critical;
}

Color getCpuColor(double percent) {
  if (percent < AppConstants.cpuWarning) return AppColors.healthy;
  if (percent < AppConstants.cpuCritical) return AppColors.warning;
  return AppColors.critical;
}

Color getRamColor(double percent) {
  if (percent < AppConstants.ramWarning) return AppColors.healthy;
  if (percent < AppConstants.ramCritical) return AppColors.warning;
  return AppColors.critical;
}

String getStatusLabel(double value, double good, double warning) {
  if (value <= good) return 'Good';
  if (value <= warning) return 'Warning';
  return 'Critical';
}

/// Parsea timestamps del server (siempre UTC, sin sufijo Z)
DateTime parseApiTimestamp(String raw) {
  return DateTime.parse('${raw}Z'); // Fuerza UTC → Dart convierte a local
}

String timeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(
    dateTime.isUtc ? dateTime.toLocal() : dateTime,
  );
  if (diff.isNegative) return 'just now';
  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
