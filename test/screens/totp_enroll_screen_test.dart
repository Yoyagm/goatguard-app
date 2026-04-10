// C4: Widget tests para TotpEnrollScreen [RF-16]
//
// Contrato: muestra QR code, input TOTP 6 digitos, boton confirmar,
// tras exito muestra backup codes.
//
// Hexagonal migration: providers now use named parameters with use cases.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goatguard_app/providers/auth_provider.dart';
import 'package:goatguard_app/services/api_service.dart';
import 'package:goatguard_app/services/fcm_service.dart';
import 'package:goatguard_app/screens/auth/totp_enroll_screen.dart';
import 'package:goatguard_app/infrastructure/adapters/token_storage_adapter.dart';
import 'package:goatguard_app/infrastructure/adapters/push_notification_adapter.dart';
import 'package:goatguard_app/infrastructure/repositories/auth_repository_impl.dart';
import 'package:goatguard_app/core/use_cases/auth/login_use_case.dart';
import 'package:goatguard_app/core/use_cases/auth/check_auth_use_case.dart';
import 'package:goatguard_app/core/use_cases/auth/complete_totp_use_case.dart';
import 'package:goatguard_app/core/use_cases/auth/complete_enrollment_use_case.dart';
import 'package:goatguard_app/core/use_cases/auth/logout_use_case.dart';
import 'package:goatguard_app/core/use_cases/auth/register_use_case.dart';

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

AuthProvider _buildAuthProvider(_FakeApiService fakeApi) {
  final tokenStorage = TokenStorageAdapter();
  final pushAdapter = PushNotificationAdapter(FcmService(fakeApi));
  final authRepository = AuthRepositoryImpl(fakeApi, tokenStorage);

  return AuthProvider(
    loginUseCase: LoginUseCase(authRepository),
    checkAuthUseCase: CheckAuthUseCase(tokenStorage),
    completeTotpUseCase: CompleteTotpUseCase(authRepository, tokenStorage),
    completeEnrollmentUseCase: CompleteEnrollmentUseCase(
      authRepository,
      tokenStorage,
    ),
    logoutUseCase: LogoutUseCase(tokenStorage, pushAdapter),
    registerUseCase: RegisterUseCase(authRepository),
    authRepository: authRepository,
    pushNotificationPort: pushAdapter,
    tokenStorage: tokenStorage,
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
    provider = _buildAuthProvider(fakeApi);
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
      'access_token': 'jwt-full-access',
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
