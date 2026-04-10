import '../../core/entities/agent.dart';
import '../dtos/agent_dto.dart';

class AgentMapper {
  const AgentMapper._();

  /// Maps an AgentDto (from GET /agents/) to the domain entity.
  static AgentEntity toEntity(AgentDto dto) {
    return AgentEntity(
      id: dto.uid?.toString() ?? dto.id.toString(),
      hostname: dto.hostname ?? 'Unknown',
      ipAddress: dto.ip ?? '',
      macAddress: dto.mac ?? '',
      status: dto.status == 'active'
          ? AgentStatus.active
          : AgentStatus.inactive,
      cpuUsage: _d(dto.cpuPct),
      ramUsage: _d(dto.ramPct),
      linkSpeedMbps: _d(dto.linkSpeed),
      lastHeartbeat: dto.lastHeartbeat != null
          ? DateTime.parse('${dto.lastHeartbeat}Z')
          : DateTime.now(),
    );
  }

  static double _d(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}
