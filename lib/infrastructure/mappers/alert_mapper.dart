import '../../core/entities/alert.dart';
import '../dtos/alert_dto.dart';

class AlertMapper {
  const AlertMapper._();

  static NetworkAlertEntity toEntity(AlertDto dto) {
    return NetworkAlertEntity(
      id: dto.id.toString(),
      title: dto.formattedTitle,
      description: dto.description ?? '',
      severity: _parseSeverity(dto.normalizedSeverity),
      deviceName: dto.deviceHostname,
      deviceIp: dto.deviceIp,
      timestamp: dto.timestamp != null
          ? DateTime.parse('${dto.timestamp}Z')
          : DateTime.now(),
      isRead: dto.seen ?? false,
    );
  }

  static AlertSeverity _parseSeverity(String normalized) {
    switch (normalized) {
      case 'critical':
        return AlertSeverity.critical;
      case 'warning':
        return AlertSeverity.warning;
      default:
        return AlertSeverity.info;
    }
  }
}
