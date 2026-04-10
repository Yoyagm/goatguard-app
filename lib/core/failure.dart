sealed class Failure {
  String get message;
  int? get statusCode => null;
}

class ServerFailure extends Failure {
  @override
  final String message;
  @override
  final int? statusCode;

  ServerFailure({required this.message, this.statusCode});
}

class NetworkFailure extends Failure {
  @override
  String get message => 'Sin conexión a la red';
}

class UnauthorizedFailure extends Failure {
  @override
  String get message => 'Sesión expirada';
}

/// Sealed result type: Success or Err.
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}
