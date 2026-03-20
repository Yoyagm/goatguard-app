class AppConstants {
  static const String appName = 'GOATGuard';
  static const String appVersion = '1.0.0';

  // Metric thresholds
  static const double latencyGood = 50;
  static const double latencyWarning = 100;
  static const double latencyCritical = 200;

  static const double packetLossGood = 0.5;
  static const double packetLossWarning = 1.0;
  static const double packetLossCritical = 5.0;

  static const double jitterGood = 10;
  static const double jitterWarning = 30;
  static const double jitterCritical = 50;

  static const double dnsGood = 50;
  static const double dnsWarning = 100;
  static const double dnsCritical = 200;

  static const double cpuWarning = 70;
  static const double cpuCritical = 90;

  static const double ramWarning = 75;
  static const double ramCritical = 90;

  static const double healthGood = 80;
  static const double healthWarning = 60;
}
