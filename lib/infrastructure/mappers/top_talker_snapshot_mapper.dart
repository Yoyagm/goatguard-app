import '../../core/entities/top_talker_snapshot.dart';
import '../dtos/top_talker_snapshot_dto.dart';

class TopTalkerSnapshotMapper {
  const TopTalkerSnapshotMapper._();

  static TopTalkerSnapshotEntity toEntity(TopTalkerSnapshotDto dto) {
    return TopTalkerSnapshotEntity(
      timestamp: dto.timestamp != null
          ? DateTime.parse(dto.timestamp!)
          : DateTime.now(),
      deviceId: (dto.deviceId as num?)?.toInt() ?? 0,
      ip: dto.ip ?? '',
      hostname: dto.alias ?? dto.hostname ?? dto.ip ?? 'Unknown',
      rank: (dto.rank as num?)?.toInt() ?? 0,
      totalConsumption: (dto.totalConsumption as num?)?.toDouble() ?? 0,
      isHog: dto.isHog ?? false,
    );
  }
}
