import 'package:flutter/foundation.dart';
import '../models/alert.dart';
import '../services/api_service.dart';

/// Provider de alertas [RF-15, RF-19]
class AlertProvider extends ChangeNotifier {
  final ApiService _api;

  List<NetworkAlert> _alerts = [];
  int _unseenCount = 0;
  bool _loading = false;
  String? _error;

  AlertProvider(this._api);

  List<NetworkAlert> get alerts => _alerts;
  int get unseenCount => _unseenCount;
  bool get loading => _loading;
  String? get error => _error;

  /// Cargar alertas desde la API
  Future<void> fetchAlerts({String? severity, bool? seen}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final rawAlerts = await _api.getAlerts(severity: severity, seen: seen);
      _alerts = rawAlerts
          .map((json) => NetworkAlert.fromJson(json as Map<String, dynamic>))
          .toList();

      final countData = await _api.getAlertCount();
      _unseenCount = countData['unseen_count'] as int? ?? 0;

      _loading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
    }
  }

  /// Marcar alerta como leída [RF-19]
  Future<void> markAsSeen(String alertId) async {
    try {
      await _api.markAlertSeen(int.parse(alertId));
      // Actualizar localmente sin esperar re-fetch
      final idx = _alerts.indexWhere((a) => a.id == alertId);
      if (idx != -1) {
        final old = _alerts[idx];
        _alerts[idx] = NetworkAlert(
          id: old.id,
          title: old.title,
          description: old.description,
          severity: old.severity,
          deviceName: old.deviceName,
          deviceIp: old.deviceIp,
          timestamp: old.timestamp,
          isRead: true,
        );
        _unseenCount = (_unseenCount - 1).clamp(0, _unseenCount);
        notifyListeners();
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  /// Actualizar conteo desde WebSocket
  void updateUnseenCount(int count) {
    if (_unseenCount != count) {
      _unseenCount = count;
      notifyListeners();
    }
  }
}
