import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goatguard_app/main.dart';
import 'package:goatguard_app/di/injection_container.dart';
import 'package:goatguard_app/providers/auth_provider.dart';
import 'package:goatguard_app/providers/device_provider.dart';
import 'package:goatguard_app/providers/alert_provider.dart';
import 'package:goatguard_app/providers/metrics_provider.dart';

void main() {
  testWidgets('App launches and shows splash', (WidgetTester tester) async {
    // flutter_secure_storage usa platform channels; mockeamos para evitar
    // MissingPluginException en tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'read') return null;
            return null;
          },
        );

    final container = InjectionContainer()..init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              loginUseCase: container.loginUseCase,
              checkAuthUseCase: container.checkAuthUseCase,
              completeTotpUseCase: container.completeTotpUseCase,
              completeEnrollmentUseCase: container.completeEnrollmentUseCase,
              logoutUseCase: container.logoutUseCase,
              registerUseCase: container.registerUseCase,
              authRepository: container.authRepository,
              pushNotificationPort: container.pushNotificationPort,
              tokenStorage: container.tokenStorage,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => DeviceProvider(
              getDevicesUseCase: container.getDevicesUseCase,
              getAgentsUseCase: container.getAgentsUseCase,
              getDeviceDetailUseCase: container.getDeviceDetailUseCase,
              updateDeviceAliasUseCase: container.updateDeviceAliasUseCase,
              getDeviceHistoryUseCase: container.getDeviceHistoryUseCase,
              getDeviceConnectionsUseCase: container.getDeviceConnectionsUseCase,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => AlertProvider(
              getAlertsUseCase: container.getAlertsUseCase,
              getUnseenCountUseCase: container.getUnseenCountUseCase,
              markAlertSeenUseCase: container.markAlertSeenUseCase,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => MetricsProvider(
              apiService: container.apiService,
              getDashboardMetricsUseCase: container.getDashboardMetricsUseCase,
              getNetworkHistoryUseCase: container.getNetworkHistoryUseCase,
              getIspHealthUseCase: container.getIspHealthUseCase,
              getTrafficDistributionUseCase: container.getTrafficDistributionUseCase,
              getTopTalkersHistoryUseCase: container.getTopTalkersHistoryUseCase,
              getDashboardSummaryUseCase: container.getDashboardSummaryUseCase,
              getDeviceComparisonUseCase: container.getDeviceComparisonUseCase,
              networkRepository: container.networkRepository,
              realTimePort: container.realTimePort,
            ),
          ),
        ],
        child: const GoatGuardApp(),
      ),
    );

    expect(find.text('GOATGUARD'), findsOneWidget);
    expect(find.text('Network Monitoring System'), findsOneWidget);

    // Avanzar timers pendientes del SplashScreen
    await tester.pump(const Duration(seconds: 3));
  });
}
