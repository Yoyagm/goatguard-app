import '../../core/entities/isp_health.dart';
import '../dtos/isp_health_dto.dart';

class IspHealthMapper {
  const IspHealthMapper._();

  static IspHealthDetailEntity toEntity(IspHealthDto dto) {
    return IspHealthDetailEntity(
      latency: _mapMetric(dto.latency),
      packetLoss: _mapMetric(dto.packetLoss),
      jitter: _mapMetric(dto.jitter),
    );
  }

  static IspMetricDetailEntity _mapMetric(IspMetricDetailDto dto) {
    return IspMetricDetailEntity(
      current: _d(dto.current),
      avg1h: _d(dto.avg1h),
      min1h: _d(dto.min1h),
      max1h: _d(dto.max1h),
      status: dto.status ?? 'unknown',
    );
  }

  static double _d(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}
