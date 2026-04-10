import '../../core/entities/device_snapshot.dart';
import '../dtos/device_snapshot_dto.dart';

class DeviceSnapshotMapper {
  const DeviceSnapshotMapper._();

  static DeviceSnapshotEntity toEntity(DeviceSnapshotDto dto) {
    return DeviceSnapshotEntity(
      timestamp: dto.timestamp != null
          ? DateTime.parse(dto.timestamp!)
          : DateTime.now(),
      cpuPct: _d(dto.cpuPct),
      ramPct: _d(dto.ramPct),
      bandwidthIn: _d(dto.bandwidthIn),
      bandwidthOut: _d(dto.bandwidthOut),
      tcpRetransmissions: _d(dto.tcpRetransmissions),
      failedConnections: (dto.failedConnections as num?)?.toInt() ?? 0,
    );
  }

  static double _d(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}
