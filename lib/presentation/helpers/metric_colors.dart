import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';

/// Metric-to-color helpers extracted from config/helpers.dart.
///
/// These depend on Flutter's Color type, so they belong in
/// the presentation layer rather than config/.

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
