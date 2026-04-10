// C3: Widget tests para TotpVerifyScreen [RF-16]
//
// Contrato: pantalla con input de 6 digitos, boton verificar,
// link a backup code, integración con AuthProvider.completeTotp().
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
import 'package:goatguard_app/screens/auth/totp_verify_screen.dart';
import 'package:goatguard_app/infrastructure/adapters/token_storage_adapter.dart';
import 'package:goatguard_app/infrastructure/adapters/push_notification_adapter.dart';
import 'package:goatguard_app/infrastructure/repositories/auth_repository_impl.dart';
import 'package:goatguard_app/core/use_cases/auth/login_use_case.dart';
import 'package:goatguard_app/core/use_cases/auth/check_auth_use_case.dart';
import 'package:goatguard_app/core/use_cases/auth/complete_totp_use_case.dart';
import 'package:goatguard_app/core/use_cases/auth/complete_enrollment_use_case.dart';
import 'package:goatguard_app/core/use_cases/auth/logout_use_case.dart';
import 'package:goatguard_app/core/use_cases/auth/register_use_case.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeApiService extends ApiService {
  _FakeApiService() : super(dio: Dio(BaseOptions(baseUrl: 'http://test')));

  Map<String, dynamic>? totpVerifyResponse;
  Exception? totpVerifyError;

  @override
  Future<Map<String, dynamic>> login(String u, String p) async => {
    'access_token': 'jwt-pending',
    'username': 'admin',
    'totp_required': true,
    'needs_enrollment': false,
  };

  @override
  Future<Map<String, dynamic>> totpVerify(String code) async {
    if (totpVerifyError != null) throw totpVerifyError!;
    return totpVerifyResponse ?? {};
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

Widget _buildTestApp(AuthProvider provider) {
  return MaterialApp(
    routes: {'/main': (_) => const Scaffold(body: Text('MAIN'))},
    home: ChangeNotifierProvider.value(
      value: provider,
      child: const TotpVerifyScreen(),
    ),
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
    // Llevar a pendingTotp
    await provider.login('admin', 'pass');
  });

  testWidgets('muestra campo de entrada para codigo TOTP de 6 digitos', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestApp(provider));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsAtLeastNWidgets(1));
  });

  testWidgets('boton verificar esta deshabilitado con menos de 6 digitos', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestApp(provider));
    await tester.pumpAndSettle();

    // Ingresar solo 3 digitos
    await tester.enterText(find.byType(TextField).first, '123');
    await tester.pump();

    // El boton debe estar deshabilitado
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('codigo valido de 6 digitos habilita el boton', (tester) async {
    await tester.pumpWidget(_buildTestApp(provider));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('verificacion exitosa navega fuera de la pantalla', (
    tester,
  ) async {
    fakeApi.totpVerifyResponse = {
      'access_token': 'jwt-full',
      'token_type': 'bearer',
      'username': 'admin',
    };

    await tester.pumpWidget(_buildTestApp(provider));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Debe haber navegado (ya no se ve TotpVerifyScreen)
    expect(provider.state, AuthState.authenticated);
  });
}
