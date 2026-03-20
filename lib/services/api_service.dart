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

  ApiService({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _attachToken,
      onError: _handleError,
    ));
  }

  Future<void> _attachToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
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
        message: e.response?.data?['detail']?.toString() ??
            e.message ??
            'Error de conexión',
      );
    }
  }

  // ─── Auth ───────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String username, String password) async {
    return _request(() => _dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    }));
  }

  Future<Map<String, dynamic>> register(String username, String password) async {
    return _request(() => _dio.post('/auth/register', data: {
      'username': username,
      'password': password,
    }));
  }

  // ─── Devices ────────────────────────────────────────────

  Future<List<dynamic>> getDevices() async {
    return _request(() => _dio.get('/devices/'));
  }

  Future<Map<String, dynamic>> getDevice(int id) async {
    return _request(() => _dio.get('/devices/$id'));
  }

  Future<void> updateAlias(int deviceId, String alias) async {
    await _request(() => _dio.patch('/devices/$deviceId/alias', data: {
      'alias': alias,
    }));
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

  // ─── WebSocket URL builder ──────────────────────────────

  String getWebSocketUrl(String token) {
    final wsBase = _dio.options.baseUrl.replaceFirst('http', 'ws');
    return '$wsBase/ws?token=$token';
  }
}
