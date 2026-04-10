import '../../failure.dart';
import '../../ports/auth_repository.dart';
import '../../ports/token_storage_port.dart';

class CompleteTotpUseCase {
  final AuthRepository _authRepository;
  final TokenStoragePort _storage;

  CompleteTotpUseCase(this._authRepository, this._storage);

  Future<Result<void>> call(String code) async {
    final result = await _authRepository.verifyTotp(code);

    switch (result) {
      case Success(:final data):
        await _storage.write('jwt_token', data.token);
        return const Success(null);
      case Err(:final failure):
        return Err(failure);
    }
  }
}
