import '../entities/auth_result.dart';
import '../failure.dart';

abstract class AuthRepository {
  Future<Result<LoginResult>> login(String username, String password);
  Future<Result<TotpResult>> verifyTotp(String code);
  Future<Result<TotpResult>> verifyTotpEnrollment(String code);
  Future<Result<TotpResult>> verifyBackupCode(String backupCode);
  Future<Result<Map<String, dynamic>>> register(
    String username,
    String password, {
    String? invitationToken,
  });
  Future<Result<Map<String, dynamic>>> checkBootstrapStatus();
  Future<Result<Map<String, dynamic>>> createInvitation();
  Future<Result<Map<String, dynamic>>> recoveryVerifyCode(
    String username,
    String recoveryCode,
  );
  Future<Result<void>> recoveryResetPassword(
    String newPassword, {
    required String resetToken,
  });

  /// Callback invoked when a 401 response is received from the server.
  set onUnauthorized(void Function()? callback);
}
