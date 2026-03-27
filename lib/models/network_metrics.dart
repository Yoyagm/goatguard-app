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

// ─── Network History ────────────────────────────────────

class NetworkSnapshot {
  final DateTime timestamp;
  final double ispLatencyAvg;
  final double packetLossPct;
  final double jitter;
  final int activeConnections;
  final int failedConnectionsGlobal;

  const NetworkSnapshot({
    required this.timestamp,
    required this.ispLatencyAvg,
    required this.packetLossPct,
    required this.jitter,
    required this.activeConnections,
    required this.failedConnectionsGlobal,
  });

  factory NetworkSnapshot.fromJson(Map<String, dynamic> json) {
    return NetworkSnapshot(
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      ispLatencyAvg: _d(json['isp_latency_avg']),
      packetLossPct: _d(json['packet_loss_pct']),
      jitter: _d(json['jitter']),
      activeConnections: (json['active_connections'] as num?)?.toInt() ?? 0,
      failedConnectionsGlobal:
          (json['failed_connections_global'] as num?)?.toInt() ?? 0,
    );
  }

  static double _d(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}

// ─── ISP Health Detail ──────────────────────────────────

class IspMetricDetail {
  final double current;
  final double avg1h;
  final double min1h;
  final double max1h;
  final String status;

  const IspMetricDetail({
    required this.current,
    required this.avg1h,
    required this.min1h,
    required this.max1h,
    required this.status,
  });

  factory IspMetricDetail.fromJson(Map<String, dynamic> json) {
    return IspMetricDetail(
      current: _d(json['current']),
      avg1h: _d(json['avg_1h']),
      min1h: _d(json['min_1h']),
      max1h: _d(json['max_1h']),
      status: json['status'] as String? ?? 'unknown',
    );
  }

  static double _d(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}

class IspHealthDetail {
  final IspMetricDetail latency;
  final IspMetricDetail packetLoss;
  final IspMetricDetail jitter;

  const IspHealthDetail({
    required this.latency,
    required this.packetLoss,
    required this.jitter,
  });

  factory IspHealthDetail.fromJson(Map<String, dynamic> json) {
    return IspHealthDetail(
      latency: IspMetricDetail.fromJson(
          json['latency'] as Map<String, dynamic>? ?? {}),
      packetLoss: IspMetricDetail.fromJson(
          json['packet_loss'] as Map<String, dynamic>? ?? {}),
      jitter: IspMetricDetail.fromJson(
          json['jitter'] as Map<String, dynamic>? ?? {}),
    );
  }
}

// ─── Traffic Distribution ───────────────────────────────

class ProtocolTraffic {
  final String protocol;
  final int bytes;
  final double percentage;

  const ProtocolTraffic({
    required this.protocol,
    required this.bytes,
    required this.percentage,
  });

