abstract class Failure {
  const Failure(this.message);

  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network failure']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache failure']) : super(message);
}
