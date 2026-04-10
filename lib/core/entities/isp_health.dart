class IspMetricDetailEntity {
  final double current;
  final double avg1h;
  final double min1h;
  final double max1h;
  final String status;

  const IspMetricDetailEntity({
    required this.current,
    required this.avg1h,
    required this.min1h,
    required this.max1h,
    required this.status,
  });
}

class IspHealthDetailEntity {
  final IspMetricDetailEntity latency;
  final IspMetricDetailEntity packetLoss;
  final IspMetricDetailEntity jitter;

  const IspHealthDetailEntity({
    required this.latency,
    required this.packetLoss,
    required this.jitter,
  });
}
