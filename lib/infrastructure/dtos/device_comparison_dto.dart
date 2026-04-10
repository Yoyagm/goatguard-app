class DeviceComparisonDto {
  final dynamic deviceId;
  final String? label;
  final String? ip;
  final dynamic value;

  const DeviceComparisonDto({this.deviceId, this.label, this.ip, this.value});

  factory DeviceComparisonDto.fromJson(Map<String, dynamic> json) =>
      DeviceComparisonDto(
        deviceId: json['device_id'],
        label: json['label'] as String?,
        ip: json['ip'] as String?,
        value: json['value'],
      );
}
