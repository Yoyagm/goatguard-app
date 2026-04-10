class DashboardSummaryDto {
  final dynamic healthScore;
  final dynamic devicesActive;
  final dynamic devicesTotal;
  final dynamic agentsActive;
  final dynamic agentsTotal;
  final dynamic ispLatencyAvg;
  final dynamic packetLossPct;
  final dynamic jitter;
  final dynamic unseenAlerts;
  final String? topConsumerName;
  final dynamic topConsumerBytes;

  const DashboardSummaryDto({
    this.healthScore,
    this.devicesActive,
    this.devicesTotal,
    this.agentsActive,
    this.agentsTotal,
    this.ispLatencyAvg,
    this.packetLossPct,
    this.jitter,
    this.unseenAlerts,
    this.topConsumerName,
    this.topConsumerBytes,
  });

  factory DashboardSummaryDto.fromJson(Map<String, dynamic> json) =>
      DashboardSummaryDto(
        healthScore: json['health_score'],
        devicesActive: json['devices_active'],
        devicesTotal: json['devices_total'],
        agentsActive: json['agents_active'],
        agentsTotal: json['agents_total'],
        ispLatencyAvg: json['isp_latency_avg'],
        packetLossPct: json['packet_loss_pct'],
        jitter: json['jitter'],
        unseenAlerts: json['unseen_alerts'],
        topConsumerName: json['top_consumer_name'] as String?,
        topConsumerBytes: json['top_consumer_bytes'],
      );
}
