class DeviceConnectionDto {
  final String? dstIp;
  final String? dstHostname;
  final dynamic dstPort;
  final String? proto;
  final dynamic totalBytes;
  final dynamic connectionCount;
  final String? lastSeen;

  const DeviceConnectionDto({
    this.dstIp,
    this.dstHostname,
    this.dstPort,
    this.proto,
    this.totalBytes,
    this.connectionCount,
    this.lastSeen,
  });

  factory DeviceConnectionDto.fromJson(Map<String, dynamic> json) =>
      DeviceConnectionDto(
        dstIp: json['dst_ip'] as String?,
        dstHostname: json['dst_hostname'] as String?,
        dstPort: json['dst_port'],
        proto: json['proto'] as String?,
        totalBytes: json['total_bytes'],
        connectionCount: json['connection_count'],
        lastSeen: json['last_seen'] as String?,
      );
}
