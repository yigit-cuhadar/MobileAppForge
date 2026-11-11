import 'result.dart';

/// One business action. Presentation depends on use cases, never repositories.
abstract interface class UseCase<T, P> {
  Future<Result<T>> call(P params);
}

/// Params type for use cases that take no input.
final class NoParams {
  const NoParams();
}
