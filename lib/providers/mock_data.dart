import 'dart:math';
import '../models/device.dart';
import '../models/network_metrics.dart';
import '../models/alert.dart';
import '../models/agent.dart';

class MockData {
  static final _now = DateTime.now();

  static NetworkMetrics get networkMetrics => NetworkMetrics(
    healthScore: 85,
    ispLatencyMs: 32,
    packetLossPercent: 0.2,
    jitterMs: 5,
    dnsResponseTimeMs: 45,
    activeDevices: 12,
    totalDevices: 15,
    activeAgents: 3,
    totalAgents: 5,
    pendingAlerts: 4,
    topConsumerName: 'Smart TV',
    topConsumerMbps: 42.3,
    lastUpdated: _now.subtract(const Duration(seconds: 30)),
  );

  static List<Device> get devices => [
    Device(
      id: '1',
      name: "Juan's MacBook",
      ipAddress: '192.168.59.255',
      macAddress: '00:1A:2B:3C:4D:5E',
      type: DeviceType.laptop,
      coverage: DeviceCoverage.withAgent,
      status: DeviceStatus.online,
      os: 'macOS 26 Tahoe',
      cpuUsage: 55,
      ramUsage: 70,
      speedMbps: 200,
      latencyMs: 90,
      retransmissionsPerMin: 12.8,
      failedConnections: 3,
      alertCount: 2,
      lastSeen: _now.subtract(const Duration(seconds: 5)),
    ),
    Device(
      id: '2',
      name: 'Server-01',
      ipAddress: '192.168.59.10',
      macAddress: '00:1A:2B:3C:4D:AA',
      type: DeviceType.server,
      coverage: DeviceCoverage.withAgent,
      status: DeviceStatus.online,
      os: 'Ubuntu 24.04 LTS',
      cpuUsage: 45,
      ramUsage: 62,
      speedMbps: 940,
      latencyMs: 2,
      retransmissionsPerMin: 0.3,
      failedConnections: 0,
      alertCount: 0,
      lastSeen: _now.subtract(const Duration(seconds: 5)),
    ),
    Device(
      id: '3',
      name: 'Laptop Dell',
      ipAddress: '192.168.59.12',
      macAddress: '00:1A:2B:3C:5F:12',
      type: DeviceType.laptop,
      coverage: DeviceCoverage.withAgent,
      status: DeviceStatus.online,
      os: 'Windows 11 Pro',
      cpuUsage: 23,
      ramUsage: 45,
      speedMbps: 240,
      latencyMs: 70,
      retransmissionsPerMin: 1.2,
      failedConnections: 0,
      alertCount: 0,
      lastSeen: _now.subtract(const Duration(seconds: 10)),
    ),
    Device(
      id: '4',
      name: 'Printer HP',
      ipAddress: '192.168.59.50',
      macAddress: '00:1A:2B:AA:BB:CC',
      type: DeviceType.printer,
      coverage: DeviceCoverage.withAgent,
      status: DeviceStatus.offline,
      cpuUsage: null,
      ramUsage: null,
      speedMbps: null,
      latencyMs: null,
      alertCount: 0,
      lastSeen: _now.subtract(const Duration(hours: 2)),
    ),
    Device(
      id: '5',
      name: 'Smart TV',
      ipAddress: '192.168.59.100',
      macAddress: 'AA:BB:CC:DD:EE:01',
      type: DeviceType.iot,
      coverage: DeviceCoverage.arpOnly,
      status: DeviceStatus.online,
      alertCount: 1,
      lastSeen: _now.subtract(const Duration(minutes: 1)),
    ),
    Device(
      id: '6',
      name: 'Unknown Device',
      ipAddress: '192.168.59.120',
      macAddress: 'AA:BB:CC:DD:EE:02',
      type: DeviceType.unknown,
      coverage: DeviceCoverage.arpOnly,
      status: DeviceStatus.online,
      alertCount: 3,
      lastSeen: _now.subtract(const Duration(minutes: 5)),
    ),
    Device(
      id: '7',
      name: 'Samsung S24',
      ipAddress: '192.168.59.130',
      macAddress: 'AA:BB:CC:DD:EE:03',
      type: DeviceType.phone,
      coverage: DeviceCoverage.arpOnly,
      status: DeviceStatus.online,
      alertCount: 0,
      lastSeen: _now.subtract(const Duration(seconds: 30)),
    ),
    Device(
      id: '8',
      name: 'iPhone 15',
      ipAddress: '192.168.59.131',
      macAddress: 'AA:BB:CC:DD:EE:04',
      type: DeviceType.phone,
      coverage: DeviceCoverage.arpOnly,
      status: DeviceStatus.online,
      alertCount: 0,
      lastSeen: _now.subtract(const Duration(minutes: 2)),
    ),
    Device(
      id: '9',
      name: 'Camera IP',
      ipAddress: '192.168.59.200',
      macAddress: 'AA:BB:CC:DD:EE:05',
      type: DeviceType.camera,
      coverage: DeviceCoverage.arpOnly,
      status: DeviceStatus.online,
      alertCount: 1,
      lastSeen: _now.subtract(const Duration(minutes: 1)),
    ),
    Device(
      id: '10',
      name: 'IoT Sensor',
      ipAddress: '192.168.59.210',
      macAddress: 'AA:BB:CC:DD:EE:06',
      type: DeviceType.iot,
      coverage: DeviceCoverage.withAgent,
      status: DeviceStatus.offline,
      alertCount: 0,
      lastSeen: _now.subtract(const Duration(hours: 5)),
    ),
  ];

