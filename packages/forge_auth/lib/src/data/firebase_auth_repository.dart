import 'package:firebase_auth/firebase_auth.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_firebase/forge_firebase.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository(this._auth);
  final FirebaseAuth _auth;

  @override
  Stream<AuthUser?> watchUser() => _auth.userChanges().map(_toUser);

  @override
  Future<Result<AuthUser>> signInWithEmail(String email, String password) =>
      _credential(
        () =>
            _auth.signInWithEmailAndPassword(email: email, password: password),
      );

  @override
  Future<Result<AuthUser>> signUpWithEmail(String email, String password) =>
      _credential(
        () => _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      );

  @override
  Future<Result<AuthUser>> signInWithProvider(SocialProvider provider) =>
      _credential(
        () => _auth.signInWithProvider(switch (provider) {
          SocialProvider.google => GoogleAuthProvider(),
          SocialProvider.apple => AppleAuthProvider(),
        }),
      );

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
        );
}
