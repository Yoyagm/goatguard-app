import 'package:flutter/foundation.dart';
import '../core/failure.dart';
import '../core/use_cases/auth/login_use_case.dart';
import '../core/use_cases/auth/check_auth_use_case.dart';
import '../core/use_cases/auth/complete_totp_use_case.dart';
import '../core/use_cases/auth/complete_enrollment_use_case.dart';
import '../core/use_cases/auth/logout_use_case.dart';
import '../core/use_cases/auth/register_use_case.dart';
import '../core/ports/auth_repository.dart';
import '../core/ports/push_notification_port.dart';
import '../core/ports/token_storage_port.dart';

/// Estado de autenticacion con soporte 2FA TOTP [RF-13, RF-16]
enum AuthState {
  unknown,
  unauthenticated,
  pendingTotp,
  pendingEnrollment,
  authenticated,
}

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final CheckAuthUseCase _checkAuthUseCase;
  final CompleteTotpUseCase _completeTotpUseCase;
  final CompleteEnrollmentUseCase _completeEnrollmentUseCase;
  final LogoutUseCase _logoutUseCase;
  final RegisterUseCase _registerUseCase;
  final AuthRepository _authRepository;
  final PushNotificationPort _pushNotificationPort;
  final TokenStoragePort _tokenStorage;

  AuthState _state = AuthState.unknown;
  String? _username;
  String? _error;
  List<String>? _backupCodes;

  AuthProvider({
    required LoginUseCase loginUseCase,
    required CheckAuthUseCase checkAuthUseCase,
    required CompleteTotpUseCase completeTotpUseCase,
    required CompleteEnrollmentUseCase completeEnrollmentUseCase,
    required LogoutUseCase logoutUseCase,
    required RegisterUseCase registerUseCase,
    required AuthRepository authRepository,
    required PushNotificationPort pushNotificationPort,
    required TokenStoragePort tokenStorage,
  })  : _loginUseCase = loginUseCase,
        _checkAuthUseCase = checkAuthUseCase,
        _completeTotpUseCase = completeTotpUseCase,
        _completeEnrollmentUseCase = completeEnrollmentUseCase,
        _logoutUseCase = logoutUseCase,
        _registerUseCase = registerUseCase,
        _authRepository = authRepository,
        _pushNotificationPort = pushNotificationPort,
        _tokenStorage = tokenStorage {
    _authRepository.onUnauthorized = () {
      _state = AuthState.unauthenticated;
      _backupCodes = null;
      _tokenStorage.delete('jwt_token');
      notifyListeners();
    };
  }

  AuthState get state => _state;
  String? get username => _username;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;
  List<String>? get backupCodes => _backupCodes;

  /// Expose push notification port for screen callbacks (FCM wiring).
  /// Replaces the old `fcmService` getter — same usage from screens.
  PushNotificationPort get fcmService => _pushNotificationPort;

  /// Limpia backup codes de memoria tras confirmar que el usuario los guardo.
  void clearBackupCodes() {
    _backupCodes = null;
  }

  // -- Restaurar sesion -------------------------------------------------------

  /// Restaura sesion al abrir la app [RF-16].
  /// Delega decodificacion JWT + validacion exp/scope al CheckAuthUseCase.
  Future<void> checkAuth() async {
    final result = await _checkAuthUseCase.call();

    switch (result) {
      case Success(:final data):
        _username = data.username;
        switch (data.status) {
          case AuthStatus.authenticated:
            _state = AuthState.authenticated;
            await _initializeFcm();
          case AuthStatus.pendingTotp:
            _state = AuthState.pendingTotp;
          case AuthStatus.pendingEnrollment:
            _state = AuthState.pendingEnrollment;
          case AuthStatus.unauthenticated:
            _state = AuthState.unauthenticated;
        }
      case Err(:final failure):
        debugPrint('checkAuth failed: ${failure.message}');
        _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  /// Alias para compatibilidad con splash_screen existente.
  Future<void> checkStoredToken() => checkAuth();

  // -- Login ------------------------------------------------------------------

  Future<bool> login(String username, String password) async {
    _error = null;
    final result = await _loginUseCase.call(username, password);

    switch (result) {
      case Success(:final data):
        await _tokenStorage.write('jwt_token', data.token);
        await _tokenStorage.write('username', username);
        _username = username;

        if (data.totpRequired && data.needsEnrollment) {
          _state = AuthState.pendingEnrollment;
        } else if (data.totpRequired) {
          _state = AuthState.pendingTotp;
        } else {
          _state = AuthState.authenticated;
        }
        notifyListeners();
        return true;

      case Err(:final failure):
        _error = failure.statusCode == 401
            ? 'Credenciales invalidas'
            : failure.message;
        _state = AuthState.unauthenticated;
        notifyListeners();
        return false;
    }
  }

  // -- TOTP 2FA [RF-16] ------------------------------------------------------

  /// Paso 2 del login: verificar codigo TOTP.
  /// No-op si el estado no es pendingTotp.
  Future<void> completeTotp(String code) async {
    if (_state != AuthState.pendingTotp) return;
    _error = null;

    final result = await _completeTotpUseCase.call(code);

    switch (result) {
      case Success():
        _state = AuthState.authenticated;
        notifyListeners();
      case Err(:final failure):
        _error = failure.message;
        notifyListeners();
    }
  }

  /// Confirmar primer TOTP tras registro.
  /// Almacena backup codes para mostrarlos al usuario una sola vez.
  /// No-op si el estado no es pendingEnrollment.
  Future<void> completeEnrollment(String code) async {
    if (_state != AuthState.pendingEnrollment) return;
    _error = null;

    final result = await _completeEnrollmentUseCase.call(code);

    switch (result) {
      case Success(:final data):
        _backupCodes = data;
        _state = AuthState.authenticated;
        notifyListeners();
      case Err(:final failure):
        _error = failure.message;
        notifyListeners();
    }
  }

  // -- Logout -----------------------------------------------------------------

  Future<void> logout() async {
    await _logoutUseCase.call();
    _username = null;
    _backupCodes = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  // -- FCM / Push Notifications -----------------------------------------------

  Future<void> _initializeFcm() async {
    try {
      await _pushNotificationPort.initialize();
      await _pushNotificationPort.registerToken();
    } catch (e) {
      debugPrint('FCM initialization failed: $e');
    }
  }

  /// Token actual para WebSocket
  Future<String?> getToken() => _tokenStorage.read('jwt_token');

  // -- Delegated methods (screens call these instead of ApiService) -----------

  /// Verifica si el sistema necesita bootstrap (0 usuarios en BD).
  Future<Result<Map<String, dynamic>>> checkBootstrapStatus() {
    return _authRepository.checkBootstrapStatus();
  }

  /// Registrar nuevo usuario.
  Future<Result<Map<String, dynamic>>> register(
    String username,
    String password, {
    String? invitationToken,
  }) {
    return _registerUseCase.call(
      username,
      password,
      invitationToken: invitationToken,
    );
  }

  /// Genera un invitation token (requiere scope=full_access).
  Future<Result<Map<String, dynamic>>> createInvitation() {
    return _authRepository.createInvitation();
  }

  /// Verifica recovery code para iniciar reset de password.
  Future<Result<Map<String, dynamic>>> recoveryVerifyCode(
    String username,
    String recoveryCode,
  ) {
    return _authRepository.recoveryVerifyCode(username, recoveryCode);
  }

  /// Cambia password usando reset_token.
  Future<Result<void>> recoveryResetPassword(
    String newPassword, {
    required String resetToken,
  }) {
    return _authRepository.recoveryResetPassword(
      newPassword,
      resetToken: resetToken,
    );
  }
}
