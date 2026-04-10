class DeviceSnapshotDto {
  final String? timestamp;
  final dynamic cpuPct;
  final dynamic ramPct;
  final dynamic bandwidthIn;
  final dynamic bandwidthOut;
  final dynamic tcpRetransmissions;
  final dynamic failedConnections;

  const DeviceSnapshotDto({
    this.timestamp,
    this.cpuPct,
    this.ramPct,
    this.bandwidthIn,
    this.bandwidthOut,
    this.tcpRetransmissions,
    this.failedConnections,
  });

  factory DeviceSnapshotDto.fromJson(Map<String, dynamic> json) =>
      DeviceSnapshotDto(
        timestamp: json['timestamp'] as String?,
        cpuPct: json['cpu_pct'],
        ramPct: json['ram_pct'],
        bandwidthIn: json['bandwidth_in'],
        bandwidthOut: json['bandwidth_out'],
        tcpRetransmissions: json['tcp_retransmissions'],
        failedConnections: json['failed_connections'],
      );
}
