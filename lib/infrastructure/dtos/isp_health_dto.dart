class IspMetricDetailDto {
  final dynamic current;
  final dynamic avg1h;
  final dynamic min1h;
  final dynamic max1h;
  final String? status;

  const IspMetricDetailDto({
    this.current,
    this.avg1h,
    this.min1h,
    this.max1h,
    this.status,
  });

  factory IspMetricDetailDto.fromJson(Map<String, dynamic> json) =>
      IspMetricDetailDto(
        current: json['current'],
        avg1h: json['avg_1h'],
        min1h: json['min_1h'],
        max1h: json['max_1h'],
        status: json['status'] as String?,
      );
}

class IspHealthDto {
  final IspMetricDetailDto latency;
  final IspMetricDetailDto packetLoss;
  final IspMetricDetailDto jitter;

  const IspHealthDto({
    required this.latency,
    required this.packetLoss,
    required this.jitter,
  });

  factory IspHealthDto.fromJson(Map<String, dynamic> json) => IspHealthDto(
        latency: IspMetricDetailDto.fromJson(
          json['latency'] as Map<String, dynamic>? ?? {},
        ),
        packetLoss: IspMetricDetailDto.fromJson(
          json['packet_loss'] as Map<String, dynamic>? ?? {},
        ),
        jitter: IspMetricDetailDto.fromJson(
          json['jitter'] as Map<String, dynamic>? ?? {},
        ),
      );
}
