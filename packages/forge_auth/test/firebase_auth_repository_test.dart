import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_auth/src/data/firebase_auth_repository.dart';
import 'package:forge_auth/src/data/native_google_sign_in.dart';
import 'package:forge_auth/src/domain/auth_repository.dart';
import 'package:forge_auth/src/domain/auth_user.dart';
import 'package:forge_core/forge_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class FakeAuthCredential extends Fake implements AuthCredential {}

class FakeAuthProvider extends Fake implements AuthProvider {}

class MockUserInfo extends Mock implements UserInfo {}

class MockNativeGoogleSignIn extends Mock implements NativeGoogleSignIn {}

void main() {
  late MockFirebaseAuth auth;
  late MockUser user;
  late MockNativeGoogleSignIn google;
  late FirebaseAuthRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
    registerFallbackValue(FakeAuthProvider());
  });

  setUp(() {
    auth = MockFirebaseAuth();
    user = MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => user.email).thenReturn('a@b.co');
    when(() => user.displayName).thenReturn(null);
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.emailVerified).thenReturn(false);
    when(() => user.providerData).thenReturn([]);
    google = MockNativeGoogleSignIn();
    repository = FirebaseAuthRepository(auth, google);
  });

  MockUserCredential credentialFor(User user) {
    final credential = MockUserCredential();
    when(() => credential.user).thenReturn(user);
    return credential;
  }

  MockUser signedInGuest() {
    final guest = MockUser();
    when(() => guest.isAnonymous).thenReturn(true);
    when(() => auth.currentUser).thenReturn(guest);
    return guest;
  }

  test('signInWithEmail maps the Firebase user', () async {
    final credential = MockUserCredential();
    when(() => credential.user).thenReturn(user);
    when(() => auth.signInWithEmailAndPassword(email: 'a@b.co', password: 'pw'))
        .thenAnswer((_) async => credential);

    final result = await repository.signInWithEmail('a@b.co', 'pw');

    expect(result.valueOrNull, const AuthUser(id: 'u1', email: 'a@b.co'));
  });

  test(
    'signUpWithEmail turns FirebaseAuthException into AuthFailure',
    () async {
      when(
        () => auth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      final result = await repository.signUpWithEmail('a@b.co', 'pw');

      expect(
        result.failureOrNull,
        isA<AuthFailure>().having(
          (f) => f.code,
          'code',
          'email-already-in-use',
        ),
      );
    },
  );

  test('watchUser emits null when signed out', () {
    when(() => auth.userChanges())
        .thenAnswer((_) => Stream.fromIterable([null, user]));

    expect(
      repository.watchUser(),
      emitsInOrder([null, const AuthUser(id: 'u1', email: 'a@b.co')]),
    );
  });

  test('signInAnonymously maps isAnonymous', () async {
    final guest = MockUser();
    when(() => guest.uid).thenReturn('g1');
    when(() => guest.email).thenReturn(null);
    when(() => guest.displayName).thenReturn(null);
    when(() => guest.isAnonymous).thenReturn(true);
    when(() => guest.emailVerified).thenReturn(false);
    when(() => guest.providerData).thenReturn([]);
    when(() => auth.signInAnonymously())
        .thenAnswer((_) async => credentialFor(guest));

    final result = await repository.signInAnonymously();

    expect(result.valueOrNull, const AuthUser(id: 'g1', isAnonymous: true));
  });

  test('signUpWithEmail links a guest instead of creating a user', () async {
    final guest = signedInGuest();
    when(() => guest.linkWithCredential(any()))
        .thenAnswer((_) async => credentialFor(user));

    final result = await repository.signUpWithEmail('a@b.co', 'pw');

    expect(result.valueOrNull, const AuthUser(id: 'u1', email: 'a@b.co'));
    verify(() => guest.linkWithCredential(any())).called(1);
    verifyNever(
      () => auth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  test('signInWithProvider links a guest to the provider', () async {
    final guest = signedInGuest();
    when(() => guest.linkWithProvider(any()))
        .thenAnswer((_) async => credentialFor(user));

    final result = await repository.signInWithProvider(SocialProvider.apple);

    expect(result.isOk, isTrue);
    verifyNever(() => auth.signInWithProvider(any()));
  });

  for (final code in ['credential-already-in-use', 'email-already-in-use']) {
    test(
      'signInWithProvider maps link conflict $code to accountExists',
      () async {
        final guest = signedInGuest();
        when(() => guest.linkWithProvider(any()))
            .thenThrow(FirebaseAuthException(code: code));

        final result = await repository.signInWithProvider(
          SocialProvider.apple,
        );

        expect(
          result.failureOrNull,
          isA<AuthFailure>().having((f) => f.code, 'code', accountExistsCode),
        );
      },
    );
  }

  test('signInWithProvider with replaceGuest signs in plainly', () async {
    final guest = signedInGuest();
    when(() => auth.signInWithProvider(any()))
        .thenAnswer((_) async => credentialFor(user));

    final result = await repository.signInWithProvider(
      SocialProvider.apple,
      replaceGuest: true,
    );

    expect(result.valueOrNull, const AuthUser(id: 'u1', email: 'a@b.co'));
    verifyNever(() => guest.linkWithProvider(any()));
  });

  UserInfo provider(String id) {
    final info = MockUserInfo();
    when(() => info.providerId).thenReturn(id);
    return info;
  }

  test('currentUser maps the signed-in Firebase user', () {
    when(() => auth.currentUser).thenReturn(user);
    expect(repository.currentUser, const AuthUser(id: 'u1', email: 'a@b.co'));
  });

  test('a user carries their sign-in methods', () {
    final providers = [
      provider('google.com'),
      provider('password'),
      provider('apple.com'),
      provider('phone'),
    ];
    when(() => user.providerData).thenReturn(providers);
    when(() => auth.currentUser).thenReturn(user);

    expect(repository.currentUser?.signInMethods, {
      SignInMethod.google,
      SignInMethod.email,
      SignInMethod.apple,
    });
  });

  group('email verification', () {
    test('an email-only user needs it until verified', () {
      final password = [provider('password')];
      when(() => user.providerData).thenReturn(password);
      when(() => auth.currentUser).thenReturn(user);
      expect(repository.currentUser?.needsEmailVerification, isTrue);

      when(() => user.emailVerified).thenReturn(true);
      expect(repository.currentUser?.needsEmailVerification, isFalse);
    });

    test('Google or Apple next to email counts as verified', () {
      for (final other in ['google.com', 'apple.com']) {
        final providers = [provider('password'), provider(other)];
        when(() => user.providerData).thenReturn(providers);
        when(() => auth.currentUser).thenReturn(user);
        expect(repository.currentUser?.needsEmailVerification, isFalse);
      }
    });

    test('a guest or a provider-only user does not need it', () {
      when(() => auth.currentUser).thenReturn(user);
      final google = [provider('google.com')];
      when(() => user.providerData).thenReturn(google);
      expect(repository.currentUser?.needsEmailVerification, isFalse);

      when(() => user.isAnonymous).thenReturn(true);
      when(() => user.providerData).thenReturn([]);
      expect(repository.currentUser?.needsEmailVerification, isFalse);
    });

    test('sendEmailVerification mails the signed-in user', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(user.sendEmailVerification).thenAnswer((_) async {});

      expect((await repository.sendEmailVerification()).isOk, isTrue);
      verify(user.sendEmailVerification).called(1);
    });

    test('sendEmailVerification keeps Firebase\'s code', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(user.sendEmailVerification)
          .thenThrow(FirebaseAuthException(code: 'too-many-requests'));

      final result = await repository.sendEmailVerification();

      expect(
        result.failureOrNull,
        isA<AuthFailure>().having((f) => f.code, 'code', 'too-many-requests'),
      );
    });

    test('reloadUser returns the user as Firebase now has it', () async {
      when(() => auth.currentUser).thenReturn(user);
      var verifiedNow = false;
      when(() => user.emailVerified).thenAnswer((_) => verifiedNow);
      when(user.reload).thenAnswer((_) async => verifiedNow = true);

      final result = await repository.reloadUser();

      expect(result.valueOrNull?.emailVerified, isTrue);
    });

    test('both fail with nobody signed in', () async {
      when(() => auth.currentUser).thenReturn(null);

      expect(
        (await repository.sendEmailVerification()).failureOrNull,
        isA<AuthFailure>(),
      );
      expect((await repository.reloadUser()).failureOrNull, isA<AuthFailure>());
    });
  });

  group('changeEmail', () {
    final recentLogin = FirebaseAuthException(code: 'requires-recent-login');

    setUp(() {
      when(() => auth.currentUser).thenReturn(user);
      when(
        () => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credentialFor(user));
    });

    test('sends the link to the new address and notes when', () async {
      when(() => user.verifyBeforeUpdateEmail('new@b.co'))
          .thenAnswer((_) async {});

      expect((await repository.changeEmail('new@b.co')).isOk, isTrue);
      expect(repository.verificationSentAt, isNotNull);
    });

    test('a sent verification email is noted too', () async {
      when(user.sendEmailVerification).thenAnswer((_) async {});
      expect(repository.verificationSentAt, isNull);

      await repository.sendEmailVerification();

      expect(repository.verificationSentAt, isNotNull);
    });

    test('a too old sign-in is renewed with the password just used', () async {
      var calls = 0;
      when(() => user.verifyBeforeUpdateEmail('new@b.co'))
          .thenAnswer((_) async {
            if (calls++ == 0) throw recentLogin;
          });
      when(() => user.reauthenticateWithCredential(any()))
          .thenAnswer((_) async => credentialFor(user));
      await repository.signInWithEmail('a@b.co', 'secret1');

      expect((await repository.changeEmail('new@b.co')).isOk, isTrue);

      final credential =
          verify(() => user.reauthenticateWithCredential(captureAny()))
                  .captured
                  .single
              as AuthCredential;
      expect(credential.providerId, EmailAuthProvider.PROVIDER_ID);
      verify(() => user.verifyBeforeUpdateEmail('new@b.co')).called(2);
    });

    test('without that password, or with one that no longer fits, it '
        'stays requires-recent-login', () async {
      when(() => user.verifyBeforeUpdateEmail(any())).thenThrow(recentLogin);
      Matcher recent() => isA<AuthFailure>().having(
        (f) => f.code,
        'code',
        'requires-recent-login',
      );

      expect(
        (await repository.changeEmail('new@b.co')).failureOrNull,
        recent(),
      );
      verifyNever(() => user.reauthenticateWithCredential(any()));

      when(() => user.reauthenticateWithCredential(any()))
          .thenThrow(FirebaseAuthException(code: 'invalid-credential'));
      await repository.signInWithEmail('a@b.co', 'secret1');
      expect(
        (await repository.changeEmail('new@b.co')).failureOrNull,
        recent(),
      );
    });

    test('a refused address keeps Firebase\'s code', () async {
      when(() => user.verifyBeforeUpdateEmail(any()))
          .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      expect(
        (await repository.changeEmail('taken@b.co')).failureOrNull,
        isA<AuthFailure>().having(
          (f) => f.code,
          'code',
          'email-already-in-use',
        ),
      );
    });

    test('once the change ends the session, the guest start signs in to '
        'the new address instead', () async {
      when(() => user.verifyBeforeUpdateEmail('new@b.co'))
          .thenAnswer((_) async {});
      await repository.signInWithEmail('a@b.co', 'secret1');
      await repository.changeEmail('new@b.co');

      final result = await repository.signInAnonymously();

      expect(result.valueOrNull?.id, 'u1');
      verify(
        () => auth.signInWithEmailAndPassword(
          email: 'new@b.co',
          password: 'secret1',
        ),
      ).called(1);
      verifyNever(() => auth.signInAnonymously());
    });

    test('after signing out, a guest starts as usual', () async {
      when(() => user.verifyBeforeUpdateEmail('new@b.co'))
          .thenAnswer((_) async {});
      when(() => auth.signOut()).thenAnswer((_) async {});
      final guest = MockUser();
      when(() => guest.uid).thenReturn('g1');
      when(() => guest.email).thenReturn(null);
      when(() => guest.displayName).thenReturn(null);
      when(() => guest.isAnonymous).thenReturn(true);
      when(() => guest.emailVerified).thenReturn(false);
      when(() => guest.providerData).thenReturn([]);
      final guestCredential = credentialFor(guest);
      when(() => auth.signInAnonymously())
          .thenAnswer((_) async => guestCredential);
      await repository.signInWithEmail('a@b.co', 'secret1');
      await repository.changeEmail('new@b.co');
      clearInteractions(auth);

      await repository.signOut();
      final result = await repository.signInAnonymously();

      expect(result.valueOrNull?.isAnonymous, isTrue);
      expect(repository.verificationSentAt, isNull);
      verifyNever(
        () => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });
  });

  group('reauthenticate', () {
    setUp(() {
      when(() => auth.currentUser).thenReturn(user);
      final providers = [provider('google.com'), provider('password')];
      when(() => user.providerData).thenReturn(providers);
      when(() => user.reauthenticateWithCredential(any()))
          .thenAnswer((_) async => credentialFor(user));
    });

    test('signs in again with the email and password', () async {
      expect((await repository.reauthenticate('secret')).isOk, isTrue);
      final credential =
          verify(() => user.reauthenticateWithCredential(captureAny()))
                  .captured
                  .single
              as EmailAuthCredential;
      expect(credential.email, 'a@b.co');
      expect(credential.password, 'secret');
    });

    Future<void> expectNoPassword() async {
      expect(
        (await repository.reauthenticate('secret')).failureOrNull,
        isA<AuthFailure>().having((f) => f.code, 'code', noPasswordCode),
      );
      verifyNever(() => user.reauthenticateWithCredential(any()));
    }

    test('fails with nobody signed in', () async {
      when(() => auth.currentUser).thenReturn(null);
      await expectNoPassword();
    });

    test('fails for a user who signs in with a provider only', () async {
      final providers = [provider('apple.com')];
      when(() => user.providerData).thenReturn(providers);
      await expectNoPassword();
    });

    test('a wrong password is an auth failure', () async {
      when(() => user.reauthenticateWithCredential(any()))
          .thenThrow(FirebaseAuthException(code: 'invalid-credential'));
      expect(
        (await repository.reauthenticate('nope')).failureOrNull,
        isA<AuthFailure>().having((f) => f.code, 'code', 'invalid-credential'),
      );
    });
  });

  group('reauthenticateWithProvider through Firebase\'s flow', () {
    setUp(() {
      // Off Android and iOS (the web), Google uses Firebase's flow too.
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      when(() => auth.currentUser).thenReturn(user);
      final providers = [provider('google.com')];
      when(() => user.providerData).thenReturn(providers);
      when(() => user.reauthenticateWithProvider(any()))
          .thenAnswer((_) async => credentialFor(user));
    });

    test('signs in again with the linked provider', () async {
      final result = await repository.reauthenticateWithProvider(
        SocialProvider.google,
      );
      expect(result.isOk, isTrue);
      final used = verify(() => user.reauthenticateWithProvider(captureAny()))
          .captured
          .single;
      expect(used, isA<GoogleAuthProvider>());
    });

    Future<void> expectNotLinked(SocialProvider provider) async {
      expect(
        (await repository.reauthenticateWithProvider(provider)).failureOrNull,
        isA<AuthFailure>().having((f) => f.code, 'code', notLinkedCode),
      );
      verifyNever(() => user.reauthenticateWithProvider(any()));
    }

    test('fails with nobody signed in', () async {
      when(() => auth.currentUser).thenReturn(null);
      await expectNotLinked(SocialProvider.google);
    });

    test('fails for a provider the user has not linked', () async {
      await expectNotLinked(SocialProvider.apple);
    });

    test('a closed sheet is cancelled', () async {
      when(() => user.reauthenticateWithProvider(any()))
          .thenThrow(FirebaseAuthException(code: 'web-context-cancelled'));
      expect(
        (await repository.reauthenticateWithProvider(SocialProvider.google))
            .failureOrNull,
        isA<AuthFailure>().having((f) => f.code, 'code', cancelledCode),
      );
    });

    test('another account keeps Firebase\'s code', () async {
      when(() => user.reauthenticateWithProvider(any()))
          .thenThrow(FirebaseAuthException(code: 'user-mismatch'));
      expect(
        (await repository.reauthenticateWithProvider(SocialProvider.google))
            .failureOrNull,
        isA<AuthFailure>().having((f) => f.code, 'code', 'user-mismatch'),
      );
    });
  });

  group('reauthenticateWithAppleCode', () {
    late List<String?> nonces;
    late Object? appleError;

    Future<AuthorizationCredentialAppleID> requestAppleId({
      required List<AppleIDAuthorizationScopes> scopes,
      String? nonce,
    }) async {
      nonces.add(nonce);
      if (appleError case final error?) throw error;
      return const AuthorizationCredentialAppleID(
        userIdentifier: 'a1',
        givenName: null,
        familyName: null,
        email: null,
        authorizationCode: 'fresh-code',
        identityToken: 'id-token',
        state: null,
      );
    }

    setUp(() {
      nonces = [];
      appleError = null;
      repository = FirebaseAuthRepository(
        auth,
        google,
        requestAppleId: requestAppleId,
      );
      when(() => auth.currentUser).thenReturn(user);
      final providers = [provider('apple.com')];
      when(() => user.providerData).thenReturn(providers);
      when(() => user.reauthenticateWithCredential(any()))
          .thenAnswer((_) async => credentialFor(user));
    });

    test('signs in again with a native Apple token and returns its fresh '
        'code', () async {
      expect(
        (await repository.reauthenticateWithAppleCode()).valueOrNull,
        'fresh-code',
      );

      final credential =
          verify(() => user.reauthenticateWithCredential(captureAny()))
                  .captured
                  .single
              as OAuthCredential;
      expect(credential.providerId, 'apple.com');
      expect(credential.idToken, 'id-token');
      final rawNonce = credential.rawNonce!;
      expect(nonces.single, sha256.convert(utf8.encode(rawNonce)).toString());
      verifyNever(() => user.reauthenticateWithProvider(any()));
    });

    test('fails without Apple linked, asking Apple nothing', () async {
      final providers = [provider('google.com')];
      when(() => user.providerData).thenReturn(providers);
      expect(
        (await repository.reauthenticateWithAppleCode()).failureOrNull,
        isA<AuthFailure>().having((f) => f.code, 'code', notLinkedCode),
      );
      expect(nonces, isEmpty);
    });

    test('a closed Apple sheet is cancelled, signing in nothing', () async {
      appleError = const SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.canceled,
        message: 'canceled',
      );
      expect(
        (await repository.reauthenticateWithAppleCode()).failureOrNull,
        isA<AuthFailure>().having((f) => f.code, 'code', cancelledCode),
      );
      verifyNever(() => user.reauthenticateWithCredential(any()));
    });

    test('another Apple error is a failure, not a cancel', () async {
      appleError = const SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.failed,
        message: 'failed',
      );
      final failure =
          (await repository.reauthenticateWithAppleCode()).failureOrNull;
      expect(failure, isNotNull);
      expect(
        failure,
        isNot(isA<AuthFailure>().having((f) => f.code, 'code', cancelledCode)),
      );
    });

    test('a failed sign-in keeps Firebase\'s code', () async {
      when(() => user.reauthenticateWithCredential(any()))
          .thenThrow(FirebaseAuthException(code: 'user-mismatch'));
      expect(
        (await repository.reauthenticateWithAppleCode()).failureOrNull,
        isA<AuthFailure>().having((f) => f.code, 'code', 'user-mismatch'),
      );
    });
  });

  group('Google on Android and iOS', () {
    const cancelled = GoogleSignInException(
      code: GoogleSignInExceptionCode.canceled,
    );

    setUp(() {
      when(google.idToken).thenAnswer((_) async => 'google-token');
    });

    OAuthCredential googleCredential(AuthCredential credential) {
      expect(credential.providerId, 'google.com');
      return credential as OAuthCredential;
    }

    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      test('signs in with the native ID token on ${platform.name}', () async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        when(() => auth.signInWithCredential(any()))
            .thenAnswer((_) async => credentialFor(user));

        final result = await repository.signInWithProvider(
          SocialProvider.google,
        );

        expect(result.valueOrNull, const AuthUser(id: 'u1', email: 'a@b.co'));
        final used =
            verify(() => auth.signInWithCredential(captureAny()))
                    .captured
                    .single
                as AuthCredential;
        expect(googleCredential(used).idToken, 'google-token');
        verifyNever(() => auth.signInWithProvider(any()));
      });
    }

    test('links a guest to the chosen Google account', () async {
      final guest = signedInGuest();
      when(() => guest.linkWithCredential(any()))
          .thenAnswer((_) async => credentialFor(user));

      final result = await repository.signInWithProvider(SocialProvider.google);

      expect(result.isOk, isTrue);
      final used =
          verify(() => guest.linkWithCredential(captureAny())).captured.single
              as AuthCredential;
      expect(googleCredential(used).idToken, 'google-token');
      verifyNever(() => guest.linkWithProvider(any()));
    });

    test('a Google account already in use is accountExists', () async {
      final guest = signedInGuest();
      when(() => guest.linkWithCredential(any()))
          .thenThrow(FirebaseAuthException(code: 'credential-already-in-use'));

      expect(
        (await repository.signInWithProvider(SocialProvider.google))
            .failureOrNull,
        isA<AuthFailure>().having((f) => f.code, 'code', accountExistsCode),
      );
    });

    test('replacing the guest signs in to the account that already exists, '
        'asking Google once', () async {
      final guest = signedInGuest();
      when(() => guest.linkWithCredential(any()))
          .thenThrow(FirebaseAuthException(code: 'credential-already-in-use'));
      when(() => auth.signInWithCredential(any()))
          .thenAnswer((_) async => credentialFor(user));

      await repository.signInWithProvider(SocialProvider.google);
      final result = await repository.signInWithProvider(
        SocialProvider.google,
        replaceGuest: true,
      );

      expect(result.isOk, isTrue);
      final linked = verify(() => guest.linkWithCredential(captureAny()))
          .captured
          .single;
      final signedIn = verify(() => auth.signInWithCredential(captureAny()))
          .captured
          .single;
      expect(signedIn, same(linked));
      verify(google.idToken).called(1);
    });

    test('replacing the guest with no account kept asks Google', () async {
      signedInGuest();
      when(() => auth.signInWithCredential(any()))
          .thenAnswer((_) async => credentialFor(user));

      final result = await repository.signInWithProvider(
        SocialProvider.google,
        replaceGuest: true,
      );

      expect(result.isOk, isTrue);
      verify(google.idToken).called(1);
      verify(() => auth.signInWithCredential(any())).called(1);
    });

    test('a closed sheet is cancelled, signing in nothing', () async {
      when(google.idToken).thenThrow(cancelled);

      expect(
        (await repository.signInWithProvider(SocialProvider.google))
            .failureOrNull,
        isA<AuthFailure>().having((f) => f.code, 'code', cancelledCode),
      );
      verifyNever(() => auth.signInWithCredential(any()));
    });

    test('another Google error is a failure, not a cancel', () async {
      when(google.idToken).thenThrow(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        ),
      );

      final failure = (await repository.signInWithProvider(
        SocialProvider.google,
      )).failureOrNull;
      expect(failure, isNotNull);
      expect(
        failure,
        isNot(isA<AuthFailure>().having((f) => f.code, 'code', cancelledCode)),
      );
    });

    group('re-authentication', () {
      setUp(() {
        when(() => auth.currentUser).thenReturn(user);
        final providers = [provider('google.com')];
        when(() => user.providerData).thenReturn(providers);
        when(() => user.reauthenticateWithCredential(any()))
            .thenAnswer((_) async => credentialFor(user));
      });

      test('signs in again with the native ID token', () async {
        expect(
          (await repository.reauthenticateWithProvider(SocialProvider.google))
              .isOk,
          isTrue,
        );
        final used =
            verify(() => user.reauthenticateWithCredential(captureAny()))
                    .captured
                    .single
                as AuthCredential;
        expect(googleCredential(used).idToken, 'google-token');
        verifyNever(() => user.reauthenticateWithProvider(any()));
      });

      test('fails without Google linked, asking Google nothing', () async {
        when(() => user.providerData).thenReturn([]);
        expect(
          (await repository.reauthenticateWithProvider(SocialProvider.google))
              .failureOrNull,
          isA<AuthFailure>().having((f) => f.code, 'code', notLinkedCode),
        );
        verifyNever(google.idToken);
      });

      test('a closed sheet is cancelled', () async {
        when(google.idToken).thenThrow(cancelled);
        expect(
          (await repository.reauthenticateWithProvider(SocialProvider.google))
              .failureOrNull,
          isA<AuthFailure>().having((f) => f.code, 'code', cancelledCode),
        );
        verifyNever(() => user.reauthenticateWithCredential(any()));
      });
    });

    group('sign-out', () {
      setUp(() {
        when(() => auth.currentUser).thenReturn(user);
        when(() => auth.signOut()).thenAnswer((_) async {});
      });

      test('signs a Google user out of Google too', () async {
        final providers = [provider('google.com')];
        when(() => user.providerData).thenReturn(providers);
        when(google.signOut).thenAnswer((_) async {});

        expect((await repository.signOut()).isOk, isTrue);
        verify(() => auth.signOut()).called(1);
        verify(google.signOut).called(1);
      });

      test('succeeds when Google\'s sign-out fails', () async {
        final providers = [provider('google.com')];
        when(() => user.providerData).thenReturn(providers);
        when(google.signOut).thenThrow(Exception('offline'));

        expect((await repository.signOut()).isOk, isTrue);
        verify(() => auth.signOut()).called(1);
      });

      test('leaves Google alone for a user without it', () async {
        final providers = [provider('password')];
        when(() => user.providerData).thenReturn(providers);

        expect((await repository.signOut()).isOk, isTrue);
        verifyNever(google.signOut);
      });
    });
  });
}
