class DeviceConnectionEntity {
  final String dstIp;
  final String? dstHostname;
  final int dstPort;
  final String proto;
  final int totalBytes;
  final int connectionCount;
  final DateTime lastSeen;

  const DeviceConnectionEntity({
    required this.dstIp,
    this.dstHostname,
    required this.dstPort,
    required this.proto,
    required this.totalBytes,
    required this.connectionCount,
    required this.lastSeen,
  });

  String get displayName => dstHostname ?? dstIp;

  String get bytesFormatted {
    if (totalBytes < 1024) {
      return '$totalBytes B';
    } else if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
