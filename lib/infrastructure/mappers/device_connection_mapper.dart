import '../../core/entities/device_connection.dart';
import '../dtos/device_connection_dto.dart';

class DeviceConnectionMapper {
  const DeviceConnectionMapper._();

  static DeviceConnectionEntity toEntity(DeviceConnectionDto dto) {
    return DeviceConnectionEntity(
      dstIp: dto.dstIp ?? '',
      dstHostname: dto.dstHostname,
      dstPort: (dto.dstPort as num?)?.toInt() ?? 0,
      proto: dto.proto ?? 'tcp',
      totalBytes: (dto.totalBytes as num?)?.toInt() ?? 0,
      connectionCount: (dto.connectionCount as num?)?.toInt() ?? 0,
      lastSeen: dto.lastSeen != null
          ? DateTime.parse(dto.lastSeen!)
          : DateTime.now(),
    );
  }
}
