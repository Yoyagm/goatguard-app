import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env.dart';

/// Excepción tipada para errores de API [RF-13]
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException({this.statusCode, required this.message});

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Callback para manejar expiración de JWT globalmente
typedef OnUnauthorized = void Function();

/// Cliente HTTP centralizado con interceptor JWT [RF-13, RF-16, RF-17]
class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  OnUnauthorized? onUnauthorized;

  /// [dio] permite inyectar un Dio pre-configurado para testing.
  /// En produccion se crea internamente con interceptor JWT.
  ApiService({String? baseUrl, Dio? dio}) {
    if (dio != null) {
      _dio = dio;
      return;
    }
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _attachToken, onError: _handleError),
    );
  }

  Future<void> _attachToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // No sobreescribir si el caller ya definio Authorization
    // (ej. recoveryResetPassword envia resetToken explicitamente)
    if (!options.headers.containsKey('Authorization')) {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  void _handleError(DioException error, ErrorInterceptorHandler handler) {
    if (error.response?.statusCode == 401) {
      onUnauthorized?.call();
    }
    handler.next(error);
  }

  /// Wrappea llamadas Dio → ApiException tipada
  Future<T> _request<T>(Future<Response<T>> Function() call) async {
    try {
      final response = await call();
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException(
        statusCode: e.response?.statusCode,
        message:
            e.response?.data?['detail']?.toString() ??
            e.message ??
            'Error de conexión',
      );
    }
  }

  // ─── Auth ───────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String username, String password) async {
    return _request(
      () => _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      ),
    );
  }

  Future<Map<String, dynamic>> register(
    String username,
    String password, {
    String? invitationToken,
  }) async {
    final data = <String, dynamic>{
      'username': username,
      'password': password,
    };
    if (invitationToken != null) {
      data['invitation_token'] = invitationToken;
    }
    return _request(
      () => _dio.post('/auth/register', data: data),
    );
  }

  /// Verifica si el sistema necesita bootstrap (0 usuarios en BD).
  /// Endpoint publico, no requiere JWT.
  Future<Map<String, dynamic>> checkBootstrapStatus() async {
    return _request(() => _dio.get('/auth/bootstrap-status'));
  }

  /// Genera un invitation token (requiere scope=full_access).
  Future<Map<String, dynamic>> createInvitation() async {
    return _request(() => _dio.post('/auth/invitations'));
  }

  // ─── TOTP 2FA [RF-16] ─────────────────────────────────────

  /// Paso 2 del login: verifica codigo TOTP de 6 digitos.
  /// Requiere JWT con scope=pending_totp en storage.
  Future<Map<String, dynamic>> totpVerify(String code) async {
    return _request(
      () => _dio.post('/auth/totp/verify', data: {'code': code}),
    );
  }

  /// Primer TOTP tras registro: confirma enrollment y retorna backup codes.
  /// Requiere JWT con scope=pending_totp en storage.
  Future<Map<String, dynamic>> totpEnrollVerify(String code) async {
    return _request(
      () => _dio.post('/auth/totp/enroll/verify', data: {'code': code}),
    );
  }

  /// Login alternativo con backup code cuando no se tiene acceso al TOTP.
  /// Requiere JWT con scope=pending_totp en storage.
  Future<Map<String, dynamic>> totpVerifyBackup(String backupCode) async {
    return _request(
      () => _dio.post(
        '/auth/totp/verify-backup',
        data: {'backup_code': backupCode},
      ),
    );
  }

  /// Verifica recovery code para iniciar reset de password.
  /// No requiere JWT previo — el usuario olvido credenciales.
  Future<Map<String, dynamic>> recoveryVerifyCode(
    String username,
    String recoveryCode,
  ) async {
    return _request(
      () => _dio.post(
        '/auth/recovery/verify-code',
        data: {'username': username, 'recovery_code': recoveryCode},
      ),
    );
  }

  /// Cambia password usando reset_token (scope=password_reset).
  /// El [resetToken] se envia como Bearer, NO el token almacenado.
  Future<Map<String, dynamic>> recoveryResetPassword(
    String newPassword, {
    required String resetToken,
  }) async {
    return _request(
      () => _dio.post(
        '/auth/recovery/reset-password',
        data: {'new_password': newPassword},
        options: Options(
          headers: {'Authorization': 'Bearer $resetToken'},
        ),
      ),
    );
  }

  // ─── Devices ────────────────────────────────────────────

  Future<List<dynamic>> getDevices() async {
    return _request(() => _dio.get('/devices/'));
  }

  Future<Map<String, dynamic>> getDevice(int id) async {
    return _request(() => _dio.get('/devices/$id'));
  }

  Future<void> updateAlias(int deviceId, String alias) async {
    await _request(
      () => _dio.patch('/devices/$deviceId/alias', data: {'alias': alias}),
    );
  }

  // ─── Network ────────────────────────────────────────────

  Future<Map<String, dynamic>> getNetworkMetrics() async {
    return _request(() => _dio.get('/network/metrics'));
  }

  Future<List<dynamic>> getTopTalkers() async {
    return _request(() => _dio.get('/network/top-talkers/'));
  }

  // ─── Alerts ─────────────────────────────────────────────

  Future<List<dynamic>> getAlerts({
    bool? seen,
    String? severity,
    int limit = 50,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (seen != null) params['seen'] = seen;
    if (severity != null) params['severity'] = severity;
    return _request(() => _dio.get('/alerts/', queryParameters: params));
  }

  Future<Map<String, dynamic>> getAlertCount() async {
    return _request(() => _dio.get('/alerts/count'));
  }

  Future<void> markAlertSeen(int alertId) async {
    await _request(() => _dio.patch('/alerts/$alertId/seen'));
  }

  // ─── Agents [RF-037] ─────────────────────────────────────

  Future<List<dynamic>> getAgents({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    return _request(() => _dio.get('/agents/', queryParameters: params));
  }

  // ─── Dashboard ─────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardSummary() async {
    return _request(() => _dio.get('/dashboard/summary'));
  }

  // ─── Network (history / ISP / traffic) ────────────────

  Future<List<dynamic>> getNetworkHistory({int hours = 4}) async {
    return _request(
      () => _dio.get('/network/history', queryParameters: {'hours': hours}),
    );
  }

  Future<Map<String, dynamic>> getIspHealth() async {
    return _request(() => _dio.get('/network/isp-health'));
  }

  Future<Map<String, dynamic>> getTrafficDistribution() async {
    return _request(() => _dio.get('/network/traffic-distribution'));
  }

  Future<List<dynamic>> getTopTalkersHistory({int hours = 4}) async {
    return _request(
      () => _dio.get(
        '/network/top-talkers/history',
        queryParameters: {'hours': hours},
      ),
    );
  }

  // ─── Devices (history / connections / comparison) ─────

  Future<List<dynamic>> getDeviceHistory(int deviceId, {int hours = 4}) async {
    return _request(
      () => _dio.get(
        '/devices/$deviceId/history',
        queryParameters: {'hours': hours},
      ),
    );
  }

  Future<List<dynamic>> getDeviceConnections(int deviceId) async {
    return _request(() => _dio.get('/devices/$deviceId/connections'));
  }

  Future<List<dynamic>> getDeviceComparison({
    String metric = 'bandwidth_in',
  }) async {
    return _request(
      () =>
          _dio.get('/devices/comparison', queryParameters: {'metric': metric}),
    );
  }

  // ─── WebSocket URL builder ──────────────────────────────

  String getWebSocketUrl(String token) {
    final wsBase = _dio.options.baseUrl.replaceFirst('http', 'ws');
    return '$wsBase/ws?token=$token';
  }
}