  static List<Agent> get agents => [
    Agent(
      id: 'a1',
      hostname: 'PC-Admin',
      ipAddress: '192.168.59.255',
      macAddress: '00:1A:2B:3C:4D:5E',
      status: AgentStatus.active,
      cpuUsage: 55,
      ramUsage: 70,
      linkSpeedMbps: 200,
      lastHeartbeat: _now.subtract(const Duration(seconds: 5)),
    ),
    Agent(
      id: 'a2',
      hostname: 'Server-01',
      ipAddress: '192.168.59.10',
      macAddress: '00:1A:2B:3C:4D:AA',
      status: AgentStatus.active,
      cpuUsage: 45,
      ramUsage: 62,
      linkSpeedMbps: 940,
      lastHeartbeat: _now.subtract(const Duration(seconds: 5)),
    ),
    Agent(
      id: 'a3',
      hostname: 'WS-Lab03',
      ipAddress: '192.168.59.12',
      macAddress: '00:1A:2B:3C:5F:12',
      status: AgentStatus.active,
      cpuUsage: 23,
      ramUsage: 45,
      linkSpeedMbps: 240,
      lastHeartbeat: _now.subtract(const Duration(seconds: 10)),
    ),
    Agent(
      id: 'a4',
      hostname: 'Printer-HP',
      ipAddress: '192.168.59.50',
      macAddress: '00:1A:2B:AA:BB:CC',
      status: AgentStatus.inactive,
      cpuUsage: 0,
      ramUsage: 0,
      linkSpeedMbps: 0,
      lastHeartbeat: _now.subtract(const Duration(hours: 2)),
    ),
    Agent(
      id: 'a5',
      hostname: 'IoT-Sensor',
      ipAddress: '192.168.59.210',
      macAddress: 'AA:BB:CC:DD:EE:06',
      status: AgentStatus.inactive,
      cpuUsage: 0,
      ramUsage: 0,
      linkSpeedMbps: 0,
      lastHeartbeat: _now.subtract(const Duration(hours: 5)),
    ),
  ];

