import '../../core/entities/dashboard_summary.dart';
import '../dtos/dashboard_summary_dto.dart';

class DashboardSummaryMapper {
  const DashboardSummaryMapper._();

  static DashboardSummaryEntity toEntity(DashboardSummaryDto dto) {
    return DashboardSummaryEntity(
      healthScore: (dto.healthScore as num?)?.toDouble() ?? 0,
      devicesActive: (dto.devicesActive as num?)?.toInt() ?? 0,
      devicesTotal: (dto.devicesTotal as num?)?.toInt() ?? 0,
      agentsActive: (dto.agentsActive as num?)?.toInt() ?? 0,
      agentsTotal: (dto.agentsTotal as num?)?.toInt() ?? 0,
      ispLatencyAvg: (dto.ispLatencyAvg as num?)?.toDouble() ?? 0,
      packetLossPct: (dto.packetLossPct as num?)?.toDouble() ?? 0,
      jitter: (dto.jitter as num?)?.toDouble() ?? 0,
      unseenAlerts: (dto.unseenAlerts as num?)?.toInt() ?? 0,
      topConsumerName: dto.topConsumerName ?? '-',
      topConsumerBytes: (dto.topConsumerBytes as num?)?.toDouble() ?? 0,
    );
  }
}
