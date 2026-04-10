// test/providers/auth_provider_test.dart
// Tests TDD RED para AuthProvider con 5 estados [RF-16]
//
// Hexagonal architecture migration: providers now receive use cases
// via named parameters instead of raw ApiService/FcmService.
//
// Strategy: _FakeApiService still stubs HTTP methods.
// We wire it through the real repository/use-case chain so that
// AuthProvider receives the same typed use cases as production.
// ignore_for_file: depend_on_referenced_packages

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goatguard_app/providers/auth_provider.dart';
import 'package:goatguard_app/services/api_service.dart';
import 'package:goatguard_app/services/fcm_service.dart';
import 'package:goatguard_app/infrastructure/adapters/token_storage_adapter.dart';
import 'package:goatguard_app/infrastructure/adapters/push_notification_adapter.dart';
import 'package:goatguard_app/infrastructure/repositories/auth_repository_impl.dart';
import 'package:goatguard_app/core/use_cases/auth/login_use_case.dart';
import 'package:goatguard_app/core/use_cases/auth/check_auth_use_case.dart';
import 'package:goatguard_app/core/use_cases/auth/complete_totp_use_case.dart';
import 'package:goatguard_app/core/use_cases/auth/complete_enrollment_use_case.dart';
import 'package:goatguard_app/core/use_cases/auth/logout_use_case.dart';
import 'package:goatguard_app/core/use_cases/auth/register_use_case.dart';

// ─── Infraestructura de fakes ─────────────────────────────────────────────────

/// Dio inerte: nunca hace peticiones reales.
/// ApiService necesita un Dio para construirse sin lanzar; este nunca se usa
/// porque _FakeApiService sobreescribe todos los métodos relevantes.
Dio _buildDummyDio() => Dio(BaseOptions(baseUrl: 'http://test-fake'));

/// Fake base: subclasea ApiService para poder sobreescribir métodos.
/// Cada test o grupo especializa según lo que necesite.
class _FakeApiService extends ApiService {
  _FakeApiService() : super(dio: _buildDummyDio());

  // Valores configurables por cada test
  Map<String, dynamic>? loginResponse;
  Map<String, dynamic>? totpVerifyResponse;
  Map<String, dynamic>? totpEnrollVerifyResponse;
  Exception? loginError;
  Exception? totpVerifyError;
  Exception? totpEnrollVerifyError;
  // Para simular getAlertCount (usado por checkStoredToken / checkAuth)
  Map<String, dynamic>? alertCountResponse;
  Exception? alertCountError;

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    if (loginError != null) throw loginError!;
    return loginResponse ?? {};
  }

  @override
  Future<Map<String, dynamic>> totpVerify(String code) async {
    if (totpVerifyError != null) throw totpVerifyError!;
    return totpVerifyResponse ?? {};
  }

  @override
  Future<Map<String, dynamic>> totpEnrollVerify(String code) async {
    if (totpEnrollVerifyError != null) throw totpEnrollVerifyError!;
    return totpEnrollVerifyResponse ?? {};
  }

  @override
  Future<Map<String, dynamic>> getAlertCount() async {
    if (alertCountError != null) throw alertCountError!;
    return alertCountResponse ?? {'count': 0};
  }
}

// ─── Helper: mock del platform channel de flutter_secure_storage ──────────────

/// Registra respuestas para los métodos read/write/delete del secure storage.
/// [store] es un mapa mutable que simula el almacenamiento en memoria.
void _mockSecureStorage(Map<String, String?> store) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall call) async {
          switch (call.method) {
            case 'read':
              final key = (call.arguments as Map)['key'] as String;
              return store[key];
            case 'write':
              final args = call.arguments as Map;
              store[args['key'] as String] = args['value'] as String?;
              return null;
            case 'delete':
              final key = (call.arguments as Map)['key'] as String;
              store.remove(key);
              return null;
            case 'deleteAll':
              store.clear();
              return null;
            default:
              return null;
          }
        },
      );
}

