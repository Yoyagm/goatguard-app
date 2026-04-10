import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';

/// Estado de autenticación con soporte 2FA TOTP [RF-13, RF-16]
enum AuthState {
  unknown,
  unauthenticated,
  pendingTotp,
  pendingEnrollment,
  authenticated,
}

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final FcmService _fcm;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthState _state = AuthState.unknown;
  String? _username;
  String? _error;
  List<String>? _backupCodes;

  AuthProvider(this._api, this._fcm) {
    _api.onUnauthorized = () {
      _state = AuthState.unauthenticated;
      _backupCodes = null;
      _storage.delete(key: 'jwt_token');
      notifyListeners();
    };
  }

  AuthState get state => _state;
  String? get username => _username;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;
  List<String>? get backupCodes => _backupCodes;
  FcmService get fcmService => _fcm;

  /// Limpia backup codes de memoria tras confirmar que el usuario los guardó.
  void clearBackupCodes() {
    _backupCodes = null;
  }

  // ── JWT decode local (sin verificar firma) ──────────────────────────────

  /// Decodifica el payload del JWT leyendo solo el segmento base64.
  /// No verifica firma — solo extrae claims (scope, exp) para decidir
  /// estado local. La firma se valida server-side en cada request.
  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Valida exp contra reloj local. Retorna true si el token ya expiró.
  bool _isTokenExpired(Map<String, dynamic> payload) {
    final exp = payload['exp'];
    if (exp == null) return true;
    final expSeconds = (exp is int) ? exp : (exp as num).toInt();
    if (expSeconds <= 0) return true;
    final expDate = DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000);
    return DateTime.now().isAfter(expDate);
  }

  // ── Restaurar sesión ────────────────────────────────────────────────────

  /// Restaura sesión al abrir la app [RF-16].
  /// Lee el JWT del storage, decodifica scope/exp sin llamar al server.
  /// Transiciona a: authenticated (full_access), pendingTotp (pending_totp),
  /// o unauthenticated (sin token, expirado, malformado, sin scope).
  Future<void> checkAuth() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }

    final payload = _decodeJwtPayload(token);
    if (payload == null) {
      await _storage.delete(key: 'jwt_token');
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }

    if (_isTokenExpired(payload)) {
      await _storage.delete(key: 'jwt_token');
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }

    final scope = payload['scope'] as String?;
    _username = await _storage.read(key: 'username');

    switch (scope) {
      case 'full_access':
        _state = AuthState.authenticated;
        await _initializeFcm();
      case 'pending_totp':
        _state = AuthState.pendingTotp;
      default:
        // Scope desconocido o ausente — sesión inválida
        await _storage.delete(key: 'jwt_token');
        _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  /// Alias para compatibilidad con splash_screen existente.
  Future<void> checkStoredToken() => checkAuth();

  // ── Login ───────────────────────────────────────────────────────────────

  Future<bool> login(String username, String password) async {
    _error = null;
    try {
      final data = await _api.login(username, password);
      final token = data['access_token'] as String;
      await _storage.write(key: 'jwt_token', value: token);
      await _storage.write(key: 'username', value: username);
      _username = username;

      // Inspeccionar respuesta 2FA del server
      final totpRequired = data['totp_required'] as bool? ?? false;
      final needsEnrollment = data['needs_enrollment'] as bool? ?? false;

      if (totpRequired && needsEnrollment) {
        _state = AuthState.pendingEnrollment;
      } else if (totpRequired) {
        _state = AuthState.pendingTotp;
      } else {
        _state = AuthState.authenticated;
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.statusCode == 401 ? 'Credenciales inválidas' : e.message;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ── TOTP 2FA [RF-16] ───────────────────────────────────────────────────

  /// Paso 2 del login: verificar código TOTP.
  /// No-op si el estado no es pendingTotp.
  Future<void> completeTotp(String code) async {
    if (_state != AuthState.pendingTotp) return;
    _error = null;
    try {
      final data = await _api.totpVerify(code);
      final token = data['access_token'] as String;
      await _storage.write(key: 'jwt_token', value: token);
      _state = AuthState.authenticated;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  /// Confirmar primer TOTP tras registro.
  /// Almacena backup codes para mostrarlos al usuario una sola vez.
  /// No-op si el estado no es pendingEnrollment.
  Future<void> completeEnrollment(String code) async {
    if (_state != AuthState.pendingEnrollment) return;
    _error = null;
    try {
      final data = await _api.totpEnrollVerify(code);
      final codes = (data['backup_codes'] as List?)?.cast<String>();
      _backupCodes = codes;
      // Guardar access_token si el server lo incluye en la respuesta
      final token = data['access_token'] as String?;
      if (token != null) {
        await _storage.write(key: 'jwt_token', value: token);
      }
      _state = AuthState.authenticated;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _fcm.unregisterToken();
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'username');
    _username = null;
    _backupCodes = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  // ── FCM ─────────────────────────────────────────────────────────────────

  Future<void> _initializeFcm() async {
    try {
      await _fcm.initialize();
      await _fcm.registerToken();
    } catch (e) {
      debugPrint('FCM initialization failed: $e');
    }
  }

  /// Token actual para WebSocket
  Future<String?> getToken() => _storage.read(key: 'jwt_token');
}
