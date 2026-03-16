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
}
