class DeviceDto {
  final dynamic id;
  final String? alias;
  final String? hostname;
  final String ip;
  final String mac;
  final String? deviceType;
  final bool? hasAgent;
  final String? status;
  final Map<String, dynamic>? metrics;
  final int? alertCount;
  final String? lastSeen;

  const DeviceDto({
    required this.id,
    this.alias,
    this.hostname,
    required this.ip,
    required this.mac,
    this.deviceType,
    this.hasAgent,
    this.status,
    this.metrics,
    this.alertCount,
    this.lastSeen,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) => DeviceDto(
    id: json['id'],
    alias: json['alias'] as String?,
    hostname: json['hostname'] as String?,
    ip: json['ip'] as String,
    mac: json['mac'] as String,
    deviceType: json['device_type'] as String?,
    hasAgent: json['has_agent'] as bool?,
    status: json['status'] as String?,
    metrics: json['metrics'] as Map<String, dynamic>?,
    alertCount: json['alert_count'] as int?,
    lastSeen: json['last_seen'] as String?,
  );

  /// Factory for WebSocket payloads (flattened structure, no mac/device_type).
  factory DeviceDto.fromWsJson(Map<String, dynamic> json) => DeviceDto(
    id: json['id'],
    hostname: json['hostname'] as String?,
    ip: json['ip'] as String,
    mac: '',
    hasAgent: json['has_agent'] as bool?,
    status: json['status'] as String?,
    metrics: {'cpu_pct': json['cpu_pct'], 'ram_pct': json['ram_pct']},
  );
}
