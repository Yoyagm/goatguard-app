import '../../failure.dart';
import '../../ports/push_notification_port.dart';
import '../../ports/token_storage_port.dart';

class LogoutUseCase {
  final TokenStoragePort _storage;
  final PushNotificationPort _push;

  LogoutUseCase(this._storage, this._push);

  Future<Result<void>> call() async {
    try {
      await _push.unregisterToken();
      await _storage.delete('jwt_token');
      await _storage.delete('username');
      return const Success(null);
    } catch (e) {
      return Err(ServerFailure(message: e.toString()));
    }
  }
}