  static List<NetworkAlert> get alerts => [
    NetworkAlert(
      id: 'al1',
      title: 'High bandwidth consumption',
      description:
          'Smart TV is consuming 42.3 Mbps, significantly above the network average. This could indicate streaming or a potential data exfiltration.',
      severity: AlertSeverity.warning,
      deviceName: 'Smart TV',
      deviceIp: '192.168.59.100',
      timestamp: _now.subtract(const Duration(minutes: 5)),
    ),
    NetworkAlert(
      id: 'al2',
      title: 'Port scan detected',
      description:
          'Sequential port scanning activity detected from Unknown Device (192.168.59.120). 847 ports probed in 60 seconds.',
      severity: AlertSeverity.critical,
      deviceName: 'Unknown Device',
      deviceIp: '192.168.59.120',
      timestamp: _now.subtract(const Duration(minutes: 12)),
    ),
    NetworkAlert(
      id: 'al3',
      title: 'TCP retransmission spike',
      description:
          "Juan's MacBook experiencing 12.8 retransmissions/min. Peak at 10:44 AM with 1284 total retransmissions. Possible physical link issue.",
      severity: AlertSeverity.critical,
      deviceName: "Juan's MacBook",
      deviceIp: '192.168.59.255',
      timestamp: _now.subtract(const Duration(minutes: 20)),
    ),
    NetworkAlert(
      id: 'al4',
      title: 'New unknown device connected',
      description:
          'A device with MAC AA:BB:CC:DD:EE:02 connected to the network. No agent installed. Device type could not be determined.',
      severity: AlertSeverity.info,
      deviceName: 'Unknown Device',
      deviceIp: '192.168.59.120',
      timestamp: _now.subtract(const Duration(hours: 1)),
    ),
    NetworkAlert(
      id: 'al5',
      title: 'Agent heartbeat lost',
      description:
          'Printer-HP agent stopped reporting heartbeats 2 hours ago. Last known status: CPU 12%, RAM 34%.',
      severity: AlertSeverity.warning,
      deviceName: 'Printer HP',
      deviceIp: '192.168.59.50',
      timestamp: _now.subtract(const Duration(hours: 2)),
      isRead: true,
    ),
    NetworkAlert(
      id: 'al6',
      title: 'Unusual outbound connections',
      description:
          'Camera IP attempting connections to 14 unique external IPs in the last 5 minutes. Possible compromised firmware.',
      severity: AlertSeverity.critical,
      deviceName: 'Camera IP',
      deviceIp: '192.168.59.200',
      timestamp: _now.subtract(const Duration(hours: 3)),
      isRead: true,
    ),
  ];

  static List<TopConsumer> get topConsumers => [
    const TopConsumer(
      name: 'Smart TV',
      ip: '192.168.59.100',
      consumptionMbps: 42.3,
    ),
    const TopConsumer(
      name: "Juan's MacBook",
      ip: '192.168.59.255',
      consumptionMbps: 28.1,
    ),
    const TopConsumer(
      name: 'Server-01',
      ip: '192.168.59.10',
      consumptionMbps: 15.7,
    ),
    const TopConsumer(
      name: 'Laptop Dell',
      ip: '192.168.59.12',
      consumptionMbps: 8.4,
    ),
    const TopConsumer(
      name: 'Unknown Device',
      ip: '192.168.59.120',
      consumptionMbps: 5.2,
    ),
  ];

  static List<TimeSeriesPoint> generateTimeSeries({
    int points = 30,
    double baseValue = 30,
    double variance = 15,
    bool withSpike = false,
  }) {
    final rng = Random(42);
    final now = DateTime.now();
    return List.generate(points, (i) {
      double val = baseValue + (rng.nextDouble() - 0.5) * variance;
      if (withSpike && i > points * 0.6 && i < points * 0.75) {
        val = baseValue * 2.5 + rng.nextDouble() * baseValue;
      }
      return TimeSeriesPoint(
        time: now.subtract(Duration(minutes: (points - i) * 2)),
        value: val.clamp(0, double.infinity),
      );
    });
  }
}
