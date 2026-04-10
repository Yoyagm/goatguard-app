import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/failure.dart';
import '../core/entities/network_metrics.dart';
import '../core/entities/network_snapshot.dart';
import '../core/entities/isp_health.dart';
import '../core/entities/traffic_distribution.dart';
import '../core/entities/top_talker_snapshot.dart';
import '../core/entities/device_comparison.dart';
import '../core/entities/dashboard_summary.dart';
import '../core/entities/top_consumer.dart';
import '../core/entities/alert.dart';
import '../core/entities/real_time_event.dart';
import '../core/ports/network_repository.dart';
import '../core/use_cases/metrics/get_dashboard_metrics_use_case.dart';
import '../core/use_cases/metrics/get_network_history_use_case.dart';
import '../core/use_cases/metrics/get_isp_health_use_case.dart';
import '../core/use_cases/metrics/get_traffic_distribution_use_case.dart';
import '../core/use_cases/metrics/get_top_talkers_history_use_case.dart';
import '../core/use_cases/metrics/get_dashboard_summary_use_case.dart';
import '../core/use_cases/devices/get_device_comparison_use_case.dart';
import '../core/ports/real_time_port.dart';
import '../services/api_service.dart';

/// Provider de metricas de red + WebSocket real-time [RF-17]
class MetricsProvider extends ChangeNotifier {
  final GetDashboardMetricsUseCase _getDashboardMetricsUseCase;
  final GetNetworkHistoryUseCase _getNetworkHistoryUseCase;
  final GetIspHealthUseCase _getIspHealthUseCase;
  final GetTrafficDistributionUseCase _getTrafficDistributionUseCase;
  final GetTopTalkersHistoryUseCase _getTopTalkersHistoryUseCase;
  final GetDashboardSummaryUseCase _getDashboardSummaryUseCase;
  final GetDeviceComparisonUseCase _getDeviceComparisonUseCase;
  final NetworkRepository _networkRepository;
  final RealTimePort _realTimePort;
  final ApiService _api; // retained only for getWebSocketUrl()
  StreamSubscription<RealTimeEvent>? _rtSub;

  NetworkMetricsEntity? _metrics;
  List<TopConsumerEntity> _topConsumers = [];
  List<NetworkSnapshotEntity> _networkHistory = [];
  IspHealthDetailEntity? _ispHealth;
  TrafficDistributionEntity? _trafficDistribution;
  DashboardSummaryEntity? _dashboardSummary;
  List<TopTalkerSnapshotEntity> _topTalkersHistory = [];
  List<DeviceComparisonEntity> _deviceComparison = [];
  String _comparisonMetric = 'bandwidth_in';
  bool _loading = false;
  String? _error;

  /// Stream de alertas push recibidas via WS (`alert_created`)
  final _wsAlertController = StreamController<NetworkAlertEntity>.broadcast();

  MetricsProvider({
    required GetDashboardMetricsUseCase getDashboardMetricsUseCase,
    required GetNetworkHistoryUseCase getNetworkHistoryUseCase,
    required GetIspHealthUseCase getIspHealthUseCase,
    required GetTrafficDistributionUseCase getTrafficDistributionUseCase,
    required GetTopTalkersHistoryUseCase getTopTalkersHistoryUseCase,
    required GetDashboardSummaryUseCase getDashboardSummaryUseCase,
    required GetDeviceComparisonUseCase getDeviceComparisonUseCase,
    required NetworkRepository networkRepository,
    required RealTimePort realTimePort,
    required ApiService apiService,
  }) : _getDashboardMetricsUseCase = getDashboardMetricsUseCase,
       _getNetworkHistoryUseCase = getNetworkHistoryUseCase,
       _getIspHealthUseCase = getIspHealthUseCase,
       _getTrafficDistributionUseCase = getTrafficDistributionUseCase,
       _getTopTalkersHistoryUseCase = getTopTalkersHistoryUseCase,
       _getDashboardSummaryUseCase = getDashboardSummaryUseCase,
       _getDeviceComparisonUseCase = getDeviceComparisonUseCase,
       _networkRepository = networkRepository,
       _realTimePort = realTimePort,
       _api = apiService;