  factory ProtocolTraffic.fromJson(Map<String, dynamic> json) {
    return ProtocolTraffic(
      protocol: json['protocol'] as String? ?? '',
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DirectionTraffic {
  final int internal;
  final int external;
  final double internalPct;
  final double externalPct;

  const DirectionTraffic({
    required this.internal,
    required this.external,
    required this.internalPct,
    required this.externalPct,
  });

  factory DirectionTraffic.fromJson(Map<String, dynamic> json) {
    return DirectionTraffic(
      internal: (json['internal'] as num?)?.toInt() ?? 0,
      external: (json['external'] as num?)?.toInt() ?? 0,
      internalPct: (json['internal_pct'] as num?)?.toDouble() ?? 0,
      externalPct: (json['external_pct'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PortTraffic {
  final int port;
  final String service;
  final int bytes;
  final double percentage;

  const PortTraffic({
    required this.port,
    required this.service,
    required this.bytes,
    required this.percentage,
  });

  factory PortTraffic.fromJson(Map<String, dynamic> json) {
    return PortTraffic(
      port: (json['port'] as num?)?.toInt() ?? 0,
      service: json['service'] as String? ?? '',
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TrafficDistribution {
  final List<ProtocolTraffic> byProtocol;
  final DirectionTraffic byDirection;
  final List<PortTraffic> byPort;

  const TrafficDistribution({
    required this.byProtocol,
    required this.byDirection,
    required this.byPort,
  });

  factory TrafficDistribution.fromJson(Map<String, dynamic> json) {
    return TrafficDistribution(
      byProtocol: (json['by_protocol'] as List<dynamic>?)
              ?.map((e) =>
                  ProtocolTraffic.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      byDirection: DirectionTraffic.fromJson(
          json['by_direction'] as Map<String, dynamic>? ?? {}),
      byPort: (json['by_port'] as List<dynamic>?)
              ?.map((e) => PortTraffic.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// ─── Device Comparison ──────────────────────────────────

class DeviceComparison {
  final int deviceId;
  final String label;
  final String ip;
  final double value;

  const DeviceComparison({
    required this.deviceId,
    required this.label,
    required this.ip,
    required this.value,
  });

  factory DeviceComparison.fromJson(Map<String, dynamic> json) {
    return DeviceComparison(
      deviceId: (json['device_id'] as num?)?.toInt() ?? 0,
      label: json['label'] as String? ?? '',
      ip: json['ip'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ─── Top Talker Snapshot (History) ───────────────────────

class TopTalkerSnapshot {
  final DateTime timestamp;
  final int deviceId;
  final String ip;
  final String hostname;
  final int rank;
  final double totalConsumption;
  final bool isHog;

  const TopTalkerSnapshot({
    required this.timestamp,
    required this.deviceId,
    required this.ip,
    required this.hostname,
    required this.rank,
    required this.totalConsumption,
    required this.isHog,
  });

  /// bytes → Mbps
  double get consumptionMbps => totalConsumption * 8 / 1000000;

  factory TopTalkerSnapshot.fromJson(Map<String, dynamic> json) {
    return TopTalkerSnapshot(
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      deviceId: (json['device_id'] as num?)?.toInt() ?? 0,
      ip: json['ip'] as String? ?? '',
      hostname: (json['alias'] as String?) ??
          (json['hostname'] as String?) ??
          json['ip'] as String? ??
          'Unknown',
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      totalConsumption:
          (json['total_consumption'] as num?)?.toDouble() ?? 0,
      isHog: json['is_hog'] as bool? ?? false,
    );
  }
}

// ─── Dashboard Summary ──────────────────────────────────

class DashboardSummary {
  final double healthScore;
  final int devicesActive;
  final int devicesTotal;
  final int agentsActive;
  final int agentsTotal;
  final double ispLatencyAvg;
  final double packetLossPct;
  final double jitter;
  final int unseenAlerts;
  final String topConsumerName;
  final double topConsumerBytes;

  const DashboardSummary({
    required this.healthScore,
    required this.devicesActive,
    required this.devicesTotal,
    required this.agentsActive,
    required this.agentsTotal,
    required this.ispLatencyAvg,
    required this.packetLossPct,
    required this.jitter,
    required this.unseenAlerts,
    required this.topConsumerName,
    required this.topConsumerBytes,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      healthScore: (json['health_score'] as num?)?.toDouble() ?? 0,
      devicesActive: (json['devices_active'] as num?)?.toInt() ?? 0,
      devicesTotal: (json['devices_total'] as num?)?.toInt() ?? 0,
      agentsActive: (json['agents_active'] as num?)?.toInt() ?? 0,
      agentsTotal: (json['agents_total'] as num?)?.toInt() ?? 0,
      ispLatencyAvg: (json['isp_latency_avg'] as num?)?.toDouble() ?? 0,
      packetLossPct: (json['packet_loss_pct'] as num?)?.toDouble() ?? 0,
      jitter: (json['jitter'] as num?)?.toDouble() ?? 0,
      unseenAlerts: (json['unseen_alerts'] as num?)?.toInt() ?? 0,
      topConsumerName: json['top_consumer_name'] as String? ?? '-',
      topConsumerBytes: (json['top_consumer_bytes'] as num?)?.toDouble() ?? 0,
    );
  }
}
