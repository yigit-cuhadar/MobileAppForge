import 'package:forge_core/forge_core.dart';

import 'auth_user.dart';

/// [AuthFailure.code] when a provider account cannot be linked to the guest
/// because it already exists.
const accountExistsCode = 'account-exists';

/// [AuthFailure.code] when [AuthRepository.reauthenticate] has no password
/// to check: nobody is signed in, or the user has no email and password
/// sign-in (a guest, or Google or Apple only).
const noPasswordCode = 'no-password';

abstract interface class AuthRepository {
  /// Emits the signed-in user, or null when signed out.
  Stream<AuthUser?> watchUser();

  AuthUser? get currentUser;

  /// Starts a guest session.
  Future<Result<AuthUser>> signInAnonymously();

  /// Replaces the current session, including a guest one; the caller confirms
  /// discarding a guest first.
  Future<Result<AuthUser>> signInWithEmail(String email, String password);

  /// Upgrades a guest in place (same uid) by linking the email; otherwise
  /// creates a new user.
  Future<Result<AuthUser>> signUpWithEmail(String email, String password);

  /// For a guest, links the provider unless [replaceGuest] is true. When the
  /// provider account already exists, fails with [accountExistsCode]
  /// and the caller may retry with [replaceGuest] to sign in to it instead.
  Future<Result<AuthUser>> signInWithProvider(
    SocialProvider provider, {
    bool replaceGuest = false,
  });

  Future<Result<void>> sendPasswordReset(String email);
  Future<Result<void>> signOut();

  /// Deletes the signed-in user. Fails with [AuthFailure] code
  /// `requires-recent-login` when Firebase finds the sign-in too old; a user
  /// with a password can renew it with [reauthenticate] and try again.
  Future<Result<void>> deleteAccount();

  /// Signs the signed-in user in again with their email and [password], so
  /// the sign-in is recent. Fails with [noPasswordCode] when nobody is
  /// signed in or the user has no email and password sign-in, and with
  /// Firebase's code (e.g. `invalid-credential`) for a wrong password.
  Future<Result<void>> reauthenticate(String password);
}
