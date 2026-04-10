/// Compatibility layer — re-exports domain entities as the legacy type names.
/// Screens and chart widgets continue importing `models/network_metrics.dart`
/// until Phase 9 migrates them to import from `core/entities/` directly.
library;

export '../core/entities/network_metrics.dart';
export '../core/entities/top_consumer.dart';
export '../core/entities/network_snapshot.dart';
export '../core/entities/isp_health.dart';
export '../core/entities/traffic_distribution.dart';
export '../core/entities/device_comparison.dart';
export '../core/entities/top_talker_snapshot.dart';
export '../core/entities/dashboard_summary.dart';

import '../core/entities/network_metrics.dart';
import '../core/entities/top_consumer.dart';
import '../core/entities/network_snapshot.dart';
import '../core/entities/isp_health.dart';
import '../core/entities/traffic_distribution.dart';
import '../core/entities/device_comparison.dart';
import '../core/entities/top_talker_snapshot.dart';
import '../core/entities/dashboard_summary.dart';

/// Type aliases for backward compatibility.
typedef NetworkMetrics = NetworkMetricsEntity;
typedef TopConsumer = TopConsumerEntity;
typedef NetworkSnapshot = NetworkSnapshotEntity;
typedef IspHealthDetail = IspHealthDetailEntity;
typedef IspMetricDetail = IspMetricDetailEntity;
typedef TrafficDistribution = TrafficDistributionEntity;
typedef ProtocolTraffic = ProtocolTrafficEntity;
typedef DirectionTraffic = DirectionTrafficEntity;
typedef PortTraffic = PortTrafficEntity;
typedef DeviceComparison = DeviceComparisonEntity;
typedef TopTalkerSnapshot = TopTalkerSnapshotEntity;
typedef DashboardSummary = DashboardSummaryEntity;

/// Presentation-only data class for chart time series.
/// No domain equivalent — purely a UI concern.
class TimeSeriesPoint {
  final DateTime time;
  final double value;

  const TimeSeriesPoint({required this.time, required this.value});
}
