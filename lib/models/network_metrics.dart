class NetworkMetrics {
  final double healthScore;
  final double ispLatencyMs;
  final double packetLossPercent;
  final double jitterMs;
  final double dnsResponseTimeMs;
  final int activeDevices;
  final int totalDevices;
  final int activeAgents;
  final int totalAgents;
  final int pendingAlerts;
  final String topConsumerName;
  final double topConsumerMbps;
  final DateTime lastUpdated;

  const NetworkMetrics({
    required this.healthScore,
    required this.ispLatencyMs,
    required this.packetLossPercent,
    required this.jitterMs,
    required this.dnsResponseTimeMs,
    required this.activeDevices,
    required this.totalDevices,
    required this.activeAgents,
    required this.totalAgents,
    required this.pendingAlerts,
    required this.topConsumerName,
    required this.topConsumerMbps,
    required this.lastUpdated,
  });
}

class TimeSeriesPoint {
  final DateTime time;
  final double value;

  const TimeSeriesPoint({required this.time, required this.value});
}

class TopConsumer {
  final String name;
  final String ip;
  final double consumptionMbps;

  const TopConsumer({
    required this.name,
    required this.ip,
    required this.consumptionMbps,
  });
}
