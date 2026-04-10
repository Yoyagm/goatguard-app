class DeviceSnapshotEntity {
  final DateTime timestamp;
  final double cpuPct;
  final double ramPct;
  final double bandwidthIn;
  final double bandwidthOut;
  final double tcpRetransmissions;
  final int failedConnections;

  const DeviceSnapshotEntity({
    required this.timestamp,
    required this.cpuPct,
    required this.ramPct,
    required this.bandwidthIn,
    required this.bandwidthOut,
    required this.tcpRetransmissions,
    required this.failedConnections,
  });
}
