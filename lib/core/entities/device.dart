enum DeviceType {
  desktop,
  laptop,
  server,
  phone,
  printer,
  camera,
  iot,
  unknown,
}

enum DeviceCoverage {
  withAgent,
  arpOnly,
}

enum DeviceStatus {
  online,
  offline,
}

class DeviceEntity {
  final String id;
  final String name;
  final String ipAddress;
  final String macAddress;
  final DeviceType type;
  final DeviceCoverage coverage;
  final DeviceStatus status;
  final String? os;
  final double? cpuUsage;
  final double? ramUsage;
  final double? speedMbps;
  final double? latencyMs;
  final double? retransmissionsPerMin;
  final int? failedConnections;
  final int alertCount;
  final DateTime lastSeen;

  const DeviceEntity({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.macAddress,
    required this.type,
    required this.coverage,
    required this.status,
    this.os,
    this.cpuUsage,
    this.ramUsage,
    this.speedMbps,
    this.latencyMs,
    this.retransmissionsPerMin,
    this.failedConnections,
    this.alertCount = 0,
    required this.lastSeen,
  });

  DeviceEntity copyWith({
    String? id,
    String? name,
    String? ipAddress,
    String? macAddress,
    DeviceType? type,
    DeviceCoverage? coverage,
    DeviceStatus? status,
    String? Function()? os,
    double? Function()? cpuUsage,
    double? Function()? ramUsage,
    double? Function()? speedMbps,
    double? Function()? latencyMs,
    double? Function()? retransmissionsPerMin,
    int? Function()? failedConnections,
    int? alertCount,
    DateTime? lastSeen,
  }) {
    return DeviceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
      type: type ?? this.type,
      coverage: coverage ?? this.coverage,
      status: status ?? this.status,
      os: os != null ? os() : this.os,
      cpuUsage: cpuUsage != null ? cpuUsage() : this.cpuUsage,
      ramUsage: ramUsage != null ? ramUsage() : this.ramUsage,
      speedMbps: speedMbps != null ? speedMbps() : this.speedMbps,
      latencyMs: latencyMs != null ? latencyMs() : this.latencyMs,
      retransmissionsPerMin: retransmissionsPerMin != null
          ? retransmissionsPerMin()
          : this.retransmissionsPerMin,
      failedConnections: failedConnections != null
          ? failedConnections()
          : this.failedConnections,
      alertCount: alertCount ?? this.alertCount,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
