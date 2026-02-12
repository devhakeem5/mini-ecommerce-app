abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Failed to load data from server']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = "Failed to load data from cache"]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No Internet Connection']);
}
