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

/// Cliente HTTP centralizado con interceptor JWT [RF-13, RF-17]
class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  OnUnauthorized? onUnauthorized;

  // Cache en RAM para evitar lecturas a Keystore/Keychain en cada request
  String? _cachedToken;

  void setCachedToken(String? token) => _cachedToken = token;
  void clearCachedToken() => _cachedToken = null;

  ApiService({String? baseUrl}) {
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
    // Usar cache RAM primero, fallback a storage solo si no hay cache
    final token =
        _cachedToken ??
        await _storage.read(key: 'jwt_token') ??
        await _storage.read(key: 'pending_jwt_token');
    if (token != null) {
      _cachedToken = token;
      options.headers['Authorization'] = 'Bearer $token';
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
    String password,
    String invitationToken,
  ) async {
    return _request(
      () => _dio.post(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
          'invitation_token': invitationToken,
        },
      ),
    );
  }

  // ─── TOTP [RF-13] ─────────────────────────────────────────

  Future<Map<String, dynamic>> verifyTotpEnroll(String code) async {
    return _request(
      () => _dio.post('/auth/totp/enroll/verify', data: {'code': code}),
    );
  }

  Future<Map<String, dynamic>> verifyTotp(String code) async {
    return _request(() => _dio.post('/auth/totp/verify', data: {'code': code}));
  }

  Future<Map<String, dynamic>> verifyBackupCode(String backupCode) async {
    return _request(
      () => _dio.post(
        '/auth/totp/verify-backup',
        data: {'backup_code': backupCode},
      ),
    );
  }

  // ─── Recovery [RF-13] ──────────────────────────────────────

  Future<Map<String, dynamic>> verifyRecoveryCode(
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

  Future<Map<String, dynamic>> resetPassword(
    String resetToken,
    String newPassword,
  ) async {
    return _request(
      () => _dio.post(
        '/auth/recovery/reset-password',
        data: {'new_password': newPassword},
        options: Options(headers: {'Authorization': 'Bearer $resetToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> regenerateBackupCodes(
    String currentPassword,
  ) async {
    return _request(
      () => _dio.post(
        '/auth/totp/regenerate-backup-codes',
        data: {'current_password': currentPassword},
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
