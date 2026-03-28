import 'package:flutter/foundation.dart';
import '../models/device.dart';
import '../models/agent.dart';
import '../services/api_service.dart';

/// Provider de dispositivos y agentes [RF-17, RF-18]
class DeviceProvider extends ChangeNotifier {
  final ApiService _api;

  List<Device> _devices = [];
  List<Agent> _agents = [];
  List<DeviceSnapshot> _deviceHistory = [];
  List<DeviceConnection> _deviceConnections = [];
  bool _loading = false;
  String? _error;

  DeviceProvider(this._api);

  List<Device> get devices => _devices;
  List<Agent> get agents => _agents;
  List<DeviceSnapshot> get deviceHistory => _deviceHistory;
  List<DeviceConnection> get deviceConnections => _deviceConnections;
  bool get loading => _loading;
  String? get error => _error;

  int get activeDeviceCount =>
      _devices.where((d) => d.status == DeviceStatus.online).length;
  int get totalDeviceCount => _devices.length;
  int get activeAgentCount =>
      _agents.where((a) => a.status == AgentStatus.active).length;
  int get totalAgentCount => _agents.length;

  /// Cargar dispositivos desde la API [RF-18]
  Future<void> fetchDevices() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final rawDevices = await _api.getDevices();
      _devices = rawDevices
          .map((json) => Device.fromJson(json as Map<String, dynamic>))
          .toList();
      _loading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
    }
  }

  /// Cargar agentes desde GET /agents [RF-037]
  Future<void> fetchAgents({String? status}) async {
    try {
      final rawAgents = await _api.getAgents(status: status);
      _agents = rawAgents
          .map((json) => Agent.fromJson(json as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  /// Obtener detalle completo de un device
  Future<Device?> fetchDeviceDetail(int id) async {
    try {
      final json = await _api.getDevice(id);
      return Device.fromJson(json);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  // ─── Nuevos métodos: history & connections ────────────

  Future<void> fetchDeviceHistory(int deviceId, {int hours = 4}) async {
    try {
      final raw = await _api.getDeviceHistory(deviceId, hours: hours);
      _deviceHistory = raw
          .map((j) => DeviceSnapshot.fromJson(j as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> fetchDeviceConnections(int deviceId) async {
    try {
      final raw = await _api.getDeviceConnections(deviceId);
      _deviceConnections = raw
          .map((j) => DeviceConnection.fromJson(j as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  /// Actualizar alias de un dispositivo [RF-18]
  Future<bool> updateAlias(int deviceId, String alias) async {
    try {
      await _api.updateAlias(deviceId, alias);
      // Refrescar lista tras el cambio
      await fetchDevices();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Actualizar datos parciales desde WebSocket state_update
  void updateFromWs(List<dynamic> wsDevices) {
    for (final wsData in wsDevices) {
      final wsMap = wsData as Map<String, dynamic>;
      final wsId = wsMap['id'].toString();
      final idx = _devices.indexWhere((d) => d.id == wsId);
      if (idx != -1) {
        // Actualizar solo campos que cambian en tiempo real
        final old = _devices[idx];
        _devices[idx] = Device(
          id: old.id,
          name: old.name,
          ipAddress: wsMap['ip'] as String? ?? old.ipAddress,
          macAddress: old.macAddress,
          type: old.type,
          coverage: old.coverage,
          status: (wsMap['status'] as String?) == 'active'
              ? DeviceStatus.online
              : DeviceStatus.offline,
          os: old.os,
          cpuUsage: _toDouble(wsMap['cpu_pct']) ?? old.cpuUsage,
          ramUsage: _toDouble(wsMap['ram_pct']) ?? old.ramUsage,
          speedMbps: old.speedMbps,
          latencyMs: old.latencyMs,
          retransmissionsPerMin: old.retransmissionsPerMin,
          failedConnections: old.failedConnections,
          alertCount: old.alertCount,
          lastSeen: DateTime.now(),
        );
      }
    }
    notifyListeners();
  }

  static double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }
}
