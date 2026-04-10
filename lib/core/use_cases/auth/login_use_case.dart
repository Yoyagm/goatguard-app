import '../../entities/auth_result.dart';
import '../../failure.dart';
import '../../ports/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  Future<Result<LoginResult>> call(String username, String password) {
    return _authRepository.login(username, password);
  }
}
