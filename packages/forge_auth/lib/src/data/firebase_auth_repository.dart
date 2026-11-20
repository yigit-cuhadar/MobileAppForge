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
  FirebaseAuthRepository(
    this._auth, {
    this._requestAppleId = SignInWithApple.getAppleIDCredential,
  });
  final FirebaseAuth _auth;
  final AppleIdRequest _requestAppleId;

  /// The password of this session's last email sign-in, sign-up or
  /// re-authentication, in memory only: changing the email may need a
  /// recent sign-in, and confirming the change ends the session.
  String? _password;

  /// The address [changeEmail] sent its link to, until the session ends.
  String? _pendingEmail;

  @override
  DateTime? verificationSentAt;

  static const _recentLoginCode = 'requires-recent-login';

  /// Firebase codes meaning the linked credential belongs to another account.
  static const _accountExistsCodes = {
    'credential-already-in-use',
    'email-already-in-use',
  };

  @override
  Stream<AuthUser?> watchUser() => _auth.userChanges().map(_toUser);

  @override
  AuthUser? get currentUser => _toUser(_auth.currentUser);

  /// Confirming an email change revokes the session, so Firebase signs the
  /// user out. While the new address and the password are known, this
  /// signs in to the account again instead of starting a stranger guest.
  @override
  Future<Result<AuthUser>> signInAnonymously() async {
    final (email, password) = (_pendingEmail, _password);
    _pendingEmail = null;
    if (email != null && password != null) {
      final account = await signInWithEmail(email, password);
      if (account.isOk) return account;
    }
    _password = null;
    return _credential(_auth.signInAnonymously);
  }

  @override
  Future<Result<AuthUser>> signInWithEmail(
    String email,
    String password,
  ) async {
    final result = await _credential(
      () => _auth.signInWithEmailAndPassword(email: email, password: password),
    );
    if (result.isOk) _password = password;
    return result;
  }

  @override
  Future<Result<AuthUser>> signUpWithEmail(
    String email,
    String password,
  ) async {
    final guest = _guest;
    final result = await _credential(
      () => guest != null
          ? guest.linkWithCredential(
              EmailAuthProvider.credential(email: email, password: password),
            )
          : _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            ),
    );
    if (result.isOk) _password = password;
    return result;
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
  Future<Result<void>> sendEmailVerification() => guard(() async {
    await _signedIn.sendEmailVerification();
    verificationSentAt = DateTime.now();
  }, mapper: mapFirebaseError);

  @override
  Future<Result<void>> changeEmail(String email) => guard(() async {
    final user = _signedIn;
    try {
      await user.verifyBeforeUpdateEmail(email);
    } on FirebaseAuthException catch (error) {
      if (error.code != _recentLoginCode) rethrow;
      await _renewSignIn(user, error);
      await user.verifyBeforeUpdateEmail(email);
    }
    _pendingEmail = email;
    verificationSentAt = DateTime.now();
  }, mapper: mapFirebaseError);

  /// Signs [user] in again with this session's password, or rethrows
  /// [tooOld] when there is none or it no longer fits.
  Future<void> _renewSignIn(User user, FirebaseAuthException tooOld) async {
    final (email, password) = (user.email, _password);
    if (email == null || password == null) throw tooOld;
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } on FirebaseAuthException {
      throw tooOld;
    }
  }

  @override
  Future<Result<AuthUser>> reloadUser() => guard(() async {
    await _signedIn.reload();
    return _toUser(_auth.currentUser)!;
  }, mapper: mapFirebaseError);

  @override
  Future<Result<void>> signOut() => guard(() async {
    _forgetSession();
    await _auth.signOut();
  }, mapper: mapFirebaseError);

  @override
  Future<Result<void>> deleteAccount() => guard(() async {
    await _auth.currentUser?.delete();
    _forgetSession();
  }, mapper: mapFirebaseError);

  void _forgetSession() {
    _password = null;
    _pendingEmail = null;
    verificationSentAt = null;
  }

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
    _password = password;
  }, mapper: mapFirebaseError);

  @override
  Future<Result<void>> reauthenticateWithProvider(SocialProvider provider) =>
      guard(() => _reauthenticate(provider), mapper: _reauthError);

  /// Apple's authorization code is single use, so this asks Apple natively
  /// for a fresh code and identity token, signs in again with the token and
  /// hands back the unused code.
  @override
  Future<Result<String>> reauthenticateWithAppleCode() => guard(() async {
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
    return apple.authorizationCode;
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

  User get _signedIn =>
      _auth.currentUser ?? (throw const AuthFailure('nobody signed in'));

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
          emailVerified: user.emailVerified,
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
