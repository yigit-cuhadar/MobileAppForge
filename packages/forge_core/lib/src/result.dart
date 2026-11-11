import 'failure.dart';
import 'log.dart';

/// Outcome of a domain operation. Switch on [Ok] / [Err] or use [fold].
sealed class Result<T> {
  const Result();

  R fold<R>(R Function(T value) ok, R Function(Failure failure) err) =>
      switch (this) {
        Ok(:final value) => ok(value),
        Err(:final failure) => err(failure),
      };

  T? get valueOrNull => fold((v) => v, (_) => null);
  Failure? get failureOrNull => fold((_) => null, (f) => f);
  bool get isOk => this is Ok<T>;

  Result<R> map<R>(R Function(T value) transform) =>
      fold((v) => Ok(transform(v)), Err.new);
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

/// Maps a thrown object to a [Failure]; return null to fall through.
typedef FailureMapper = Failure? Function(Object error);

/// Runs [body] and converts anything it throws into an [Err].
///
/// Repositories wrap every data source call in this, so exceptions never
/// cross into the domain layer.
Future<Result<T>> guard<T>(
  Future<T> Function() body, {
  FailureMapper? mapper,
}) async {
  try {
    return Ok(await body());
  } catch (error, stack) {
    if (error is Failure) return Err(error);
    final failure = mapper?.call(error) ?? UnknownFailure('$error', error);
    Log.e('guard', failure.message, error, stack);
    return Err(failure);
  }
}
