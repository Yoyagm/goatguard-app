class TopConsumerDto {
  final String? alias;
  final String? hostname;
  final String? ip;
  final dynamic totalConsumption;

  const TopConsumerDto({
    this.alias,
    this.hostname,
    this.ip,
    this.totalConsumption,
  });

  /// From GET /network/top-talkers.
  /// `total_consumption` is in bytes; conversion to Mbps is done in the mapper.
  factory TopConsumerDto.fromJson(Map<String, dynamic> json) => TopConsumerDto(
        alias: json['alias'] as String?,
        hostname: json['hostname'] as String?,
        ip: json['ip'] as String?,
        totalConsumption: json['total_consumption'],
      );
}
