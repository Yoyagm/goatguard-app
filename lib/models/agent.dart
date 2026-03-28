import '../config/helpers.dart';

enum AgentStatus { active, inactive }

class Agent {
  final String id;
  final String hostname;
  final String ipAddress;
  final String macAddress;
  final AgentStatus status;
  final double cpuUsage;
  final double ramUsage;
  final double linkSpeedMbps;
  final DateTime lastHeartbeat;

  const Agent({
    required this.id,
    required this.hostname,
    required this.ipAddress,
    required this.macAddress,
    required this.status,
    required this.cpuUsage,
    required this.ramUsage,
    required this.linkSpeedMbps,
    required this.lastHeartbeat,
  });

  /// Factoría desde GET /agents/ [RF-037]
  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['uid']?.toString() ?? json['id'].toString(),
      hostname: (json['hostname'] as String?) ?? 'Unknown',
      ipAddress: json['ip'] as String? ?? '',
      macAddress: '',
      status: (json['status'] as String?) == 'active'
          ? AgentStatus.active
          : AgentStatus.inactive,
      cpuUsage: 0,
      ramUsage: 0,
      linkSpeedMbps: 0,
      lastHeartbeat: json['last_heartbeat'] != null
          ? parseApiTimestamp(json['last_heartbeat'] as String)
          : DateTime.now(),
    );
  }

  /// Factoría legacy desde GET /devices/{id} — mantener para compatibilidad
  factory Agent.fromDeviceJson(Map<String, dynamic> deviceJson) {
    final agentJson = deviceJson['agent'] as Map<String, dynamic>?;
    final metricsJson = deviceJson['metrics'] as Map<String, dynamic>?;
    return Agent(
      id: agentJson?['uid']?.toString() ?? deviceJson['id'].toString(),
      hostname: (deviceJson['hostname'] as String?) ?? 'Unknown',
      ipAddress: deviceJson['ip'] as String? ?? '',
      macAddress: deviceJson['mac'] as String? ?? '',
      status: (agentJson?['status'] as String?) == 'active'
          ? AgentStatus.active
          : AgentStatus.inactive,
      cpuUsage: _d(metricsJson?['cpu_pct']),
      ramUsage: _d(metricsJson?['ram_pct']),
      linkSpeedMbps: _d(metricsJson?['link_speed']),
      lastHeartbeat: agentJson?['last_heartbeat'] != null
          ? parseApiTimestamp(agentJson!['last_heartbeat'] as String)
          : DateTime.now(),
    );
  }

  static double _d(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}
