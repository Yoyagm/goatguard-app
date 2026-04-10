class TopTalkerSnapshotEntity {
  final DateTime timestamp;
  final int deviceId;
  final String ip;
  final String hostname;
  final int rank;
  final double totalConsumption;
  final bool isHog;

  const TopTalkerSnapshotEntity({
    required this.timestamp,
    required this.deviceId,
    required this.ip,
    required this.hostname,
    required this.rank,
    required this.totalConsumption,
    required this.isHog,
  });

  double get consumptionMbps => totalConsumption * 8 / 1000000;
}
