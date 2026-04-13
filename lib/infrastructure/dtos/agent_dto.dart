class AgentDto {
  final dynamic uid;
  final dynamic id;
  final String? hostname;
  final String? ip;
  final String? mac;
  final String? status;
  final dynamic cpuPct;
  final dynamic ramPct;
  final dynamic linkSpeed;
  final String? lastHeartbeat;

  const AgentDto({
    this.uid,
    this.id,
    this.hostname,
    this.ip,
    this.mac,
    this.status,
    this.cpuPct,
    this.ramPct,
    this.linkSpeed,
    this.lastHeartbeat,
  });

  /// From GET /agents/ (flat agent object with metrics).
  factory AgentDto.fromJson(Map<String, dynamic> json) => AgentDto(
    uid: json['uid'],
    id: json['id'],
    hostname: json['hostname'] as String?,
    ip: json['ip'] as String?,
    status: json['status'] as String?,
    cpuPct: json['cpu_pct'],
    ramPct: json['ram_pct'],
    linkSpeed: json['link_speed_mbps'],
    lastHeartbeat: json['last_heartbeat'] as String?,
  );

  /// From GET /devices/{id} (nested agent + metrics).
  factory AgentDto.fromDeviceJson(Map<String, dynamic> deviceJson) {
    final agentJson = deviceJson['agent'] as Map<String, dynamic>?;
    final metricsJson = deviceJson['metrics'] as Map<String, dynamic>?;
    return AgentDto(
      uid: agentJson?['uid'],
      id: deviceJson['id'],
      hostname: deviceJson['hostname'] as String?,
      ip: deviceJson['ip'] as String?,
      mac: deviceJson['mac'] as String?,
      status: agentJson?['status'] as String?,
      cpuPct: metricsJson?['cpu_pct'],
      ramPct: metricsJson?['ram_pct'],
      linkSpeed: metricsJson?['link_speed'],
      lastHeartbeat: agentJson?['last_heartbeat'] as String?,
    );
  }
}
