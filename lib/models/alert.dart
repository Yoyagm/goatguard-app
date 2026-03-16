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
}
