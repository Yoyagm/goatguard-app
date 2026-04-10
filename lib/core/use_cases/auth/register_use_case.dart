import '../../failure.dart';
import '../../ports/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _authRepository;

  RegisterUseCase(this._authRepository);

  Future<Result<Map<String, dynamic>>> call(
    String username,
    String password, {
    String? invitationToken,
  }) {
    return _authRepository.register(
      username,
      password,
      invitationToken: invitationToken,
    );
  }
}
