import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_auth/src/data/firebase_auth_repository.dart';
import 'package:forge_auth/src/domain/auth_user.dart';
import 'package:forge_core/forge_core.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth auth;
  late MockUser user;
  late FirebaseAuthRepository repository;

  setUp(() {
    auth = MockFirebaseAuth();
    user = MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => user.email).thenReturn('a@b.co');
    when(() => user.displayName).thenReturn(null);
    repository = FirebaseAuthRepository(auth);
  });

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
}
