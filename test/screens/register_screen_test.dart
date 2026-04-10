// C5: Widget tests para RegisterScreen [RF-16]
//
// Contrato: 3 campos (username, password, invitation token),
// boton registrar, validación de campos vacios.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goatguard_app/providers/auth_provider.dart';
import 'package:goatguard_app/services/api_service.dart';
import 'package:goatguard_app/screens/auth/register_screen.dart';

class _FakeApiService extends ApiService {
  _FakeApiService() : super(dio: Dio(BaseOptions(baseUrl: 'http://test')));

  Map<String, dynamic>? registerResponse;
  Exception? registerError;
  bool needsBootstrap = false;

  @override
  Future<Map<String, dynamic>> register(
    String username,
    String password, {
    String? invitationToken,
  }) async {
    if (registerError != null) throw registerError!;
    return registerResponse ?? {};
  }

  @override
  Future<Map<String, dynamic>> checkBootstrapStatus() async {
    return {'needs_bootstrap': needsBootstrap};
  }

  @override
  Future<Map<String, dynamic>> getAlertCount() async => {'count': 0};
}

void _mockStorage(Map<String, String?> store) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (MethodCall call) async {
      switch (call.method) {
        case 'read':
          return store[(call.arguments as Map)['key'] as String];
        case 'write':
          final args = call.arguments as Map;
          store[args['key'] as String] = args['value'] as String?;
          return null;
        case 'delete':
          store.remove((call.arguments as Map)['key'] as String);
          return null;
        default:
          return null;
      }
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeApiService fakeApi;
  late AuthProvider provider;
  late Map<String, String?> store;

  setUp(() {
    fakeApi = _FakeApiService();
    store = {};
    _mockStorage(store);
    provider = AuthProvider(fakeApi);
  });

  Widget buildApp() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          Provider<ApiService>.value(value: fakeApi),
        ],
        child: const RegisterScreen(),
      ),
    );
  }

  testWidgets('muestra 3 campos: username, password, invitation token',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsAtLeastNWidgets(3));
  });

  testWidgets('boton registrar deshabilitado con campos vacios',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final buttons = find.byType(ElevatedButton);
    expect(buttons, findsOneWidget);
    final button = tester.widget<ElevatedButton>(buttons);
    expect(button.onPressed, isNull);
  });

  testWidgets('modo bootstrap oculta campo invitation token', (tester) async {
    fakeApi.needsBootstrap = true;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Solo 2 campos: username y password (sin invitation)
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Crea la cuenta de administrador inicial'), findsOneWidget);
  });

  testWidgets('modo bootstrap permite registrar sin invitation', (tester) async {
    fakeApi.needsBootstrap = true;
    fakeApi.registerResponse = {
      'access_token': 'jwt-pending-totp',
      'username': 'admin',
      'recovery_code': 'ABCD-EFGH-IJKL-MNOP',
      'totp_uri': 'otpauth://totp/GOATGuard:admin?secret=BASE32',
      'qr_png_base64': 'iVBORw0KGgo=',
    };

    await tester.pumpWidget(MaterialApp(
      routes: {
        '/totp-enroll': (_) => const Scaffold(body: Text('ENROLL')),
      },
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          Provider<ApiService>.value(value: fakeApi),
        ],
        child: const RegisterScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'admin');
    await tester.enterText(fields.at(1), 'StrongPassword123!@#');
    await tester.pump();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('ABCD'), findsOneWidget);
  });

  testWidgets('registro exitoso muestra recovery code', (tester) async {
    fakeApi.registerResponse = {
      'access_token': 'jwt-pending-totp',
      'username': 'admin',
      'recovery_code': 'ABCD-EFGH-IJKL-MNOP',
      'totp_uri': 'otpauth://totp/GOATGuard:admin?secret=BASE32',
      'qr_png_base64': 'iVBORw0KGgo=',
    };

    await tester.pumpWidget(MaterialApp(
      routes: {
        '/totp-enroll': (_) => const Scaffold(body: Text('ENROLL')),
      },
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          Provider<ApiService>.value(value: fakeApi),
        ],
        child: const RegisterScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'admin');
    await tester.enterText(fields.at(1), 'StrongPassword123!@#');
    await tester.enterText(fields.at(2), 'inv-token-123');
    await tester.pump();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('ABCD'), findsOneWidget);
  });
}
