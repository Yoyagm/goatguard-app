import 'alert.dart';

sealed class RealTimeEvent {}

class StateUpdateEvent extends RealTimeEvent {
  final double? ispLatencyAvg;
  final double? packetLossPct;
  final double? jitter;
  final int? unseenAlerts;
  final List<RealTimeDeviceUpdate> devices;

  StateUpdateEvent({
    this.ispLatencyAvg,
    this.packetLossPct,
    this.jitter,
    this.unseenAlerts,
    required this.devices,
  });
}

class RealTimeDeviceUpdate {
  final String id;
  final String? ip;
  final String? status;
  final double? cpuPct;
  final double? ramPct;

  const RealTimeDeviceUpdate({
    required this.id,
    this.ip,
    this.status,
    this.cpuPct,
    this.ramPct,
  });
}

class AlertCreatedEvent extends RealTimeEvent {
  final NetworkAlertEntity alert;

  AlertCreatedEvent({
    required this.alert,
  });
}
