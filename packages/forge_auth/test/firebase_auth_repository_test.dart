import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_auth/src/data/firebase_auth_repository.dart';
import 'package:forge_auth/src/domain/auth_repository.dart';
import 'package:forge_auth/src/domain/auth_user.dart';
import 'package:forge_core/forge_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class FakeAuthCredential extends Fake implements AuthCredential {}

class FakeAuthProvider extends Fake implements AuthProvider {}

class MockUserInfo extends Mock implements UserInfo {}

void main() {
  late MockFirebaseAuth auth;
  late MockUser user;
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
    repository = FirebaseAuthRepository(auth);
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

    final result = await repository.signInWithProvider(SocialProvider.google);

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
      SocialProvider.google,
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

  group('reauthenticateWithProvider', () {
    setUp(() {
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
      repository = FirebaseAuthRepository(auth, requestAppleId: requestAppleId);
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
}
