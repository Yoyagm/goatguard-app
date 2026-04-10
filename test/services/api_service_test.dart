import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goatguard_app/services/api_service.dart';

/// Interceptor de prueba: captura requests y devuelve respuestas configuradas.
/// Reemplaza la red real sin dependencias externas (mockito, http_mock_adapter).
class _MockInterceptor extends Interceptor {
  final List<RequestOptions> captured = [];
  int _statusCode = 200;
  dynamic _data;
  bool _shouldReject = false;
  bool _networkError = false;

  void respond(int statusCode, dynamic data) {
    _statusCode = statusCode;
    _data = data;
    _shouldReject = false;
    _networkError = false;
  }

  void rejectWith(int statusCode, dynamic data) {
    _statusCode = statusCode;
    _data = data;
    _shouldReject = true;
    _networkError = false;
  }

  void networkError() {
    _networkError = true;
    _shouldReject = false;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    captured.add(options);
    if (_networkError) {
      handler.reject(DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'Connection refused',
      ));
      return;
    }
    if (_shouldReject) {
      handler.reject(DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: _statusCode,
          data: {'detail': 'Error simulado'},
        ),
        type: DioExceptionType.badResponse,
      ));
      return;
    }
    handler.resolve(Response(
      requestOptions: options,
      statusCode: _statusCode,
      data: _data,
    ));
  }

  /// Ultimo request capturado.
  RequestOptions get lastRequest => captured.last;
}

