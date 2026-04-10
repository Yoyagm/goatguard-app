enum AlertSeverity {
  critical,
  warning,
  info,
}

class NetworkAlertEntity {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final String? deviceName;
  final String? deviceIp;
  final DateTime timestamp;
  final bool isRead;

  const NetworkAlertEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    this.deviceName,
    this.deviceIp,
    required this.timestamp,
    this.isRead = false,
  });

  NetworkAlertEntity copyWith({
    String? id,
    String? title,
    String? description,
    AlertSeverity? severity,
    String? Function()? deviceName,
    String? Function()? deviceIp,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NetworkAlertEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      deviceName: deviceName != null ? deviceName() : this.deviceName,
      deviceIp: deviceIp != null ? deviceIp() : this.deviceIp,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Converts a snake_case anomaly type to Title Case.
  ///
  /// Example: `high_cpu_usage` -> `High Cpu Usage`
  static String formatTitle(String anomalyType) {
    return anomalyType
        .split('_')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }
}
