class DashboardSummaryEntity {
  final double healthScore;
  final int devicesActive;
  final int devicesTotal;
  final int agentsActive;
  final int agentsTotal;
  final double ispLatencyAvg;
  final double packetLossPct;
  final double jitter;
  final int unseenAlerts;
  final String topConsumerName;
  final double topConsumerBytes;

  const DashboardSummaryEntity({
    required this.healthScore,
    required this.devicesActive,
    required this.devicesTotal,
    required this.agentsActive,
    required this.agentsTotal,
    required this.ispLatencyAvg,
    required this.packetLossPct,
    required this.jitter,
    required this.unseenAlerts,
    required this.topConsumerName,
    required this.topConsumerBytes,
  });
}
