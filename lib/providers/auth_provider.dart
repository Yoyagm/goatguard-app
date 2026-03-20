import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

/// Estado de autenticación [RF-13, RF-16]
enum AuthState { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthState _state = AuthState.unknown;
  String? _username;
  String? _error;

  AuthProvider(this._api) {
    // Redirigir a login si el server devuelve 401
    _api.onUnauthorized = () {
      _state = AuthState.unauthenticated;
      _storage.delete(key: 'jwt_token');
      notifyListeners();
    };
  }

  AuthState get state => _state;
  String? get username => _username;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;

  /// Verificar si hay token guardado al iniciar la app
  Future<void> checkStoredToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      // Validar haciendo una petición liviana
      try {
        await _api.getAlertCount();
        _username = await _storage.read(key: 'username');
        _state = AuthState.authenticated;
      } on ApiException catch (e) {
        if (e.isUnauthorized) {
          await _storage.delete(key: 'jwt_token');
          _state = AuthState.unauthenticated;
        } else {
          // Error de red — asumir que el token es válido
          _username = await _storage.read(key: 'username');
          _state = AuthState.authenticated;
        }
      }
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _error = null;
    try {
      final data = await _api.login(username, password);
      final token = data['access_token'] as String;
      await _storage.write(key: 'jwt_token', value: token);
      await _storage.write(key: 'username', value: username);
      _username = username;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.statusCode == 401 ? 'Credenciales inválidas' : e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'username');
    _username = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  /// Token actual para WebSocket
  Future<String?> getToken() => _storage.read(key: 'jwt_token');
}