// ─── Helper: build AuthProvider wired through hexagonal layers ────────────────

/// Creates an AuthProvider with a _FakeApiService wired through the real
/// repository and use-case chain (same wiring as InjectionContainer).
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

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // Inicializar bindings una sola vez para todos los tests
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── Grupo 1: checkAuth() — transiciones desde unknown ──────────────────────
  //
  // checkAuth() es el método NUEVO que reemplaza/extiende checkStoredToken().
  // Lee el token del storage, decodifica el claim `scope` del JWT sin verificar
  // firma (solo payload base64), y transiciona al estado correspondiente.
  // RF-16: la app debe distinguir scope=full_access vs pending_totp al arrancar.

  group('checkAuth — transiciones desde unknown', () {
    late _FakeApiService fakeApi;
    late Map<String, String?> store;
    late AuthProvider provider;

    setUp(() {
      fakeApi = _FakeApiService();
      store = {};
      _mockSecureStorage(store);
      provider = _buildAuthProvider(fakeApi);
    });

    test(
      // Transición 1
      'unknown → authenticated: token full_access en storage sin error de API',
      () async {
        // Arrange: JWT con scope=full_access (payload decodificable sin firma)
        // eyJhbGciOiJIUzI1NiJ9 = {"alg":"HS256"}
        // eyJzdWIiOiJhZG1pbiIsInNjb3BlIjoiZnVsbF9hY2Nlc3MiLCJleHAiOjk5OTk5OTk5OTl9
        //   = {"sub":"admin","scope":"full_access","exp":9999999999}
        const tokenFullAccess =
            'eyJhbGciOiJIUzI1NiJ9'
            '.eyJzdWIiOiJhZG1pbiIsInNjb3BlIjoiZnVsbF9hY2Nlc3MiLCJleHAiOjk5OTk5OTk5OTl9'
            '.fake-sig';
        store['jwt_token'] = tokenFullAccess;
        store['username'] = 'admin';
        fakeApi.alertCountResponse = {'count': 0};

        // Act
        await provider.checkAuth();

        // Assert
        expect(
          provider.state,
          AuthState.authenticated,
          reason: 'Token full_access debe llevar a authenticated',
        );
      },
    );

    test(
      // Transición 2
      'unknown → pendingTotp: token totp_required en storage',
      () async {
        // Arrange: JWT con scope=totp_required (CheckAuthUseCase checks this value)
        // {"sub":"admin","scope":"totp_required","exp":9999999999}
        const tokenPendingTotp =
            'eyJhbGciOiJIUzI1NiJ9'
            '.eyJzdWIiOiJhZG1pbiIsInNjb3BlIjoidG90cF9yZXF1aXJlZCIsImV4cCI6OTk5OTk5OTk5OX0'
            '.fake-sig';
        store['jwt_token'] = tokenPendingTotp;
        store['username'] = 'admin';

        // Act
        await provider.checkAuth();

        // Assert
        expect(
          provider.state,
          AuthState.pendingTotp,
          reason:
              'Token totp_required debe llevar a pendingTotp sin llamar API',
        );
      },
    );

    test(
      // Transición 3
      'unknown → unauthenticated: sin token en storage',
      () async {
        // Arrange: storage vacío (store = {})

        // Act
        await provider.checkAuth();

        // Assert
        expect(provider.state, AuthState.unauthenticated);
      },
    );

    test(
      // Transición 4
      'unknown → unauthenticated: token expirado (exp < now)',
      () async {
        // Arrange: JWT con exp=1 (Unix epoch 1970-01-01T00:00:01Z, ya expirado)
        // {"sub":"admin","scope":"full_access","exp":1}
        const tokenExpired =
            'eyJhbGciOiJIUzI1NiJ9'
            '.eyJzdWIiOiJhZG1pbiIsInNjb3BlIjoiZnVsbF9hY2Nlc3MiLCJleHAiOjF9'
            '.fake-sig';
        store['jwt_token'] = tokenExpired;
        store['username'] = 'admin';

        // Act
        await provider.checkAuth();

        // Assert
        expect(
          provider.state,
          AuthState.unauthenticated,
          reason: 'Token expirado debe invalidar la sesión localmente',
        );
      },
    );
  });

  // ── Grupo 2: login() — transiciones desde unauthenticated ──────────────────
  //
  // RF-16: login() ahora debe inspeccionar totp_required y needs_enrollment
  // en la respuesta del servidor para decidir el estado destino.

  group('login — transiciones desde unauthenticated', () {
    late _FakeApiService fakeApi;
    late Map<String, String?> store;
    late AuthProvider provider;

    setUp(() {
      fakeApi = _FakeApiService();
      store = {};
      _mockSecureStorage(store);
      provider = _buildAuthProvider(fakeApi);
    });

    test(
      // Transición 5
      'unauthenticated → pendingTotp: server devuelve totp_required=true, needs_enrollment=false',
      () async {
        // Arrange
        fakeApi.loginResponse = {
          'access_token': 'jwt-pending-totp',
          'username': 'admin',
          'totp_required': true,
          'needs_enrollment': false,
        };

        // Act
        await provider.login('admin', 'correctPassword');

        // Assert
        expect(
          provider.state,
          AuthState.pendingTotp,
          reason: 'TOTP requerido y ya enrollado → pendingTotp',
        );
      },
    );

    test(
      // Transición 6
      'unauthenticated → pendingEnrollment: server devuelve totp_required=true, needs_enrollment=true',
      () async {
        // Arrange
        fakeApi.loginResponse = {
          'access_token': 'jwt-pending-enrollment',
          'username': 'admin',
          'totp_required': true,
          'needs_enrollment': true,
        };

        // Act
        await provider.login('admin', 'correctPassword');

        // Assert
        expect(
          provider.state,
          AuthState.pendingEnrollment,
          reason: 'TOTP requerido y sin enrollar → pendingEnrollment',
        );
      },
    );

    test(
      // Transición 7
      'unauthenticated → authenticated: server devuelve token sin totp_required (legacy)',
      () async {
        // Arrange
        fakeApi.loginResponse = {
          'access_token': 'jwt-full-access-legacy',
          'token_type': 'bearer',
          'username': 'admin',
          // totp_required ausente → false por defecto
        };

        // Act
        await provider.login('admin', 'correctPassword');

        // Assert
        expect(
          provider.state,
          AuthState.authenticated,
          reason: 'Login legacy sin 2FA → authenticated directamente',
        );
      },
    );

    test(
      'login falla con credenciales inválidas: estado permanece unauthenticated',
      () async {
        // Arrange
        fakeApi.loginError = const ApiException(
          statusCode: 401,
          message: 'Credenciales inválidas',
        );

        // Act
        final result = await provider.login('admin', 'wrongPassword');

        // Assert
        expect(result, false);
        expect(provider.state, AuthState.unauthenticated);
        expect(provider.error, isNotNull);
      },
    );
  });

  // ── Grupo 3: completeTotp() — transición pendingTotp → authenticated ────────
  //
  // RF-16: método nuevo que llama api.totpVerify(code), guarda el token
  // full_access y transiciona a authenticated.

  group('completeTotp — pendingTotp → authenticated', () {
    late _FakeApiService fakeApi;
    late Map<String, String?> store;
    late AuthProvider provider;

    setUp(() async {
      fakeApi = _FakeApiService();
      store = {};
      _mockSecureStorage(store);
      provider = _buildAuthProvider(fakeApi);

      // Llevar el provider a pendingTotp primero (Transición 5)
      fakeApi.loginResponse = {
        'access_token': 'jwt-pending-totp',
        'username': 'admin',
        'totp_required': true,
        'needs_enrollment': false,
      };
      await provider.login('admin', 'correctPassword');
      // Verificar precondición del arrange
      expect(provider.state, AuthState.pendingTotp);
    });

    test(
      // Transición 8
      'pendingTotp → authenticated: completeTotp() con código válido',
      () async {
        // Arrange
        fakeApi.totpVerifyResponse = {
          'access_token': 'jwt-full-access',
          'token_type': 'bearer',
          'username': 'admin',
        };

        // Act
        await provider.completeTotp('123456');

        // Assert
        expect(
          provider.state,
          AuthState.authenticated,
          reason: 'Código TOTP correcto → authenticated',
        );
      },
    );

    test(
      'completeTotp guarda el nuevo token full_access en secure storage',
      () async {
        // Arrange
        fakeApi.totpVerifyResponse = {
          'access_token': 'jwt-full-access-new',
          'token_type': 'bearer',
          'username': 'admin',
        };

        // Act
        await provider.completeTotp('123456');

        // Assert
        expect(
          store['jwt_token'],
          'jwt-full-access-new',
          reason: 'El token full_access debe reemplazar al pending en storage',
        );
      },
    );

    test(
      'completeTotp con código inválido: estado permanece en pendingTotp',
      () async {
        // Arrange
        fakeApi.totpVerifyError = const ApiException(
          statusCode: 401,
          message: 'Código TOTP inválido',
        );

        // Act
        await provider.completeTotp('000000');

        // Assert
        expect(
          provider.state,
          AuthState.pendingTotp,
          reason: 'Código incorrecto no debe abandonar pendingTotp',
        );
        expect(provider.error, isNotNull);
      },
    );
  });

  // ── Grupo 4: completeEnrollment() — pendingEnrollment → authenticated ────────
  //
  // RF-16: método nuevo que llama api.totpEnrollVerify(code), guarda backup codes
  // temporalmente en la propiedad backupCodes, y transiciona a authenticated.

  group('completeEnrollment — pendingEnrollment → authenticated', () {
    late _FakeApiService fakeApi;
    late Map<String, String?> store;
    late AuthProvider provider;

    setUp(() async {
      fakeApi = _FakeApiService();
      store = {};
      _mockSecureStorage(store);
      provider = _buildAuthProvider(fakeApi);

      // Llevar el provider a pendingEnrollment (Transición 6)
      fakeApi.loginResponse = {
        'access_token': 'jwt-pending-enrollment',
        'username': 'admin',
        'totp_required': true,
        'needs_enrollment': true,
      };
      await provider.login('admin', 'correctPassword');
      expect(provider.state, AuthState.pendingEnrollment);
    });

    test(
      // Transición 9
      'pendingEnrollment → authenticated: completeEnrollment() con código válido',
      () async {
        // Arrange
        fakeApi.totpEnrollVerifyResponse = {
          'access_token': 'jwt-full-access',
          'backup_codes': [
            'AAAA-BBBB-CCCC',
            'DDDD-EEEE-FFFF',
            'GGGG-HHHH-IIII',
          ],
        };

        // Act
        await provider.completeEnrollment('654321');

        // Assert
        expect(
          provider.state,
          AuthState.authenticated,
          reason: 'Primer código correcto completa el enrollment',
        );
      },
    );

    test(
      'completeEnrollment almacena backup codes en la propiedad del provider',
      () async {
        // Arrange
        const expectedCodes = ['AAAA-BBBB-CCCC', 'DDDD-EEEE-FFFF'];
        fakeApi.totpEnrollVerifyResponse = {
          'access_token': 'jwt-full-access',
          'backup_codes': expectedCodes,
        };

        // Act
        await provider.completeEnrollment('654321');

        // Assert
        expect(
          provider.backupCodes,
          expectedCodes,
          reason: 'backupCodes debe estar disponible para mostrar al usuario',
        );
      },
    );

    test(
      'completeEnrollment con código inválido: estado permanece en pendingEnrollment',
      () async {
        // Arrange
        fakeApi.totpEnrollVerifyError = const ApiException(
          statusCode: 400,
          message: 'Código incorrecto',
        );

        // Act
        await provider.completeEnrollment('999999');

        // Assert
        expect(provider.state, AuthState.pendingEnrollment);
        expect(provider.error, isNotNull);
      },
    );
  });

  // ── Grupo 5: logout() — authenticated → unauthenticated ────────────────────
  //
  // Este flujo ya existe pero debe seguir funcionando con 5 estados.
  // RF-16: logout limpia token, username y backupCodes del provider.

  group('logout — authenticated → unauthenticated', () {
    late _FakeApiService fakeApi;
    late Map<String, String?> store;
    late AuthProvider provider;

    setUp(() async {
      fakeApi = _FakeApiService();
      store = {};
      _mockSecureStorage(store);
      provider = _buildAuthProvider(fakeApi);

      // Llevar a authenticated via login legacy
      fakeApi.loginResponse = {
        'access_token': 'jwt-full-access-legacy',
        'token_type': 'bearer',
        'username': 'admin',
      };
      await provider.login('admin', 'correctPassword');
      expect(provider.state, AuthState.authenticated);
    });

    test(
      // Transición 10
      'authenticated → unauthenticated: logout limpia token de storage',
      () async {
        // Arrange: verificar que hay token antes
        expect(store['jwt_token'], isNotNull);

        // Act
        await provider.logout();

        // Assert
        expect(provider.state, AuthState.unauthenticated);
        expect(
          store['jwt_token'],
          isNull,
          reason: 'jwt_token debe borrarse del secure storage',
        );
        expect(store['username'], isNull);
      },
    );

    test(
      'logout limpia backupCodes si los había del enrollment previo',
      () async {
        // Act
        await provider.logout();

        // Assert: backupCodes debe ser null/vacío después de logout
        expect(
          provider.backupCodes,
          isNull,
          reason: 'backupCodes son sensibles y deben borrarse en logout',
        );
      },
    );
  });

  // ── Grupo 6: transiciones inválidas (no-ops) ────────────────────────────────
  //
  // RF-16: el provider debe ignorar operaciones que no corresponden al estado
  // actual. No deben lanzar excepción pero tampoco cambiar de estado.

  group('transiciones inválidas — deben ser no-ops', () {
    late _FakeApiService fakeApi;
    late Map<String, String?> store;
    late AuthProvider provider;

    setUp(() {
      fakeApi = _FakeApiService();
      store = {};
      _mockSecureStorage(store);
      provider = _buildAuthProvider(fakeApi);
    });

    test(
      // Transición 11 inválida
      'completeEnrollment desde unauthenticated: estado no cambia',
      () async {
        // Arrange: estado inicial es unknown → tras checkAuth sin token → unauthenticated
        await provider.checkAuth();
        expect(provider.state, AuthState.unauthenticated);

        // Act: intentar completeEnrollment sin haber pasado por login
        await provider.completeEnrollment('123456');

        // Assert
        expect(
          provider.state,
          AuthState.unauthenticated,
          reason:
              'completeEnrollment es no-op si no estamos en pendingEnrollment',
        );
      },
    );

    test(
      // Transición 12 inválida
      'completeTotp desde authenticated: estado no cambia',
      () async {
        // Arrange: llevar a authenticated
        fakeApi.loginResponse = {
          'access_token': 'jwt-full',
          'token_type': 'bearer',
          'username': 'admin',
        };
        await provider.login('admin', 'pass');
        expect(provider.state, AuthState.authenticated);

        // Act: intentar completeTotp ya estando autenticado
        await provider.completeTotp('123456');

        // Assert
        expect(
          provider.state,
          AuthState.authenticated,
          reason: 'completeTotp es no-op si no estamos en pendingTotp',
        );
      },
    );

    test(
      // Transición 13 inválida
      'completeEnrollment desde pendingTotp: no transiciona a pendingEnrollment',
      () async {
        // Arrange: llevar a pendingTotp
        fakeApi.loginResponse = {
          'access_token': 'jwt-pending-totp',
          'username': 'admin',
          'totp_required': true,
          'needs_enrollment': false,
        };
        await provider.login('admin', 'pass');
        expect(provider.state, AuthState.pendingTotp);

        // Act: intentar enrollment cuando estamos en pendingTotp
        await provider.completeEnrollment('123456');

        // Assert
        expect(
          provider.state,
          AuthState.pendingTotp,
          reason:
              'pendingTotp y pendingEnrollment son estados paralelos; '
              'completeEnrollment es no-op desde pendingTotp',
        );
      },
    );
  });

  // ── Grupo 7: edge cases realistas ─────────────────────────────────────────
  //
  // Escenarios que no están explícitamente en los RF pero son realistas
  // en producción.

  group('edge cases', () {
    late _FakeApiService fakeApi;
    late Map<String, String?> store;
    late AuthProvider provider;

    setUp(() {
      fakeApi = _FakeApiService();
      store = {};
      _mockSecureStorage(store);
      provider = _buildAuthProvider(fakeApi);
    });

    test(
      'checkAuth con token JWT malformado (no base64 válido): va a unauthenticated',
      () async {
        // Arrange: token que no es JWT válido
        store['jwt_token'] = 'esto-no-es-un-jwt';

        // Act
        await provider.checkAuth();

        // Assert: no debe lanzar, debe tratar como token inválido
        expect(
          provider.state,
          AuthState.unauthenticated,
          reason: 'JWT malformado debe tratarse como sesión inválida',
        );
      },
    );

    test(
      'checkAuth con token JWT sin claim scope: va a authenticated',
      () async {
        // Arrange: JWT válido en estructura pero sin campo scope
        // {"sub":"admin","exp":9999999999} — sin scope
        // CheckAuthUseCase treats missing/empty scope as authenticated
        // (absence of a restricting scope means full access).
        const tokenSinScope =
            'eyJhbGciOiJIUzI1NiJ9'
            '.eyJzdWIiOiJhZG1pbiIsImV4cCI6OTk5OTk5OTk5OX0'
            '.fake-sig';
        store['jwt_token'] = tokenSinScope;

        // Act
        await provider.checkAuth();

        // Assert
        expect(
          provider.state,
          AuthState.authenticated,
          reason: 'Sin scope claim = sin restricción TOTP → authenticated',
        );
      },
    );

    test('login exitoso expone username en provider', () async {
      // Arrange
      fakeApi.loginResponse = {
        'access_token': 'jwt-full',
        'token_type': 'bearer',
        'username': 'admin',
      };

      // Act
      await provider.login('admin', 'pass');

      // Assert
      expect(
        provider.username,
        'admin',
        reason: 'username debe estar disponible para la UI tras login',
      );
    });

    test(
      'error de red en completeTotp: estado no cambia y error expone mensaje',
      () async {
        // Arrange: llevar a pendingTotp
        fakeApi.loginResponse = {
          'access_token': 'jwt-pending',
          'username': 'admin',
          'totp_required': true,
          'needs_enrollment': false,
        };
        await provider.login('admin', 'pass');
        fakeApi.totpVerifyError = const ApiException(
          statusCode: null,
          message: 'Error de conexión',
        );

        // Act
        await provider.completeTotp('123456');

        // Assert
        expect(
          provider.state,
          AuthState.pendingTotp,
          reason: 'Error de red no debe abandonar pendingTotp',
        );
        expect(
          provider.error,
          contains('conexión'),
          reason: 'El mensaje de error debe ser descriptivo para la UI',
        );
      },
    );

    test('notifyListeners se llama tras cada transición de estado', () async {
      // Arrange: escuchar notificaciones
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      fakeApi.loginResponse = {
        'access_token': 'jwt-pending-totp',
        'username': 'admin',
        'totp_required': true,
        'needs_enrollment': false,
      };

      // Act: login → pendingTotp
      await provider.login('admin', 'pass');

      // Assert
      expect(
        notifyCount,
        greaterThanOrEqualTo(1),
        reason: 'Cada cambio de estado debe notificar a los listeners',
      );
    });
  });
}
