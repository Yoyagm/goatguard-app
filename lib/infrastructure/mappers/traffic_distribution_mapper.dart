import '../../core/entities/traffic_distribution.dart';
import '../dtos/traffic_distribution_dto.dart';

class TrafficDistributionMapper {
  const TrafficDistributionMapper._();

  static TrafficDistributionEntity toEntity(TrafficDistributionDto dto) {
    return TrafficDistributionEntity(
      byProtocol: dto.byProtocol.map(_mapProtocol).toList(),
      byDirection: _mapDirection(dto.byDirection),
      byPort: dto.byPort.map(_mapPort).toList(),
    );
  }

  static ProtocolTrafficEntity _mapProtocol(ProtocolTrafficDto dto) {
    return ProtocolTrafficEntity(
      protocol: dto.protocol ?? '',
      bytes: (dto.bytes as num?)?.toInt() ?? 0,
      percentage: (dto.percentage as num?)?.toDouble() ?? 0,
    );
  }

  static DirectionTrafficEntity _mapDirection(DirectionTrafficDto dto) {
    return DirectionTrafficEntity(
      internal: (dto.internal as num?)?.toInt() ?? 0,
      external: (dto.external as num?)?.toInt() ?? 0,
      internalPct: (dto.internalPct as num?)?.toDouble() ?? 0,
      externalPct: (dto.externalPct as num?)?.toDouble() ?? 0,
    );
  }

  static PortTrafficEntity _mapPort(PortTrafficDto dto) {
    return PortTrafficEntity(
      port: (dto.port as num?)?.toInt() ?? 0,
      service: dto.service ?? '',
      bytes: (dto.bytes as num?)?.toInt() ?? 0,
      percentage: (dto.percentage as num?)?.toDouble() ?? 0,
    );
  }
}
