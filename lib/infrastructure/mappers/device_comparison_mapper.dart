import '../../core/entities/device_comparison.dart';
import '../dtos/device_comparison_dto.dart';

class DeviceComparisonMapper {
  const DeviceComparisonMapper._();

  static DeviceComparisonEntity toEntity(DeviceComparisonDto dto) {
    return DeviceComparisonEntity(
      deviceId: (dto.deviceId as num?)?.toInt() ?? 0,
      label: dto.label ?? '',
      ip: dto.ip ?? '',
      value: (dto.value as num?)?.toDouble() ?? 0,
    );
  }
}
