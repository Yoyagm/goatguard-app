import '../../failure.dart';
import '../../ports/auth_repository.dart';
import '../../ports/token_storage_port.dart';

class CompleteEnrollmentUseCase {
  final AuthRepository _authRepository;
  final TokenStoragePort _storage;

  CompleteEnrollmentUseCase(this._authRepository, this._storage);

  Future<Result<List<String>?>> call(String code) async {
    final result = await _authRepository.verifyTotpEnrollment(code);

    switch (result) {
      case Success(:final data):
        await _storage.write('jwt_token', data.token);
        return Success(data.backupCodes);
      case Err(:final failure):
        return Err(failure);
    }
  }
}
