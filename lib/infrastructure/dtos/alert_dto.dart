class AlertDto {
  final dynamic id;
  final String anomalyType;
  final String? description;
  final String? severity;
  final String? deviceHostname;
  final String? deviceIp;
  final String? timestamp;
  final bool? seen;

  const AlertDto({
    required this.id,
    required this.anomalyType,
    this.description,
    this.severity,
    this.deviceHostname,
    this.deviceIp,
    this.timestamp,
    this.seen,
  });

  factory AlertDto.fromJson(Map<String, dynamic> json) => AlertDto(
    id: json['id'],
    anomalyType: json['anomaly_type'] as String? ?? 'unknown',
    description: json['description'] as String?,
    severity: json['severity'] as String?,
    deviceHostname: json['device_hostname'] as String?,
    deviceIp: json['device_ip'] as String?,
    timestamp: json['timestamp'] as String?,
    seen: json['seen'] as bool?,
  );

  /// Converts anomaly_type snake_case to Title Case.
  /// Example: `high_cpu_usage` -> `High Cpu Usage`
  String get formattedTitle => anomalyType
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  /// Maps severity string to a normalized value.
  /// critical/high -> critical, medium -> warning, else -> info
  String get normalizedSeverity {
    switch (severity) {
      case 'critical':
      case 'high':
        return 'critical';
      case 'medium':
        return 'warning';
      default:
        return 'info';
    }
  }
}
