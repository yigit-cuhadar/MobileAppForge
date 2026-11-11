import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_auth/src/data/firebase_auth_repository.dart';
import 'package:forge_auth/src/domain/auth_user.dart';
import 'package:forge_core/forge_core.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class FakeAuthCredential extends Fake implements AuthCredential {}

class FakeAuthProvider extends Fake implements AuthProvider {}

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

  for (final code in [
    'credential-already-in-use',
    'email-already-in-use',
    'provider-already-linked',
  ]) {
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
          isA<AuthFailure>().having(
            (f) => f.code,
            'code',
            AuthFailure.accountExists,
          ),
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
}
