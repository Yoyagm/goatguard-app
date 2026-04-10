class NetworkMetricsEntity {
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

  const NetworkMetricsEntity({
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

  NetworkMetricsEntity copyWith({
    double? healthScore,
    double? ispLatencyMs,
    double? packetLossPercent,
    double? jitterMs,
    double? dnsResponseTimeMs,
    int? activeDevices,
    int? totalDevices,
    int? activeAgents,
    int? totalAgents,
    int? pendingAlerts,
    String? topConsumerName,
    double? topConsumerMbps,
    DateTime? lastUpdated,
  }) {
    return NetworkMetricsEntity(
      healthScore: healthScore ?? this.healthScore,
      ispLatencyMs: ispLatencyMs ?? this.ispLatencyMs,
      packetLossPercent: packetLossPercent ?? this.packetLossPercent,
      jitterMs: jitterMs ?? this.jitterMs,
      dnsResponseTimeMs: dnsResponseTimeMs ?? this.dnsResponseTimeMs,
      activeDevices: activeDevices ?? this.activeDevices,
      totalDevices: totalDevices ?? this.totalDevices,
      activeAgents: activeAgents ?? this.activeAgents,
      totalAgents: totalAgents ?? this.totalAgents,
      pendingAlerts: pendingAlerts ?? this.pendingAlerts,
      topConsumerName: topConsumerName ?? this.topConsumerName,
      topConsumerMbps: topConsumerMbps ?? this.topConsumerMbps,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
