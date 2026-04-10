class NetworkSnapshotDto {
  final String? timestamp;
  final dynamic ispLatencyAvg;
  final dynamic packetLossPct;
  final dynamic jitter;
  final dynamic activeConnections;
  final dynamic failedConnectionsGlobal;

  const NetworkSnapshotDto({
    this.timestamp,
    this.ispLatencyAvg,
    this.packetLossPct,
    this.jitter,
    this.activeConnections,
    this.failedConnectionsGlobal,
  });

  factory NetworkSnapshotDto.fromJson(Map<String, dynamic> json) =>
      NetworkSnapshotDto(
        timestamp: json['timestamp'] as String?,
        ispLatencyAvg: json['isp_latency_avg'],
        packetLossPct: json['packet_loss_pct'],
        jitter: json['jitter'],
        activeConnections: json['active_connections'],
        failedConnectionsGlobal: json['failed_connections_global'],
      );
}