  NetworkMetricsEntity? get metrics => _metrics;
  List<TopConsumerEntity> get topConsumers => _topConsumers;
  List<NetworkSnapshotEntity> get networkHistory => _networkHistory;
  IspHealthDetailEntity? get ispHealth => _ispHealth;
  TrafficDistributionEntity? get trafficDistribution => _trafficDistribution;
  DashboardSummaryEntity? get dashboardSummary => _dashboardSummary;
  List<TopTalkerSnapshotEntity> get topTalkersHistory => _topTalkersHistory;
  List<DeviceComparisonEntity> get deviceComparison => _deviceComparison;
  String get comparisonMetric => _comparisonMetric;
  bool get loading => _loading;
  String? get error => _error;
  Stream<NetworkAlertEntity> get wsAlerts => _wsAlertController.stream;

  /// Carga inicial: REST para datos completos
  Future<void> fetchMetrics({
    int activeAgents = 0,
    int totalAgents = 0,
    int unseenAlerts = 0,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final metricsResult = await _getDashboardMetricsUseCase.call(
      activeAgents: activeAgents,
      totalAgents: totalAgents,
    );
    final talkersResult = await _networkRepository.getTopTalkers();

    switch (metricsResult) {
      case Success(:final data):
        _metrics = data;
      case Err(:final failure):
        _error = failure.message;
    }

    switch (talkersResult) {
      case Success(:final data):
        _topConsumers = data;
      case Err(:final failure):
        _error ??= failure.message;
    }

    _loading = false;
    notifyListeners();
  }

  // --- Fetch methods --------------------------------------------------------

  Future<void> fetchNetworkHistory({int hours = 4}) async {
    final result = await _getNetworkHistoryUseCase.call(hours: hours);

    switch (result) {
      case Success(:final data):
        _networkHistory = data;
      case Err(:final failure):
        _error = failure.message;
    }
    notifyListeners();
  }

  Future<void> fetchIspHealth() async {
    final result = await _getIspHealthUseCase.call();

    switch (result) {
      case Success(:final data):
        _ispHealth = data;
      case Err(:final failure):
        _error = failure.message;
    }
    notifyListeners();
  }

  Future<void> fetchTrafficDistribution() async {
    final result = await _getTrafficDistributionUseCase.call();

    switch (result) {
      case Success(:final data):
        _trafficDistribution = data;
      case Err(:final failure):
        _error = failure.message;
    }
    notifyListeners();
  }

  Future<void> fetchTopTalkersHistory({int hours = 4}) async {
    final result = await _getTopTalkersHistoryUseCase.call(hours: hours);

    switch (result) {
      case Success(:final data):
        _topTalkersHistory = data;
      case Err(:final failure):
        _error = failure.message;
    }
    notifyListeners();
  }

  Future<void> fetchDeviceComparison({String? metric}) async {
    if (metric != null) _comparisonMetric = metric;

    final result = await _getDeviceComparisonUseCase.call(
      metric: _comparisonMetric,
    );

    switch (result) {
      case Success(:final data):
        _deviceComparison = data;
      case Err(:final failure):
        _error = failure.message;
    }
    notifyListeners();
  }

  Future<void> fetchDashboardSummary() async {
    final result = await _getDashboardSummaryUseCase.call();

    switch (result) {
      case Success(:final data):
        _dashboardSummary = data;
      case Err(:final failure):
        _error = failure.message;
    }
    notifyListeners();
  }

  // --- Real-time (WebSocket) -------------------------------------------------

  /// Conectar al canal real-time y escuchar eventos tipados.
  void startWebSocket(String token) {
    final url = _api.getWebSocketUrl(token);
    _realTimePort.connect(url);
    _rtSub = _realTimePort.events.listen(_onRealTimeEvent);
  }

  void _onRealTimeEvent(RealTimeEvent event) {
    switch (event) {
      case AlertCreatedEvent(:final alert):
        _wsAlertController.add(alert);

      case StateUpdateEvent(
        :final ispLatencyAvg,
        :final packetLossPct,
        :final jitter,
        :final unseenAlerts,
      ):
        if (_metrics != null) {
          _metrics = _metrics!.copyWith(
            ispLatencyMs: ispLatencyAvg ?? _metrics!.ispLatencyMs,
            packetLossPercent: packetLossPct ?? _metrics!.packetLossPercent,
            jitterMs: jitter ?? _metrics!.jitterMs,
            pendingAlerts: unseenAlerts ?? _metrics!.pendingAlerts,
            lastUpdated: DateTime.now(),
          );
          notifyListeners();
        }
    }
  }

  void stopWebSocket() {
    _rtSub?.cancel();
    _realTimePort.disconnect();
  }

  @override
  void dispose() {
    stopWebSocket();
    _wsAlertController.close();
    _realTimePort.dispose();
    super.dispose();
  }
}
