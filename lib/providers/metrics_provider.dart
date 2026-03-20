import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/network_metrics.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

/// Provider de métricas de red + WebSocket real-time [RF-17]
class MetricsProvider extends ChangeNotifier {
  final ApiService _api;
  final WebSocketService _ws;
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  NetworkMetrics? _metrics;
  List<TopConsumer> _topConsumers = [];
  bool _loading = false;
  String? _error;

  MetricsProvider(this._api, this._ws);

  NetworkMetrics? get metrics => _metrics;
  List<TopConsumer> get topConsumers => _topConsumers;
  bool get loading => _loading;
  String? get error => _error;

  /// Carga inicial: REST para datos completos
  Future<void> fetchMetrics({
    int activeAgents = 0,
    int totalAgents = 0,
    int unseenAlerts = 0,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final netJson = await _api.getNetworkMetrics();
      final ttRaw = await _api.getTopTalkers();
      final countData = await _api.getAlertCount();

      _topConsumers = ttRaw
          .map((j) => TopConsumer.fromJson(j as Map<String, dynamic>))
          .toList();

      final topName = _topConsumers.isNotEmpty ? _topConsumers.first.name : '-';
      final topMbps =
          _topConsumers.isNotEmpty ? _topConsumers.first.consumptionMbps : 0.0;

      _metrics = NetworkMetrics.fromApi(
        networkJson: netJson,
        unseenAlerts: countData['unseen_count'] as int? ?? unseenAlerts,
        topConsumerName: topName,
        topConsumerMbps: topMbps,
        activeAgents: activeAgents,
        totalAgents: totalAgents,
      );

      _loading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
    }
  }

  /// Conectar WebSocket y escuchar state_update
  void startWebSocket(String token) {
    final url = _api.getWebSocketUrl(token);
    _ws.connect(url);
    _wsSub = _ws.stateUpdates.listen(_onWsMessage);
  }

  void _onWsMessage(Map<String, dynamic> msg) {
    if (msg['type'] != 'state_update') return;

    final netJson = msg['network'] as Map<String, dynamic>?;
    if (netJson != null && _metrics != null) {
      // Actualizar solo las métricas ISP que llegan por WS
      _metrics = NetworkMetrics(
        healthScore: _metrics!.healthScore, // Re-calcular sería costoso cada 5s
        ispLatencyMs: _d(netJson['isp_latency_avg']),
        packetLossPercent: _d(netJson['packet_loss_pct']),
        jitterMs: _d(netJson['jitter']),
        dnsResponseTimeMs: _metrics!.dnsResponseTimeMs, // No viene en WS
        activeDevices: _metrics!.activeDevices,
        totalDevices: _metrics!.totalDevices,
        activeAgents: _metrics!.activeAgents,
        totalAgents: _metrics!.totalAgents,
        pendingAlerts: msg['unseen_alerts'] as int? ?? _metrics!.pendingAlerts,
        topConsumerName: _metrics!.topConsumerName,
        topConsumerMbps: _metrics!.topConsumerMbps,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void stopWebSocket() {
    _wsSub?.cancel();
    _ws.disconnect();
  }

  @override
  void dispose() {
    stopWebSocket();
    _ws.dispose();
    super.dispose();
  }

  static double _d(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}
