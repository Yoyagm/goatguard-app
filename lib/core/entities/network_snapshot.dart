class NetworkSnapshotEntity {
  final DateTime timestamp;
  final double ispLatencyAvg;
  final double packetLossPct;
  final double jitter;
  final int activeConnections;
  final int failedConnectionsGlobal;

  const NetworkSnapshotEntity({
    required this.timestamp,
    required this.ispLatencyAvg,
    required this.packetLossPct,
    required this.jitter,
    required this.activeConnections,
    required this.failedConnectionsGlobal,
  });
}
