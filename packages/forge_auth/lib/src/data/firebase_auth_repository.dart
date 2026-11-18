import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_firebase/forge_firebase.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

/// Asks Apple for a credential natively, embedding the hashed `nonce` in
/// its identity token.
typedef AppleIdRequest = Future<AuthorizationCredentialAppleID> Function({
  required List<AppleIDAuthorizationScopes> scopes,
  String? nonce,
});

class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository(
    this._auth, {
    this._requestAppleId = SignInWithApple.getAppleIDCredential,
  });
  final FirebaseAuth _auth;
  final AppleIdRequest _requestAppleId;

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
    final authProvider = _authProvider(provider);
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
    final hasPassword =
        user?.providerData.any(
          (info) => info.providerId == EmailAuthProvider.PROVIDER_ID,
        ) ??
        false;
    if (user == null || email == null || !hasPassword) {
      throw const AuthFailure(
        'no email and password sign-in',
        code: noPasswordCode,
      );
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );
  }, mapper: mapFirebaseError);

  @override
  Future<Result<void>> reauthenticateWithProvider(SocialProvider provider) =>
      guard(() => _reauthenticate(provider), mapper: _reauthError);

  /// Apple's authorization code is single use, and the one FlutterFire's
  /// provider flow hands back is refused by the revocation endpoint. So this
  /// asks Apple natively for a fresh code and identity token, signs in again
  /// with the token and revokes with the unused code.
  @override
  Future<Result<void>> revokeAppleSignIn() => guard(() async {
    final user = _linkedUser(SocialProvider.apple);
    final rawNonce = _nonce();
    final apple = await _requestAppleId(
      scopes: const [],
      nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
    );
    final idToken = apple.identityToken;
    if (idToken == null) {
      throw const AuthFailure('no Apple identity token');
    }
    await user.reauthenticateWithCredential(
      OAuthProvider(AppleAuthProvider.PROVIDER_ID)
          .credential(idToken: idToken, rawNonce: rawNonce),
    );
    await _auth.revokeTokenWithAuthorizationCode(apple.authorizationCode);
  }, mapper: _reauthError);

  static String _nonce() {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        32,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<void> _reauthenticate(SocialProvider provider) async {
    await _linkedUser(provider)
        .reauthenticateWithProvider(_authProvider(provider));
  }

  User _linkedUser(SocialProvider provider) {
    final user = _auth.currentUser;
    final providerId = _authProvider(provider).providerId;
    final linked =
        user?.providerData.any((info) => info.providerId == providerId) ??
        false;
    if (user == null || !linked) {
      throw AuthFailure('${provider.name} not linked', code: notLinkedCode);
    }
    return user;
  }

  static Failure? _reauthError(Object error) => switch (error) {
    FirebaseAuthException(:final code, :final message)
        when _cancelledCodes.contains(code) =>
      AuthFailure(message ?? code, code: cancelledCode, cause: error),
    SignInWithAppleAuthorizationException(
      code: AuthorizationErrorCode.canceled,
      :final message,
    ) =>
      AuthFailure(message, code: cancelledCode, cause: error),
    _ => mapFirebaseError(error),
  };

  /// What Firebase reports when the user closes the provider's sheet, by
  /// platform and provider.
  static const _cancelledCodes = {
    'web-context-cancelled',
    'web-context-canceled',
    'canceled',
    'cancelled',
  };

  static AuthProvider _authProvider(SocialProvider provider) =>
      switch (provider) {
        SocialProvider.google => GoogleAuthProvider(),
        SocialProvider.apple => AppleAuthProvider(),
      };

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
          signInMethods: {
            for (final info in user.providerData) ?_methods[info.providerId],
          },
        );

  static final _methods = {
    EmailAuthProvider.PROVIDER_ID: SignInMethod.email,
    GoogleAuthProvider.PROVIDER_ID: SignInMethod.google,
    AppleAuthProvider.PROVIDER_ID: SignInMethod.apple,
  };
}
