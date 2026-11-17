import 'package:forge_core/forge_core.dart';

enum AuthFailureField { email, password }

/// The email form field a failure is shown under, or null when it belongs
/// to none (no connection, too many attempts) and shows as a snackbar.
AuthFailureField? failureField(Failure failure) => switch (failure) {
  AuthFailure(code: 'email-already-in-use' || 'invalid-email') =>
    AuthFailureField.email,
  AuthFailure(
    code: 'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'weak-password',
  ) =>
    AuthFailureField.password,
  _ => null,
};
