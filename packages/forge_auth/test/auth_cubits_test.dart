import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_auth/forge_auth.dart';
import 'package:forge_core/forge_core.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  const user = AuthUser(id: 'u1', email: 'a@b.co');
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  group('AuthCubit', () {
    late StreamController<AuthUser?> users;

    AuthCubit build({bool guestStart = false}) => AuthCubit(
      watchAuthUser: WatchAuthUser(repository),
      signOut: SignOut(repository),
      deleteAccount: DeleteAccount(repository),
      signInAnonymously: guestStart ? SignInAnonymously(repository) : null,
    );

    setUp(() {
      users = StreamController<AuthUser?>();
      when(() => repository.watchUser()).thenAnswer((_) => users.stream);
    });

    test('starts unknown', () => expect(build().state, const AuthUnknown()));

    blocTest<AuthCubit, AuthState>(
      'follows the user stream',
      build: build,
      act: (_) => users
        ..add(null)
        ..add(user)
        ..add(null),
      expect: () => const [
        Unauthenticated(),
        Authenticated(user),
        Unauthenticated(),
      ],
    );

    const guest = AuthUser(id: 'g1', isAnonymous: true);

    blocTest<AuthCubit, AuthState>(
      'with guest start, a signed-out session becomes a guest',
      setUp: () =>
          when(() => repository.signInAnonymously()).thenAnswer((_) async {
            users.add(guest);
            return const Ok(guest);
          }),
      build: () => build(guestStart: true),
      act: (_) => users
        ..add(user)
        ..add(null),
      expect: () => const [Authenticated(user), Authenticated(guest)],
      verify: (_) => verify(() => repository.signInAnonymously()).called(1),
    );

    blocTest<AuthCubit, AuthState>(
      'with guest start, a failed guest sign-in is Unauthenticated',
      setUp: () =>
          when(() => repository.signInAnonymously())
              .thenAnswer((_) async => const Err(NetworkFailure())),
      build: () => build(guestStart: true),
      act: (_) => users.add(null),
      expect: () => const [Unauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'without guest start, never signs in anonymously',
      build: build,
      act: (_) => users.add(null),
      expect: () => const [Unauthenticated()],
      verify: (_) => verifyNever(() => repository.signInAnonymously()),
    );

    blocTest<AuthCubit, AuthState>(
      'retryGuestSignIn tries again after a failure',
      setUp: () {
        var attempts = 0;
        when(() => repository.signInAnonymously()).thenAnswer((_) async {
          if (++attempts == 1) return const Err(NetworkFailure());
          users.add(guest);
          return const Ok(guest);
        });
      },
      build: () => build(guestStart: true),
      act: (cubit) async {
        users.add(null);
        await Future<void>.delayed(Duration.zero);
        await cubit.retryGuestSignIn();
      },
      expect: () => const [
        Unauthenticated(),
        AuthUnknown(),
        Authenticated(guest),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'retryGuestSignIn does nothing without guest start',
      build: build,
      act: (cubit) async {
        users.add(null);
        await Future<void>.delayed(Duration.zero);
        await cubit.retryGuestSignIn();
      },
      expect: () => const [Unauthenticated()],
      verify: (_) => verifyNever(() => repository.signInAnonymously()),
    );

    test('signOut delegates to the repository', () async {
      when(() => repository.signOut()).thenAnswer((_) async => const Ok(null));
      expect((await build().signOut()).isOk, isTrue);
      verify(() => repository.signOut()).called(1);
    });
  });

  group('AuthFormCubit', () {
    AuthFormCubit build() => AuthFormCubit(
      signInWithEmail: SignInWithEmail(repository),
      signUpWithEmail: SignUpWithEmail(repository),
      signInWithProvider: SignInWithProvider(repository),
      sendPasswordReset: SendPasswordReset(repository),
      getCurrentUser: GetCurrentUser(repository),
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'signIn trims the email and returns to idle on success',
      setUp: () =>
          when(() => repository.signInWithEmail('a@b.co', 'secret1'))
              .thenAnswer((_) async => const Ok(user)),
      build: build,
      act: (cubit) => cubit.signIn(' a@b.co ', 'secret1'),
      expect: () => const [
        AuthFormState(status: AuthFormStatus.loading),
        AuthFormState(),
      ],
    );

    const failure = AuthFailure('bad', code: 'email-already-in-use');
    blocTest<AuthFormCubit, AuthFormState>(
      'signUp surfaces the failure',
      setUp: () =>
          when(() => repository.signUpWithEmail(any(), any()))
              .thenAnswer((_) async => const Err(failure)),
      build: build,
      act: (cubit) => cubit.signUp('a@b.co', 'secret1'),
      expect: () => const [
        AuthFormState(status: AuthFormStatus.loading),
        AuthFormState(status: AuthFormStatus.failure, failure: failure),
      ],
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'resetPassword ends in resetSent',
      setUp: () =>
          when(() => repository.sendPasswordReset('a@b.co'))
              .thenAnswer((_) async => const Ok(null)),
      build: build,
      act: (cubit) => cubit.resetPassword('a@b.co'),
      expect: () => const [
        AuthFormState(status: AuthFormStatus.loading),
        AuthFormState(status: AuthFormStatus.resetSent),
      ],
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'ignores a second submit while loading',
      setUp: () => when(
        () => repository.signInWithProvider(
          SocialProvider.google,
          replaceGuest: any(named: 'replaceGuest'),
        ),
      ).thenAnswer((_) async => const Ok(user)),
      build: build,
      act: (cubit) => Future.wait([
        cubit.signInWith(SocialProvider.google),
        cubit.signInWith(SocialProvider.google),
      ]),
      verify: (_) => verify(
        () => repository.signInWithProvider(
          SocialProvider.google,
          replaceGuest: any(named: 'replaceGuest'),
        ),
      ).called(1),
    );
  });

  group('AuthFormCubit with a guest', () {
    const guest = AuthUser(id: 'g1', isAnonymous: true);
    const accountExists = AuthFailure('x', code: accountExistsCode);

    AuthFormCubit build() => AuthFormCubit(
      signInWithEmail: SignInWithEmail(repository),
      signUpWithEmail: SignUpWithEmail(repository),
      signInWithProvider: SignInWithProvider(repository),
      sendPasswordReset: SendPasswordReset(repository),
      getCurrentUser: GetCurrentUser(repository),
    );

    void stubProvider({
      required bool replaceGuest,
      required Result<AuthUser> result,
    }) => when(
      () => repository.signInWithProvider(
        SocialProvider.apple,
        replaceGuest: replaceGuest,
      ),
    ).thenAnswer((_) async => result);

    setUp(() {
      when(() => repository.currentUser).thenReturn(guest);
      when(() => repository.signInWithEmail(any(), any()))
          .thenAnswer((_) async => const Ok(user));
    });

    blocTest<AuthFormCubit, AuthFormState>(
      'signIn asks first and signs in only after confirm',
      build: build,
      act: (cubit) async {
        await cubit.signIn('a@b.co', 'secret1');
        verifyNever(() => repository.signInWithEmail(any(), any()));
        await cubit.confirmReplaceGuest();
      },
      expect: () => const [
        AuthFormState(status: AuthFormStatus.confirmReplaceGuest),
        AuthFormState(status: AuthFormStatus.loading),
        AuthFormState(),
      ],
      verify: (_) =>
          verify(() => repository.signInWithEmail('a@b.co', 'secret1'))
              .called(1),
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'cancel returns to idle without signing in',
      build: build,
      act: (cubit) async {
        await cubit.signIn('a@b.co', 'secret1');
        cubit.cancelReplaceGuest();
        await cubit.confirmReplaceGuest();
      },
      expect: () => const [
        AuthFormState(status: AuthFormStatus.confirmReplaceGuest),
        AuthFormState(),
      ],
      verify: (_) =>
          verifyNever(() => repository.signInWithEmail(any(), any())),
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'a signed-in user is not asked',
      setUp: () => when(() => repository.currentUser).thenReturn(user),
      build: build,
      act: (cubit) => cubit.signIn('a@b.co', 'secret1'),
      expect: () => const [
        AuthFormState(status: AuthFormStatus.loading),
        AuthFormState(),
      ],
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'provider account-exists asks, then retries with replaceGuest',
      setUp: () {
        stubProvider(replaceGuest: false, result: const Err(accountExists));
        stubProvider(replaceGuest: true, result: const Ok(user));
      },
      build: build,
      act: (cubit) async {
        await cubit.signInWith(SocialProvider.apple);
        verifyNever(
          () => repository.signInWithProvider(
            SocialProvider.apple,
            replaceGuest: true,
          ),
        );
        await cubit.confirmReplaceGuest();
      },
      expect: () => const [
        AuthFormState(status: AuthFormStatus.loading),
        AuthFormState(status: AuthFormStatus.confirmReplaceGuest),
        AuthFormState(status: AuthFormStatus.loading),
        AuthFormState(),
      ],
      verify: (_) => verify(
        () => repository.signInWithProvider(
          SocialProvider.apple,
          replaceGuest: true,
        ),
      ).called(1),
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'other provider failures surface as failure',
      setUp: () => stubProvider(
        replaceGuest: false,
        result: const Err(NetworkFailure()),
      ),
      build: build,
      act: (cubit) => cubit.signInWith(SocialProvider.apple),
      expect: () => [
        const AuthFormState(status: AuthFormStatus.loading),
        isA<AuthFormState>().having(
          (s) => s.status,
          'status',
          AuthFormStatus.failure,
        ),
      ],
    );
  });

  test('default error text distinguishes common auth codes', () {
    const s = AuthStrings();
    expect(
      s.errorFor(const AuthFailure('x', code: 'wrong-password')),
      s.errorFor(const AuthFailure('x', code: 'invalid-credential')),
    );
    expect(
      s.errorFor(const NetworkFailure()),
      isNot(s.errorFor(const AuthFailure('x', code: 'weak-password'))),
    );
  });
}
