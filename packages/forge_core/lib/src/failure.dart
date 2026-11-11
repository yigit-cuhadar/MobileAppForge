/// A domain-level error. Data sources throw; repositories return these.
sealed class Failure {
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

/// A store purchase that did not complete. Network problems are
/// [NetworkFailure], anything unrecognised is [UnknownFailure].
final class PurchaseFailure extends Failure {
  const PurchaseFailure(this.reason, [String? message, Object? cause])
    : super(message ?? 'Purchase failed', cause: cause);

  final PurchaseFailureReason reason;

  @override
  String toString() => 'PurchaseFailure(${reason.name}): $message';
}

enum PurchaseFailureReason {
  /// The user dismissed the store sheet; not an error to show.
  cancelled,

  /// Purchases are impossible here: store problem, restrictions or billing
  /// not set up on the device.
  storeUnavailable,
  productNotAvailable,
  alreadyOwned,

  /// Awaiting approval (Ask to Buy, pending payment); the entitlement arrives
  /// later through the entitlement stream.
  pending,
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
