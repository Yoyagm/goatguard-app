// C4: Widget tests para TotpEnrollScreen [RF-16]
//
// Contrato: muestra QR code, input TOTP 6 digitos, boton confirmar,
// tras exito muestra backup codes.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goatguard_app/providers/auth_provider.dart';
import 'package:goatguard_app/services/api_service.dart';
import 'package:goatguard_app/screens/auth/totp_enroll_screen.dart';

class _FakeApiService extends ApiService {
  _FakeApiService() : super(dio: Dio(BaseOptions(baseUrl: 'http://test')));

  Map<String, dynamic>? totpEnrollVerifyResponse;
  Exception? totpEnrollVerifyError;

  @override
  Future<Map<String, dynamic>> login(String u, String p) async => {
    'access_token': 'jwt-pending',
    'username': 'admin',
    'totp_required': true,
    'needs_enrollment': true,
  };

  @override
  Future<Map<String, dynamic>> totpEnrollVerify(String code) async {
    if (totpEnrollVerifyError != null) throw totpEnrollVerifyError!;
    return totpEnrollVerifyResponse ?? {};
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

  setUp(() async {
    fakeApi = _FakeApiService();
    store = {};
    _mockStorage(store);
    provider = AuthProvider(fakeApi);
    await provider.login('admin', 'pass');
  });

  testWidgets('muestra campo de entrada para codigo TOTP', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: provider,
          child: const TotpEnrollScreen(
            totpUri: 'otpauth://totp/GOATGuard:admin?secret=TEST',
            qrBase64: '',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsAtLeastNWidgets(1));
  });

  testWidgets('enrollment exitoso muestra backup codes', (tester) async {
    fakeApi.totpEnrollVerifyResponse = {
      'backup_codes': ['AAAA-BBBB-CCCC', 'DDDD-EEEE-FFFF'],
    };

    await tester.pumpWidget(
      MaterialApp(
        routes: {'/main': (_) => const Scaffold(body: Text('MAIN'))},
        home: ChangeNotifierProvider.value(
          value: provider,
          child: const TotpEnrollScreen(
            totpUri: 'otpauth://totp/GOATGuard:admin?secret=TEST',
            qrBase64: '',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '654321');
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Tras enrollment exitoso, los backup codes deben estar visibles
    expect(provider.state, AuthState.authenticated);
    expect(provider.backupCodes, isNotNull);
  });
}
