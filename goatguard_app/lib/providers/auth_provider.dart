import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

/// Estado de autenticación [RF-13, RF-16]
enum AuthState {
  unknown,
  unauthenticated,
  pendingTotp, // Password OK, esperando código TOTP
  pendingEnrollment, // Recién registrado, debe escanear QR + verificar
  authenticated,
}

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthState _state = AuthState.unknown;
  String? _username;
  String? _error;

  // Datos mostrar-una-sola-vez (se limpian después de navegar)
  String? _pendingRecoveryCode;
  String? _pendingTotpUri;
  String? _pendingQrBase64;
  List<String>? _pendingBackupCodes;

  AuthProvider(this._api) {
    _api.onUnauthorized = () {
      _state = AuthState.unauthenticated;
      _api.clearCachedToken();
      _storage.delete(key: 'jwt_token');
      _storage.delete(key: 'pending_jwt_token');
      notifyListeners();
    };
  }

  AuthState get state => _state;
  String? get username => _username;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;

  String? get pendingRecoveryCode => _pendingRecoveryCode;
  String? get pendingTotpUri => _pendingTotpUri;
  String? get pendingQrBase64 => _pendingQrBase64;
  List<String>? get pendingBackupCodes => _pendingBackupCodes;

  /// Verificar si hay token guardado al iniciar la app
  Future<void> checkStoredToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      try {
        await _api.getAlertCount();
        _username = await _storage.read(key: 'username');
        _state = AuthState.authenticated;
      } on ApiException catch (e) {
        if (e.isUnauthorized) {
          await _storage.delete(key: 'jwt_token');
          _state = AuthState.unauthenticated;
        } else if (e.statusCode == 403) {
          // Token válido pero TOTP no verificado
          _username = await _storage.read(key: 'username');
          _state = AuthState.pendingTotp;
        } else {
          // Error de red — asumir token válido
          _username = await _storage.read(key: 'username');
          _state = AuthState.authenticated;
        }
      }
    } else {
      // Verificar si hay pending token (registro incompleto)
      final pendingToken = await _storage.read(key: 'pending_jwt_token');
      if (pendingToken != null) {
        _username = await _storage.read(key: 'username');
        _state = AuthState.pendingTotp;
      } else {
        _state = AuthState.unauthenticated;
      }
    }
    notifyListeners();
  }

  /// Login paso 1: credenciales [RF-16]
  Future<bool> login(String username, String password) async {
    _error = null;
    try {
      final data = await _api.login(username, password);
      final token = data['access_token'] as String;
      final totpRequired = data['totp_required'] as bool? ?? false;
      final needsEnrollment = data['needs_enrollment'] as bool? ?? false;

      _username = username;
      await _storage.write(key: 'username', value: username);

      if (totpRequired) {
        await _storage.write(key: 'pending_jwt_token', value: token);
        _state = needsEnrollment
            ? AuthState.pendingEnrollment
            : AuthState.pendingTotp;
      } else {
        await _storage.write(key: 'jwt_token', value: token);
        _state = AuthState.authenticated;
      }

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.statusCode == 401 ? 'Credenciales inválidas' : e.message;
      notifyListeners();
      return false;
    }
  }

  /// Registro con invitation token [RF-13]
  Future<bool> register(
    String username,
    String password,
    String invitationToken,
  ) async {
    _error = null;
    try {
      final data = await _api.register(username, password, invitationToken);

      final token = data['access_token'] as String;
      _username = data['username'] as String;
      _pendingRecoveryCode = data['recovery_code'] as String;
      _pendingTotpUri = data['totp_uri'] as String;
      _pendingQrBase64 = data['qr_png_base64'] as String;

      await _storage.write(key: 'pending_jwt_token', value: token);
      await _storage.write(key: 'username', value: _username!);

      _state = AuthState.pendingEnrollment;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Verificar TOTP durante enrollment (primera vez) [RF-13]
  Future<List<String>?> enrollTotp(String code) async {
    _error = null;
    try {
      final data = await _api.verifyTotpEnroll(code);
      final backupCodes = (data['backup_codes'] as List).cast<String>();
      _pendingBackupCodes = backupCodes;
      notifyListeners();
      return backupCodes;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  /// Verificar código TOTP durante login [RF-13]
  Future<bool> verifyTotp(String code) async {
    _error = null;
    try {
      final data = await _api.verifyTotp(code);
      final token = data['access_token'] as String;

      await _storage.write(key: 'jwt_token', value: token);
      await _storage.delete(key: 'pending_jwt_token');

      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Verificar backup code como alternativa a TOTP [RF-13]
  Future<bool> verifyBackupCode(String code) async {
    _error = null;
    try {
      final data = await _api.verifyBackupCode(code);
      final token = data['access_token'] as String;

      await _storage.write(key: 'jwt_token', value: token);
      await _storage.delete(key: 'pending_jwt_token');

      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Limpiar datos de TOTP post-enrollment
  void clearPendingTotpData() {
    _pendingRecoveryCode = null;
    _pendingTotpUri = null;
    _pendingQrBase64 = null;
  }

  /// Limpiar backup codes después de mostrarlos
  void clearBackupCodes() {
    _pendingBackupCodes = null;
  }

  /// Verificar recovery code — retorna reset_token [RF-13]
  Future<String?> verifyRecoveryCode(
    String username,
    String recoveryCode,
  ) async {
    _error = null;
    try {
      final data = await _api.verifyRecoveryCode(username, recoveryCode);
      return data['reset_token'] as String;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  /// Resetear contraseña con reset_token [RF-13]
  Future<bool> resetPassword(String resetToken, String newPassword) async {
    _error = null;
    try {
      final data = await _api.resetPassword(resetToken, newPassword);
      final token = data['access_token'] as String;

      await _storage.write(key: 'jwt_token', value: token);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _api.clearCachedToken();
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'pending_jwt_token');
    await _storage.delete(key: 'username');
    _username = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  /// Token actual para WebSocket
  Future<String?> getToken() => _storage.read(key: 'jwt_token');
}
