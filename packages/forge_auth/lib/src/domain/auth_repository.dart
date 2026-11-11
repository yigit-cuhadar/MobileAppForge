import 'package:forge_core/forge_core.dart';

import 'auth_user.dart';

/// [AuthFailure.code] when a provider account cannot be linked to the guest
/// because it already exists.
const accountExistsCode = 'account-exists';

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

  /// Fails with [AuthFailure] code `requires-recent-login` when the session
  /// is too old; the user must sign in again first.
  Future<Result<void>> deleteAccount();
}
