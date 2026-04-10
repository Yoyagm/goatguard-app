class TopTalkerSnapshotDto {
  final String? timestamp;
  final dynamic deviceId;
  final String? ip;
  final String? alias;
  final String? hostname;
  final dynamic rank;
  final dynamic totalConsumption;
  final bool? isHog;

  const TopTalkerSnapshotDto({
    this.timestamp,
    this.deviceId,
    this.ip,
    this.alias,
    this.hostname,
    this.rank,
    this.totalConsumption,
    this.isHog,
  });

  factory TopTalkerSnapshotDto.fromJson(Map<String, dynamic> json) =>
      TopTalkerSnapshotDto(
        timestamp: json['timestamp'] as String?,
        deviceId: json['device_id'],
        ip: json['ip'] as String?,
        alias: json['alias'] as String?,
        hostname: json['hostname'] as String?,
        rank: json['rank'],
        totalConsumption: json['total_consumption'],
        isHog: json['is_hog'] as bool?,
      );
}