void main() {
  late Dio dio;
  late _MockInterceptor mock;
  late ApiService api;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    mock = _MockInterceptor();
    dio.interceptors.clear();
    dio.interceptors.add(mock);
    // DI: inyectar Dio para testing (bypasea interceptor de storage)
    api = ApiService(dio: dio);
  });

  // ── register (actualizado con invitation_token) ───────────────────────

  group('register', () {
    test('envia invitation_token y retorna campos de enrollment', () async {
      mock.respond(201, {
        'access_token': 'jwt-pending-totp',
        'username': 'admin',
        'recovery_code': 'ABCD-EFGH-IJKL-MNOP',
        'totp_uri': 'otpauth://totp/GOATGuard:admin?secret=BASE32SECRET',
        'qr_png_base64': 'iVBORw0KGgo=',
      });

      final result = await api.register(
        'admin',
        'StrongPassword123!@#',
        invitationToken: 'inv-token-abc',
      );

      expect(result['access_token'], 'jwt-pending-totp');
      expect(result['recovery_code'], isNotEmpty);
      expect(result['qr_png_base64'], isNotEmpty);
      expect(result['totp_uri'], contains('otpauth://'));

      final req = mock.lastRequest;
      expect(req.method, 'POST');
      expect(req.path, '/auth/register');
      expect(req.data['invitation_token'], 'inv-token-abc');
      expect(req.data['username'], 'admin');
      expect(req.data['password'], 'StrongPassword123!@#');
    });

    test('lanza ApiException en 400 (token invalido)', () async {
      mock.rejectWith(400, {'detail': 'No se pudo completar el registro'});

      expect(
        () => api.register('admin', 'pass', invitationToken: 'bad-token'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
    });
  });

  // ── totpVerify (paso 2 login) ─────────────────────────────────────────

  group('totpVerify', () {
    test('envia codigo 6 digitos y retorna full_access token', () async {
      mock.respond(200, {
        'access_token': 'jwt-full-access',
        'token_type': 'bearer',
        'username': 'admin',
      });

      final result = await api.totpVerify('123456');

      expect(result['access_token'], 'jwt-full-access');
      expect(result['token_type'], 'bearer');

      final req = mock.lastRequest;
      expect(req.method, 'POST');
      expect(req.path, '/auth/totp/verify');
      expect(req.data['code'], '123456');
    });

    test('lanza ApiException en 401 (codigo invalido)', () async {
      mock.rejectWith(401, {'detail': 'Codigo TOTP invalido'});

      expect(
        () => api.totpVerify('000000'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });

    test('lanza ApiException en 429 (rate limit)', () async {
      mock.rejectWith(429, {'detail': 'Rate limit exceeded'});

      expect(
        () => api.totpVerify('123456'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            429,
          ),
        ),
      );
    });
  });

  // ── totpEnrollVerify (primer TOTP tras registro) ──────────────────────

  group('totpEnrollVerify', () {
    test('envia primer codigo y retorna backup codes', () async {
      mock.respond(200, {
        'backup_codes': [
          'AAAA-BBBB-CCCC',
          'DDDD-EEEE-FFFF',
          'GGGG-HHHH-IIII',
        ],
      });

      final result = await api.totpEnrollVerify('654321');

      expect(result['backup_codes'], isList);
      expect((result['backup_codes'] as List).length, 3);

      final req = mock.lastRequest;
      expect(req.method, 'POST');
      expect(req.path, '/auth/totp/enroll/verify');
      expect(req.data['code'], '654321');
    });

    test('lanza ApiException en 400 (ya enrollado)', () async {
      mock.rejectWith(400, {'detail': 'TOTP ya fue configurado'});

      expect(
        () => api.totpEnrollVerify('654321'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ── totpVerifyBackup (login con backup code) ──────────────────────────

  group('totpVerifyBackup', () {
    test('envia backup code y retorna full_access token', () async {
      mock.respond(200, {
        'access_token': 'jwt-full-via-backup',
        'token_type': 'bearer',
        'username': 'admin',
      });

      final result = await api.totpVerifyBackup('AAAA-BBBB-CCCC');

      expect(result['access_token'], 'jwt-full-via-backup');

      final req = mock.lastRequest;
      expect(req.method, 'POST');
      expect(req.path, '/auth/totp/verify-backup');
      expect(req.data['backup_code'], 'AAAA-BBBB-CCCC');
    });

    test('lanza ApiException en 401 (code usado o invalido)', () async {
      mock.rejectWith(401, {'detail': 'Codigo de respaldo invalido'});

      expect(
        () => api.totpVerifyBackup('USED-CODE-HERE'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });
  });

  // ── recoveryVerifyCode (verificar recovery code) ──────────────────────

  group('recoveryVerifyCode', () {
    test('envia username + recovery code y retorna reset_token', () async {
      mock.respond(200, {'reset_token': 'jwt-password-reset'});

      final result = await api.recoveryVerifyCode(
        'admin',
        'ABCD-EFGH-IJKL-MNOP',
      );

      expect(result['reset_token'], 'jwt-password-reset');

      final req = mock.lastRequest;
      expect(req.method, 'POST');
      expect(req.path, '/auth/recovery/verify-code');
      expect(req.data['username'], 'admin');
      expect(req.data['recovery_code'], 'ABCD-EFGH-IJKL-MNOP');
    });

    test('lanza ApiException en 429 (intentos excedidos)', () async {
      mock.rejectWith(429, {'detail': 'Codigo bloqueado por exceso de intentos'});

      expect(
        () => api.recoveryVerifyCode('admin', 'XXXX-XXXX-XXXX-XXXX'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            429,
          ),
        ),
      );
    });
  });

  // ── recoveryResetPassword (cambiar password con reset token) ──────────

  group('recoveryResetPassword', () {
    test('envia new_password con reset_token en header', () async {
      mock.respond(200, {
        'access_token': 'jwt-post-reset',
        'token_type': 'bearer',
        'username': 'admin',
      });

      final result = await api.recoveryResetPassword(
        'NewStrongPass456!@#',
        resetToken: 'jwt-password-reset',
      );

      expect(result['access_token'], 'jwt-post-reset');

      final req = mock.lastRequest;
      expect(req.method, 'POST');
      expect(req.path, '/auth/recovery/reset-password');
      expect(req.data['new_password'], 'NewStrongPass456!@#');
      // El reset_token va como Bearer, NO el token almacenado
      expect(
        req.headers['Authorization'],
        'Bearer jwt-password-reset',
      );
    });

    test('lanza ApiException en 401 (reset token expirado)', () async {
      mock.rejectWith(401, {'detail': 'Token de reset invalido'});

      expect(
        () => api.recoveryResetPassword(
          'NewPass',
          resetToken: 'expired-token',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });
  });

  // ── Error generico de red ─────────────────────────────────────────────

  group('errores de red', () {
    test('network error lanza ApiException con message descriptivo', () async {
      mock.networkError();

      expect(
        () => api.totpVerify('123456'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            isNull,
          ),
        ),
      );
    });
  });

  // ── login (ya existe pero verificar respuesta 2FA) ────────────────────

  group('login respuestas 2FA', () {
    test('login retorna totp_required y needs_enrollment', () async {
      mock.respond(200, {
        'access_token': 'jwt-pending',
        'username': 'admin',
        'totp_required': true,
        'needs_enrollment': false,
      });

      final result = await api.login('admin', 'password');

      expect(result['totp_required'], true);
      expect(result['needs_enrollment'], false);
      expect(result['access_token'], isNotEmpty);
    });
  });
}
