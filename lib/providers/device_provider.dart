import 'package:flutter/foundation.dart';
import '../core/failure.dart';
import '../core/entities/device.dart';
import '../core/entities/agent.dart';
import '../core/entities/device_snapshot.dart';
import '../core/entities/device_connection.dart';
import '../core/entities/real_time_event.dart';
import '../core/use_cases/devices/get_devices_use_case.dart';
import '../core/use_cases/devices/get_device_detail_use_case.dart';
import '../core/use_cases/devices/update_device_alias_use_case.dart';
import '../core/use_cases/devices/get_device_history_use_case.dart';
import '../core/use_cases/devices/get_device_connections_use_case.dart';
import '../core/use_cases/agents/get_agents_use_case.dart';

/// Provider de dispositivos y agentes [RF-17, RF-18]
class DeviceProvider extends ChangeNotifier {
  final GetDevicesUseCase _getDevicesUseCase;
  final GetAgentsUseCase _getAgentsUseCase;
  final GetDeviceDetailUseCase _getDeviceDetailUseCase;
  final UpdateDeviceAliasUseCase _updateDeviceAliasUseCase;
  final GetDeviceHistoryUseCase _getDeviceHistoryUseCase;
  final GetDeviceConnectionsUseCase _getDeviceConnectionsUseCase;

  List<DeviceEntity> _devices = [];
  List<AgentEntity> _agents = [];
  List<DeviceSnapshotEntity> _deviceHistory = [];
  List<DeviceConnectionEntity> _deviceConnections = [];
  bool _loading = false;
  String? _error;

  DeviceProvider({
    required GetDevicesUseCase getDevicesUseCase,
    required GetAgentsUseCase getAgentsUseCase,
    required GetDeviceDetailUseCase getDeviceDetailUseCase,
    required UpdateDeviceAliasUseCase updateDeviceAliasUseCase,
    required GetDeviceHistoryUseCase getDeviceHistoryUseCase,
    required GetDeviceConnectionsUseCase getDeviceConnectionsUseCase,
  })  : _getDevicesUseCase = getDevicesUseCase,
        _getAgentsUseCase = getAgentsUseCase,
        _getDeviceDetailUseCase = getDeviceDetailUseCase,
        _updateDeviceAliasUseCase = updateDeviceAliasUseCase,
        _getDeviceHistoryUseCase = getDeviceHistoryUseCase,
        _getDeviceConnectionsUseCase = getDeviceConnectionsUseCase;

  List<DeviceEntity> get devices => _devices;
  List<AgentEntity> get agents => _agents;
  List<DeviceSnapshotEntity> get deviceHistory => _deviceHistory;
  List<DeviceConnectionEntity> get deviceConnections => _deviceConnections;
  bool get loading => _loading;
  String? get error => _error;

  int get activeDeviceCount =>
      _devices.where((d) => d.status == DeviceStatus.online).length;
  int get totalDeviceCount => _devices.length;
  int get activeAgentCount =>
      _agents.where((a) => a.status == AgentStatus.active).length;
  int get totalAgentCount => _agents.length;

  /// Cargar dispositivos desde el dominio [RF-18]
  Future<void> fetchDevices() async {
    _loading = true;
    _error = null;
    notifyListeners();

    final result = await _getDevicesUseCase.call();

    switch (result) {
      case Success(:final data):
        _devices = data;
      case Err(:final failure):
        _error = failure.message;
    }
    _loading = false;
    notifyListeners();
  }

  /// Cargar agentes [RF-037]
  Future<void> fetchAgents({String? status}) async {
    final result = await _getAgentsUseCase.call(status: status);

    switch (result) {
      case Success(:final data):
        _agents = data;
      case Err(:final failure):
        _error = failure.message;
    }
    notifyListeners();
  }

  /// Obtener detalle completo de un device
  Future<DeviceEntity?> fetchDeviceDetail(int id) async {
    final result = await _getDeviceDetailUseCase.call(id);

    switch (result) {
      case Success(:final data):
        return data;
      case Err(:final failure):
        _error = failure.message;
        notifyListeners();
        return null;
    }
  }

  // --- History & connections -------------------------------------------------

  Future<void> fetchDeviceHistory(int deviceId, {int hours = 4}) async {
    final result = await _getDeviceHistoryUseCase.call(deviceId, hours: hours);

    switch (result) {
      case Success(:final data):
        _deviceHistory = data;
      case Err(:final failure):
        _error = failure.message;
    }
    notifyListeners();
  }

  Future<void> fetchDeviceConnections(int deviceId) async {
    final result = await _getDeviceConnectionsUseCase.call(deviceId);

    switch (result) {
      case Success(:final data):
        _deviceConnections = data;
      case Err(:final failure):
        _error = failure.message;
    }
    notifyListeners();
  }

  /// Actualizar alias de un dispositivo [RF-18]
  Future<bool> updateAlias(int deviceId, String alias) async {
    final result = await _updateDeviceAliasUseCase.call(deviceId, alias);

    switch (result) {
      case Success():
        // Refrescar lista tras el cambio
        await fetchDevices();
        return true;
      case Err(:final failure):
        _error = failure.message;
        notifyListeners();
        return false;
    }
  }

  /// Actualizar datos parciales desde WebSocket state_update.
  /// Recibe una lista tipada de [RealTimeDeviceUpdate] proveniente del
  /// [StateUpdateEvent] procesado en MetricsProvider.
  void updateFromWs(List<RealTimeDeviceUpdate> wsDevices) {
    for (final update in wsDevices) {
      final idx = _devices.indexWhere((d) => d.id == update.id);
      if (idx != -1) {
        final old = _devices[idx];
        _devices[idx] = old.copyWith(
          ipAddress: update.ip ?? old.ipAddress,
          status: update.status == 'active'
              ? DeviceStatus.online
              : (update.status != null ? DeviceStatus.offline : null),
          cpuUsage: update.cpuPct != null ? () => update.cpuPct : null,
          ramUsage: update.ramPct != null ? () => update.ramPct : null,
          lastSeen: DateTime.now(),
        );
      }
    }
    notifyListeners();
  }
}
