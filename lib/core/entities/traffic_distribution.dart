class ProtocolTrafficEntity {
  final String protocol;
  final int bytes;
  final double percentage;

  const ProtocolTrafficEntity({
    required this.protocol,
    required this.bytes,
    required this.percentage,
  });
}

class DirectionTrafficEntity {
  final int internal;
  final int external;
  final double internalPct;
  final double externalPct;

  const DirectionTrafficEntity({
    required this.internal,
    required this.external,
    required this.internalPct,
    required this.externalPct,
  });
}

class PortTrafficEntity {
  final int port;
  final String service;
  final int bytes;
  final double percentage;

  const PortTrafficEntity({
    required this.port,
    required this.service,
    required this.bytes,
    required this.percentage,
  });
}

class TrafficDistributionEntity {
  final List<ProtocolTrafficEntity> byProtocol;
  final DirectionTrafficEntity byDirection;
  final List<PortTrafficEntity> byPort;

  const TrafficDistributionEntity({
    required this.byProtocol,
    required this.byDirection,
    required this.byPort,
  });
}
