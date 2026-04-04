import 'package:flutter/material.dart';
import '../config/helpers.dart';

enum DeviceType { desktop, laptop, server, phone, printer, camera, iot, unknown }

enum DeviceCoverage { withAgent, arpOnly }

enum DeviceStatus { online, offline }

class Device {
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

  const Device({
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

  /// Factoría desde JSON de la API (GET /devices, GET /devices/{id})
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'].toString(),
      name: (json['alias'] as String?) ??
          (json['hostname'] as String?) ??
          'Unknown',
      ipAddress: json['ip'] as String,
      macAddress: json['mac'] as String,
      type: _parseDeviceType(json['device_type'] as String?),
      coverage: (json['has_agent'] as bool? ?? false)
          ? DeviceCoverage.withAgent
          : DeviceCoverage.arpOnly,
      status: (json['status'] as String?) == 'active'
          ? DeviceStatus.online
          : DeviceStatus.offline,
      os: null, // El server no recolecta OS
      cpuUsage: _toDouble(json['metrics']?['cpu_pct']),
      ramUsage: _toDouble(json['metrics']?['ram_pct']),
      speedMbps: _toDouble(json['metrics']?['link_speed']),
      latencyMs: _toDouble(json['metrics']?['dns_response_time']),
      retransmissionsPerMin: _toDouble(json['metrics']?['tcp_retransmissions']),
      failedConnections: json['metrics']?['failed_connections'] as int?,
      alertCount: json['alert_count'] as int? ?? 0,
      lastSeen: json['last_seen'] != null
          ? parseApiTimestamp(json['last_seen'] as String)
          : DateTime.now(),
    );
  }

  /// Factoría rápida desde payload del WebSocket (campos reducidos)
  factory Device.fromWsJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'].toString(),
      name: (json['hostname'] as String?) ?? 'Unknown',
      ipAddress: json['ip'] as String,
      macAddress: '',
      type: DeviceType.unknown,
      coverage: (json['has_agent'] as bool? ?? false)
          ? DeviceCoverage.withAgent
          : DeviceCoverage.arpOnly,
      status: (json['status'] as String?) == 'active'
          ? DeviceStatus.online
          : DeviceStatus.offline,
      cpuUsage: _toDouble(json['cpu_pct']),
      ramUsage: _toDouble(json['ram_pct']),
      speedMbps: null,
      lastSeen: DateTime.now(),
    );
  }

  static DeviceType _parseDeviceType(String? raw) {
    if (raw == null) return DeviceType.unknown;
    return DeviceType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => DeviceType.unknown,
    );
  }

  static double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }

  IconData get icon {
    switch (type) {
      case DeviceType.desktop:
        return Icons.desktop_windows_rounded;
      case DeviceType.laptop:
        return Icons.laptop_mac_rounded;
      case DeviceType.server:
        return Icons.dns_rounded;
      case DeviceType.phone:
        return Icons.phone_android_rounded;
      case DeviceType.printer:
        return Icons.print_rounded;
      case DeviceType.camera:
        return Icons.videocam_rounded;
      case DeviceType.iot:
        return Icons.sensors_rounded;
      case DeviceType.unknown:
        return Icons.device_unknown_rounded;
    }
  }
}
