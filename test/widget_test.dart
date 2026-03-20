import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goatguard_app/main.dart';
import 'package:goatguard_app/services/api_service.dart';
import 'package:goatguard_app/services/websocket_service.dart';
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

    final api = ApiService();
    final ws = WebSocketService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(api)),
          ChangeNotifierProvider(create: (_) => DeviceProvider(api)),
          ChangeNotifierProvider(create: (_) => AlertProvider(api)),
          ChangeNotifierProvider(create: (_) => MetricsProvider(api, ws)),
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
