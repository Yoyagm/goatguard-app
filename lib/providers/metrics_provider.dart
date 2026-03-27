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
  List<NetworkSnapshot> _networkHistory = [];
  IspHealthDetail? _ispHealth;
  TrafficDistribution? _trafficDistribution;
  DashboardSummary? _dashboardSummary;
  List<TopTalkerSnapshot> _topTalkersHistory = [];
  List<DeviceComparison> _deviceComparison = [];
  String _comparisonMetric = 'bandwidth_in';
  bool _loading = false;
  String? _error;

  /// Stream de alertas push recibidas vía WS (`alert_created`)
  final _wsAlertController = StreamController<Map<String, dynamic>>.broadcast();

  MetricsProvider(this._api, this._ws);

  NetworkMetrics? get metrics => _metrics;
  List<TopConsumer> get topConsumers => _topConsumers;
  List<NetworkSnapshot> get networkHistory => _networkHistory;
  IspHealthDetail? get ispHealth => _ispHealth;
  TrafficDistribution? get trafficDistribution => _trafficDistribution;
  DashboardSummary? get dashboardSummary => _dashboardSummary;
  List<TopTalkerSnapshot> get topTalkersHistory => _topTalkersHistory;
  List<DeviceComparison> get deviceComparison => _deviceComparison;
  String get comparisonMetric => _comparisonMetric;
  bool get loading => _loading;
  String? get error => _error;
  Stream<Map<String, dynamic>> get wsAlerts => _wsAlertController.stream;

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

  // ─── Nuevos fetch methods ─────────────────────────────

  Future<void> fetchNetworkHistory({int hours = 4}) async {
    try {
      final raw = await _api.getNetworkHistory(hours: hours);
      _networkHistory = raw
          .map((j) => NetworkSnapshot.fromJson(j as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> fetchIspHealth() async {
    try {
      final json = await _api.getIspHealth();
      _ispHealth = IspHealthDetail.fromJson(json);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> fetchTrafficDistribution() async {
    try {
      final json = await _api.getTrafficDistribution();
      _trafficDistribution = TrafficDistribution.fromJson(json);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> fetchTopTalkersHistory({int hours = 4}) async {
    try {
      final raw = await _api.getTopTalkersHistory(hours: hours);
      _topTalkersHistory = raw
          .map((j) => TopTalkerSnapshot.fromJson(j as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> fetchDeviceComparison({String? metric}) async {
    if (metric != null) _comparisonMetric = metric;
    try {
      final raw = await _api.getDeviceComparison(metric: _comparisonMetric);
      _deviceComparison = raw
          .map((j) => DeviceComparison.fromJson(j as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> fetchDashboardSummary() async {
    try {
      final json = await _api.getDashboardSummary();
      _dashboardSummary = DashboardSummary.fromJson(json);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  /// Conectar WebSocket y escuchar state_update + alert_created
  void startWebSocket(String token) {
    final url = _api.getWebSocketUrl(token);
    _ws.connect(url);
    _wsSub = _ws.stateUpdates.listen(_onWsMessage);
  }

  void _onWsMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;

    if (type == 'alert_created') {
      _wsAlertController.add(msg);
      return;
    }

    if (type != 'state_update') return;

    final netJson = msg['network'] as Map<String, dynamic>?;
    if (netJson != null && _metrics != null) {
      _metrics = NetworkMetrics(
        healthScore: _metrics!.healthScore,
        ispLatencyMs: _d(netJson['isp_latency_avg']),
        packetLossPercent: _d(netJson['packet_loss_pct']),
        jitterMs: _d(netJson['jitter']),
        dnsResponseTimeMs: _metrics!.dnsResponseTimeMs,
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
    _wsAlertController.close();
    _ws.dispose();
    super.dispose();
  }

  static double _d(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}
