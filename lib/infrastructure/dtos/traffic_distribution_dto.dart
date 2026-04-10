class ProtocolTrafficDto {
  final String? protocol;
  final dynamic bytes;
  final dynamic percentage;

  const ProtocolTrafficDto({this.protocol, this.bytes, this.percentage});

  factory ProtocolTrafficDto.fromJson(Map<String, dynamic> json) =>
      ProtocolTrafficDto(
        protocol: json['protocol'] as String?,
        bytes: json['bytes'],
        percentage: json['percentage'],
      );
}

class DirectionTrafficDto {
  final dynamic internal;
  final dynamic external;
  final dynamic internalPct;
  final dynamic externalPct;

  const DirectionTrafficDto({
    this.internal,
    this.external,
    this.internalPct,
    this.externalPct,
  });

  factory DirectionTrafficDto.fromJson(Map<String, dynamic> json) =>
      DirectionTrafficDto(
        internal: json['internal'],
        external: json['external'],
        internalPct: json['internal_pct'],
        externalPct: json['external_pct'],
      );
}

class PortTrafficDto {
  final dynamic port;
  final String? service;
  final dynamic bytes;
  final dynamic percentage;

  const PortTrafficDto({this.port, this.service, this.bytes, this.percentage});

  factory PortTrafficDto.fromJson(Map<String, dynamic> json) => PortTrafficDto(
    port: json['port'],
    service: json['service'] as String?,
    bytes: json['bytes'],
    percentage: json['percentage'],
  );
}

class TrafficDistributionDto {
  final List<ProtocolTrafficDto> byProtocol;
  final DirectionTrafficDto byDirection;
  final List<PortTrafficDto> byPort;

  const TrafficDistributionDto({
    required this.byProtocol,
    required this.byDirection,
    required this.byPort,
  });

  factory TrafficDistributionDto.fromJson(Map<String, dynamic> json) =>
      TrafficDistributionDto(
        byProtocol:
            (json['by_protocol'] as List<dynamic>?)
                ?.map(
                  (e) => ProtocolTrafficDto.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
        byDirection: DirectionTrafficDto.fromJson(
          json['by_direction'] as Map<String, dynamic>? ?? {},
        ),
        byPort:
            (json['by_port'] as List<dynamic>?)
                ?.map((e) => PortTrafficDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
