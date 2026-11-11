import 'package:firebase_core/firebase_core.dart';
import 'package:forge_core/forge_core.dart';

/// [FailureMapper] for Firebase SDK errors. Pass to `guard(mapper:)`.
Failure? mapFirebaseError(Object error) {
  if (error is! FirebaseException) return null;
  final message = error.message ?? error.code;
  if (error.plugin == 'firebase_auth') {
    return error.code == 'network-request-failed'
        ? NetworkFailure(message, error)
        : AuthFailure(message, code: error.code, cause: error);
  }
  return switch (error.code) {
    'unavailable' || 'deadline-exceeded' => NetworkFailure(message, error),
    'permission-denied' ||
    'unauthenticated' => PermissionFailure(message, error),
    'not-found' => NotFoundFailure(message, error),
    _ => UnknownFailure(message, error),
  };
}
