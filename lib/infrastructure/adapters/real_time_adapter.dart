import 'dart:async';

import '../../core/entities/real_time_event.dart';
import '../../core/ports/real_time_port.dart';
import '../../services/websocket_service.dart';
import '../dtos/alert_dto.dart';
import '../mappers/alert_mapper.dart';

class RealTimeAdapter implements RealTimePort {
  final WebSocketService _ws;
  final _controller = StreamController<RealTimeEvent>.broadcast();
  StreamSubscription<Map<String, dynamic>>? _sub;

  RealTimeAdapter(this._ws);

  @override
  Stream<RealTimeEvent> get events => _controller.stream;

  @override
  bool get isConnected => _ws.isConnected;

  @override
  void connect(String url) {
    _ws.connect(url);
    _sub = _ws.stateUpdates.listen(_onMessage);
  }

  void _onMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    if (type == 'alert_created') {
      final alertJson = msg['alert'] as Map<String, dynamic>? ?? msg;
      final dto = AlertDto.fromJson(alertJson);
      final entity = AlertMapper.toEntity(dto);
      _controller.add(AlertCreatedEvent(alert: entity));
    } else if (type == 'state_update') {
      final net = msg['network'] as Map<String, dynamic>?;
      final devs =
          (msg['devices'] as List<dynamic>?)
              ?.map((d) => d as Map<String, dynamic>)
              .map(
                (d) => RealTimeDeviceUpdate(
                  id: d['id'].toString(),
                  ip: d['ip'] as String?,
                  status: d['status'] as String?,
                  cpuPct: _d(d['cpu_pct']),
                  ramPct: _d(d['ram_pct']),
                ),
              )
              .toList() ??
          [];
      _controller.add(
        StateUpdateEvent(
          ispLatencyAvg: _d(net?['isp_latency_avg']),
          packetLossPct: _d(net?['packet_loss_pct']),
          jitter: _d(net?['jitter']),
          unseenAlerts: msg['unseen_alerts'] as int?,
          devices: devs,
        ),
      );
    }
  }

  static double? _d(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }

  @override
  void disconnect() {
    _sub?.cancel();
    _ws.disconnect();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
    _ws.dispose();
  }
}
