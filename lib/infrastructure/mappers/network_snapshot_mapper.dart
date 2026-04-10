import '../../core/entities/network_snapshot.dart';
import '../dtos/network_snapshot_dto.dart';

class NetworkSnapshotMapper {
  const NetworkSnapshotMapper._();

  static NetworkSnapshotEntity toEntity(NetworkSnapshotDto dto) {
    return NetworkSnapshotEntity(
      timestamp: dto.timestamp != null
          ? DateTime.parse(dto.timestamp!)
          : DateTime.now(),
      ispLatencyAvg: _d(dto.ispLatencyAvg),
      packetLossPct: _d(dto.packetLossPct),
      jitter: _d(dto.jitter),
      activeConnections: (dto.activeConnections as num?)?.toInt() ?? 0,
      failedConnectionsGlobal:
          (dto.failedConnectionsGlobal as num?)?.toInt() ?? 0,
    );
  }

  static double _d(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}
