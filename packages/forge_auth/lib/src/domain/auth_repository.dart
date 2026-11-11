import 'package:forge_core/forge_core.dart';

import 'auth_user.dart';

abstract interface class AuthRepository {
  /// Emits the signed-in user, or null when signed out.
  Stream<AuthUser?> watchUser();

  Future<Result<AuthUser>> signInWithEmail(String email, String password);
  Future<Result<AuthUser>> signUpWithEmail(String email, String password);
  Future<Result<AuthUser>> signInWithProvider(SocialProvider provider);
  Future<Result<void>> sendPasswordReset(String email);
  Future<Result<void>> signOut();

  /// Fails with [AuthFailure] code `requires-recent-login` when the session
  /// is too old; the user must sign in again first.
  Future<Result<void>> deleteAccount();
}
