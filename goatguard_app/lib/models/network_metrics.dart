class NetworkMetrics {
  final double healthScore;
  final double ispLatencyMs;
  final double packetLossPercent;
  final double jitterMs;
  final double dnsResponseTimeMs;
  final int activeDevices;
  final int totalDevices;
  final int activeAgents;
  final int totalAgents;
  final int pendingAlerts;
  final String topConsumerName;
  final double topConsumerMbps;
  final DateTime lastUpdated;

  const NetworkMetrics({
    required this.healthScore,
    required this.ispLatencyMs,
    required this.packetLossPercent,
    required this.jitterMs,
    required this.dnsResponseTimeMs,
    required this.activeDevices,
    required this.totalDevices,
    required this.activeAgents,
    required this.totalAgents,
    required this.pendingAlerts,
    required this.topConsumerName,
    required this.topConsumerMbps,
    required this.lastUpdated,
  });

  /// Factoría desde GET /network/metrics + datos complementarios
  factory NetworkMetrics.fromApi({
    required Map<String, dynamic> networkJson,
    required int unseenAlerts,
    String topConsumerName = '-',
    double topConsumerMbps = 0,
    int activeAgents = 0,
    int totalAgents = 0,
  }) {
    final latency = _d(networkJson['isp_latency_avg']);
    final loss = _d(networkJson['packet_loss_pct']);
    final jitter = _d(networkJson['jitter']);
    final dns = _d(networkJson['dns_response_time_avg']);

    return NetworkMetrics(
      healthScore: _calcHealthScore(latency, loss, jitter, dns),
      ispLatencyMs: latency,
      packetLossPercent: loss,
      jitterMs: jitter,
      dnsResponseTimeMs: dns,
      activeDevices: networkJson['devices_active'] as int? ?? 0,
      totalDevices: networkJson['total_devices'] as int? ?? 0,
      activeAgents: activeAgents,
      totalAgents: totalAgents,
      pendingAlerts: unseenAlerts,
      topConsumerName: topConsumerName,
      topConsumerMbps: topConsumerMbps,
      lastUpdated: DateTime.now(),
    );
  }

  /// Health score ponderado (0-100) basado en umbrales de constants.dart
  static double _calcHealthScore(
    double latency, double loss, double jitter, double dns,
  ) {
    double score = 100;
    // Penalización por latencia (peso 30%)
    if (latency > 200) {
      score -= 30;
    } else if (latency > 100) {
      score -= 15;
    } else if (latency > 50) {
      score -= 5;
    }
    // Penalización por packet loss (peso 30%)
    if (loss > 5) {
      score -= 30;
    } else if (loss > 1) {
      score -= 15;
    } else if (loss > 0.5) {
      score -= 5;
    }
    // Penalización por jitter (peso 20%)
    if (jitter > 50) {
      score -= 20;
    } else if (jitter > 30) {
      score -= 10;
    } else if (jitter > 10) {
      score -= 3;
    }
    // Penalización por DNS (peso 20%)
    if (dns > 200) {
      score -= 20;
    } else if (dns > 100) {
      score -= 10;
    } else if (dns > 50) {
      score -= 3;
    }
    return score.clamp(0, 100);
  }

  static double _d(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}

class TimeSeriesPoint {
  final DateTime time;
  final double value;

  const TimeSeriesPoint({required this.time, required this.value});
}

class TopConsumer {
  final String name;
  final String ip;
  final double consumptionMbps;

  const TopConsumer({
    required this.name,
    required this.ip,
    required this.consumptionMbps,
  });

  /// Factoría desde GET /network/top-talkers
  /// total_consumption viene en bytes → convertir a Mbps
  factory TopConsumer.fromJson(Map<String, dynamic> json) {
    final bytes = (json['total_consumption'] as num?)?.toDouble() ?? 0;
    return TopConsumer(
      name: (json['alias'] as String?) ??
          (json['hostname'] as String?) ??
          json['ip'] as String? ??
          'Unknown',
      ip: json['ip'] as String? ?? '',
      consumptionMbps: bytes * 8 / 1000000, // bytes → Mbps
    );
  }
}
