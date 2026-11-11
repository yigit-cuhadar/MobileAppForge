/// A domain-level error. Data sources throw; repositories return these.
abstract class Failure {
  const Failure(this.message, {this.cause});

  /// Developer-facing description. UI maps the failure *type* to user text.
  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network unavailable', Object? cause])
    : super(cause: cause);
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message, {this.code = 'unknown', super.cause});

  /// Provider error code, e.g. `wrong-password`, `email-already-in-use`.
  final String code;
}

final class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied', Object? cause])
    : super(cause: cause);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found', Object? cause])
    : super(cause: cause);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unexpected error', Object? cause])
    : super(cause: cause);
}
