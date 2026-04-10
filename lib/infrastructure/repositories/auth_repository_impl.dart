import '../../core/entities/auth_result.dart';
import '../../core/failure.dart';
import '../../core/ports/auth_repository.dart';
import '../../core/ports/token_storage_port.dart';
import '../../services/api_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiService _api;
  final TokenStoragePort _storage;

  AuthRepositoryImpl(this._api, this._storage);

  @override
  set onUnauthorized(void Function()? callback) {
    _api.onUnauthorized = callback;
  }

  @override
  Future<Result<LoginResult>> login(String username, String password) async {
    try {
      final data = await _api.login(username, password);
      final token = data['access_token'] as String;
      final totpRequired = data['totp_required'] as bool? ?? false;
      final needsEnrollment = data['needs_enrollment'] as bool? ?? false;

      await _storage.write('jwt_token', token);

      return Success(
        LoginResult(
          token: token,
          totpRequired: totpRequired,
          needsEnrollment: needsEnrollment,
        ),
      );
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }

  @override
  Future<Result<TotpResult>> verifyTotp(String code) async {
    try {
      final data = await _api.totpVerify(code);
      final token = data['access_token'] as String;

      await _storage.write('jwt_token', token);

      return Success(TotpResult(token: token));
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }

  @override
  Future<Result<TotpResult>> verifyTotpEnrollment(String code) async {
    try {
      final data = await _api.totpEnrollVerify(code);
      final token = data['access_token'] as String;
      final backupCodes = (data['backup_codes'] as List<dynamic>?)
          ?.map((c) => c.toString())
          .toList();

      await _storage.write('jwt_token', token);

      return Success(TotpResult(token: token, backupCodes: backupCodes));
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }

  @override
  Future<Result<TotpResult>> verifyBackupCode(String backupCode) async {
    try {
      final data = await _api.totpVerifyBackup(backupCode);
      final token = data['access_token'] as String;

      await _storage.write('jwt_token', token);

      return Success(TotpResult(token: token));
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> register(
    String username,
    String password, {
    String? invitationToken,
  }) async {
    try {
      final data = await _api.register(
        username,
        password,
        invitationToken: invitationToken,
      );
      return Success(data);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> checkBootstrapStatus() async {
    try {
      final data = await _api.checkBootstrapStatus();
      return Success(data);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> createInvitation() async {
    try {
      final data = await _api.createInvitation();
      return Success(data);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> recoveryVerifyCode(
    String username,
    String recoveryCode,
  ) async {
    try {
      final data = await _api.recoveryVerifyCode(username, recoveryCode);
      return Success(data);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }

  @override
  Future<Result<void>> recoveryResetPassword(
    String newPassword, {
    required String resetToken,
  }) async {
    try {
      await _api.recoveryResetPassword(newPassword, resetToken: resetToken);
      return const Success(null);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }
}
