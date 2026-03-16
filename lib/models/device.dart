import 'package:flutter/material.dart';

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
