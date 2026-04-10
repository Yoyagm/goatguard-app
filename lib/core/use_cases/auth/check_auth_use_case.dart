import 'dart:convert';

import '../../failure.dart';
import '../../ports/token_storage_port.dart';

enum AuthStatus {
  authenticated,
  pendingTotp,
  pendingEnrollment,
  unauthenticated,
}

class CheckAuthResult {
  final AuthStatus status;
  final String? username;

  const CheckAuthResult({required this.status, this.username});
}

class CheckAuthUseCase {
  final TokenStoragePort _storage;

  CheckAuthUseCase(this._storage);

  Future<Result<CheckAuthResult>> call() async {
    try {
      final token = await _storage.read('jwt_token');
      final username = await _storage.read('username');

      if (token == null) {
        return const Success(
          CheckAuthResult(status: AuthStatus.unauthenticated),
        );
      }

      final payload = _decodePayload(token);
      if (payload == null || _isExpired(payload)) {
        return Success(
          CheckAuthResult(
            status: AuthStatus.unauthenticated,
            username: username,
          ),
        );
      }

      final scope = payload['scope'] as String? ?? '';

      if (scope == 'totp_required') {
        return Success(
          CheckAuthResult(status: AuthStatus.pendingTotp, username: username),
        );
      }

      if (scope == 'totp_enrollment') {
        return Success(
          CheckAuthResult(
            status: AuthStatus.pendingEnrollment,
            username: username,
          ),
        );
      }

      return Success(
        CheckAuthResult(status: AuthStatus.authenticated, username: username),
      );
    } catch (e) {
      return Err(ServerFailure(message: e.toString()));
    }
  }

  Map<String, dynamic>? _decodePayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  bool _isExpired(Map<String, dynamic> payload) {
    final exp = payload['exp'];
    if (exp == null) return true;
    final expDate = DateTime.fromMillisecondsSinceEpoch(
      (exp as num).toInt() * 1000,
    );
    return DateTime.now().isAfter(expDate);
  }
}
