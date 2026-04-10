import 'package:flutter/foundation.dart';
import '../core/failure.dart';
import '../core/entities/alert.dart';
import '../core/use_cases/alerts/get_alerts_use_case.dart';
import '../core/use_cases/alerts/get_unseen_count_use_case.dart';
import '../core/use_cases/alerts/mark_alert_seen_use_case.dart';

/// Provider de alertas [RF-15, RF-19]
class AlertProvider extends ChangeNotifier {
  final GetAlertsUseCase _getAlertsUseCase;
  final GetUnseenCountUseCase _getUnseenCountUseCase;
  final MarkAlertSeenUseCase _markAlertSeenUseCase;

  List<NetworkAlertEntity> _alerts = [];
  int _unseenCount = 0;
  bool _loading = false;
  String? _error;

  AlertProvider({
    required GetAlertsUseCase getAlertsUseCase,
    required GetUnseenCountUseCase getUnseenCountUseCase,
    required MarkAlertSeenUseCase markAlertSeenUseCase,
  }) : _getAlertsUseCase = getAlertsUseCase,
       _getUnseenCountUseCase = getUnseenCountUseCase,
       _markAlertSeenUseCase = markAlertSeenUseCase;

  List<NetworkAlertEntity> get alerts => _alerts;
  int get unseenCount => _unseenCount;
  bool get loading => _loading;
  String? get error => _error;

  /// Cargar alertas desde el dominio
  Future<void> fetchAlerts({String? severity, bool? seen}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final alertsResult = await _getAlertsUseCase.call(
      severity: severity,
      seen: seen,
    );
    final countResult = await _getUnseenCountUseCase.call();

    switch (alertsResult) {
      case Success(:final data):
        _alerts = data;
      case Err(:final failure):
        _error = failure.message;
    }

    switch (countResult) {
      case Success(:final data):
        _unseenCount = data;
      case Err(:final failure):
        // Solo sobreescribir error si no hay uno previo
        _error ??= failure.message;
    }

    _loading = false;
    notifyListeners();
  }

  /// Marcar alerta como leida [RF-19]
  Future<void> markAsSeen(String alertId) async {
    final result = await _markAlertSeenUseCase.call(int.parse(alertId));

    switch (result) {
      case Success():
        // Actualizar localmente sin esperar re-fetch
        final idx = _alerts.indexWhere((a) => a.id == alertId);
        if (idx != -1) {
          _alerts[idx] = _alerts[idx].copyWith(isRead: true);
          _unseenCount = (_unseenCount - 1).clamp(0, _unseenCount);
          notifyListeners();
        }
      case Err(:final failure):
        _error = failure.message;
        notifyListeners();
    }
  }

  /// Insertar alerta recibida via WebSocket push (`alert_created`).
  /// Recibe un [NetworkAlertEntity] ya tipado desde el RealTimeEvent.
  void addAlertFromWs(NetworkAlertEntity alert) {
    _alerts.insert(0, alert);
    _unseenCount++;
    notifyListeners();
  }

  /// Actualizar conteo desde WebSocket
  void updateUnseenCount(int count) {
    if (_unseenCount != count) {
      _unseenCount = count;
      notifyListeners();
    }
  }
}
