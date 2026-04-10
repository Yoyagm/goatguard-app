import '../../core/entities/device.dart';
import '../dtos/device_dto.dart';

class DeviceMapper {
  const DeviceMapper._();

  static DeviceEntity toEntity(DeviceDto dto) {
    return DeviceEntity(
      id: dto.id.toString(),
      name: dto.alias ?? dto.hostname ?? 'Unknown',
      ipAddress: dto.ip,
      macAddress: dto.mac,
      type: _parseDeviceType(dto.deviceType),
      coverage: (dto.hasAgent ?? false)
          ? DeviceCoverage.withAgent
          : DeviceCoverage.arpOnly,
      status: dto.status == 'active'
          ? DeviceStatus.online
          : DeviceStatus.offline,
      os: null,
      cpuUsage: _toDouble(dto.metrics?['cpu_pct']),
      ramUsage: _toDouble(dto.metrics?['ram_pct']),
      speedMbps: _toDouble(dto.metrics?['link_speed']),
      latencyMs: _toDouble(dto.metrics?['dns_response_time']),
      retransmissionsPerMin: _toDouble(dto.metrics?['tcp_retransmissions']),
      failedConnections: dto.metrics?['failed_connections'] as int?,
      alertCount: dto.alertCount ?? 0,
      lastSeen: dto.lastSeen != null
          ? DateTime.parse('${dto.lastSeen}Z')
          : DateTime.now(),
    );
  }

  /// Maps a WebSocket DTO (flattened, minimal fields).
  static DeviceEntity toEntityFromWs(DeviceDto dto) {
    return DeviceEntity(
      id: dto.id.toString(),
      name: dto.hostname ?? 'Unknown',
      ipAddress: dto.ip,
      macAddress: '',
      type: DeviceType.unknown,
      coverage: (dto.hasAgent ?? false)
          ? DeviceCoverage.withAgent
          : DeviceCoverage.arpOnly,
      status: dto.status == 'active'
          ? DeviceStatus.online
          : DeviceStatus.offline,
      cpuUsage: _toDouble(dto.metrics?['cpu_pct']),
      ramUsage: _toDouble(dto.metrics?['ram_pct']),
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
}
