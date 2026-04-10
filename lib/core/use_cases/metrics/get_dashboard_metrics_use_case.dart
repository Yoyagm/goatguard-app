import '../../entities/network_metrics.dart';
import '../../entities/top_consumer.dart';
import '../../failure.dart';
import '../../ports/alert_repository.dart';
import '../../ports/network_repository.dart';
import '../calculate_health_score.dart';

class GetDashboardMetricsUseCase {
  final NetworkRepository _networkRepository;
  final AlertRepository _alertRepository;
  final CalculateHealthScore _calculateHealthScore;

  GetDashboardMetricsUseCase(
    this._networkRepository,
    this._alertRepository,
    this._calculateHealthScore,
  );

  Future<Result<NetworkMetricsEntity>> call({
    required int activeAgents,
    required int totalAgents,
  }) async {
    final rawResult = await _networkRepository.getRawNetworkMetrics();
    final talkersResult = await _networkRepository.getTopTalkers();
    final unseenResult = await _alertRepository.getUnseenCount();

    if (rawResult case Err(:final failure)) return Err(failure);
    if (talkersResult case Err(:final failure)) return Err(failure);
    if (unseenResult case Err(:final failure)) return Err(failure);

    final raw = (rawResult as Success<Map<String, dynamic>>).data;
    final talkers = (talkersResult as Success<List<TopConsumerEntity>>).data;
    final unseen = (unseenResult as Success<int>).data;

    final latency = _d(raw['isp_latency_ms']);
    final loss = _d(raw['packet_loss_percent']);
    final jitter = _d(raw['jitter_ms']);
    final dns = _d(raw['dns_response_time_ms']);
    final activeDevices = (raw['active_devices'] as num?)?.toInt() ?? 0;
    final totalDevices = (raw['total_devices'] as num?)?.toInt() ?? 0;

    final healthScore = _calculateHealthScore(
      latency: latency,
      loss: loss,
      jitter: jitter,
      dns: dns,
    );

    String topName = 'N/A';
    double topMbps = 0;
    if (talkers.isNotEmpty) {
      topName = talkers.first.name;
      topMbps = talkers.first.consumptionMbps;
    }

    return Success(
      NetworkMetricsEntity(
        healthScore: healthScore,
        ispLatencyMs: latency,
        packetLossPercent: loss,
        jitterMs: jitter,
        dnsResponseTimeMs: dns,
        activeDevices: activeDevices,
        totalDevices: totalDevices,
        activeAgents: activeAgents,
        totalAgents: totalAgents,
        pendingAlerts: unseen,
        topConsumerName: topName,
        topConsumerMbps: topMbps,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  double _d(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}
