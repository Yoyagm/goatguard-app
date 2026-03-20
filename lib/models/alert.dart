import '../config/helpers.dart';

enum AlertSeverity { critical, warning, info }

class NetworkAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final String? deviceName;
  final String? deviceIp;
  final DateTime timestamp;
  final bool isRead;

  const NetworkAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    this.deviceName,
    this.deviceIp,
    required this.timestamp,
    this.isRead = false,
  });

  /// Factoría desde JSON de la API (GET /alerts)
  /// Mapeo de severidades: critical→critical, high→critical, medium→warning, low→info
  factory NetworkAlert.fromJson(Map<String, dynamic> json) {
    return NetworkAlert(
      id: json['id'].toString(),
      title: _formatTitle(json['anomaly_type'] as String? ?? 'unknown'),
      description: json['description'] as String? ?? '',
      severity: _parseSeverity(json['severity'] as String?),
      deviceName: json['device_hostname'] as String?,
      deviceIp: json['device_ip'] as String?,
      timestamp: json['timestamp'] != null
          ? parseApiTimestamp(json['timestamp'] as String)
          : DateTime.now(),
      isRead: json['seen'] as bool? ?? false,
    );
  }

  static AlertSeverity _parseSeverity(String? raw) {
    switch (raw) {
      case 'critical':
      case 'high':
        return AlertSeverity.critical;
      case 'medium':
        return AlertSeverity.warning;
      default:
        return AlertSeverity.info;
    }
  }

  /// Convierte anomaly_type snake_case a título legible
  static String _formatTitle(String anomalyType) {
    return anomalyType
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
