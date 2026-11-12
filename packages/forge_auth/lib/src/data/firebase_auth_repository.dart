import 'package:firebase_auth/firebase_auth.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_firebase/forge_firebase.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository(this._auth);
  final FirebaseAuth _auth;

  /// Firebase codes meaning the linked credential belongs to another account.
  static const _accountExistsCodes = {
    'credential-already-in-use',
    'email-already-in-use',
  };

  @override
  Stream<AuthUser?> watchUser() => _auth.userChanges().map(_toUser);

  @override
  AuthUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Future<Result<AuthUser>> signInAnonymously() =>
      _credential(_auth.signInAnonymously);

  @override
  Future<Result<AuthUser>> signInWithEmail(String email, String password) =>
      _credential(
        () =>
            _auth.signInWithEmailAndPassword(email: email, password: password),
      );

  @override
  Future<Result<AuthUser>> signUpWithEmail(String email, String password) {
    final guest = _guest;
    return _credential(
      () => guest != null
          ? guest.linkWithCredential(
              EmailAuthProvider.credential(email: email, password: password),
            )
          : _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            ),
    );
  }

  @override
  Future<Result<AuthUser>> signInWithProvider(
    SocialProvider provider, {
    bool replaceGuest = false,
  }) {
    final authProvider = switch (provider) {
      SocialProvider.google => GoogleAuthProvider(),
      SocialProvider.apple => AppleAuthProvider(),
    };
    final guest = replaceGuest ? null : _guest;
    if (guest == null) {
      return _credential(() => _auth.signInWithProvider(authProvider));
    }
    return guard(
      () async => _toUser((await guest.linkWithProvider(authProvider)).user)!,
      mapper: (error) =>
          error is FirebaseAuthException &&
              _accountExistsCodes.contains(error.code)
          ? AuthFailure(
              error.message ?? error.code,
              code: accountExistsCode,
              cause: error,
            )
          : mapFirebaseError(error),
    );
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) => guard(
    () => _auth.sendPasswordResetEmail(email: email),
    mapper: mapFirebaseError,
  );

  @override
  Future<Result<void>> signOut() =>
      guard(_auth.signOut, mapper: mapFirebaseError);

  @override
  Future<Result<void>> deleteAccount() =>
      guard(() async => _auth.currentUser?.delete(), mapper: mapFirebaseError);

  @override
  Future<Result<void>> reauthenticate(String password) => guard(() async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AuthFailure('no email user signed in');
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );
  }, mapper: mapFirebaseError);

  User? get _guest {
    final user = _auth.currentUser;
    return user != null && user.isAnonymous ? user : null;
  }

  Future<Result<AuthUser>> _credential(
    Future<UserCredential> Function() signIn,
  ) => guard(
    () async => _toUser((await signIn()).user)!,
    mapper: mapFirebaseError,
  );

  static AuthUser? _toUser(User? user) => user == null
      ? null
      : AuthUser(
          id: user.uid,
          email: user.email,
          displayName: user.displayName,
          isAnonymous: user.isAnonymous,
        );
}
