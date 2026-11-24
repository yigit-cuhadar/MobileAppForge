import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_auth/forge_auth.dart';
import 'package:forge_core/forge_core.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  const user = AuthUser(id: 'u1', email: 'a@b.co');
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.sendEmailVerification())
        .thenAnswer((_) async => const Ok(null));
  });

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
      signInAnonymously: SignInAnonymously(repository),
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

    test(
      'signUp mails the verification link once the account exists',
      () async {
        when(() => repository.signUpWithEmail('a@b.co', 'secret1'))
            .thenAnswer((_) async => const Ok(user));

        await build().signUp(' a@b.co ', 'secret1');

        verify(() => repository.sendEmailVerification()).called(1);
      },
    );

    test('a failed sign-up mails nothing', () async {
      when(() => repository.signUpWithEmail(any(), any()))
          .thenAnswer((_) async => const Err(failure));

      await build().signUp('a@b.co', 'secret1');

      verifyNever(() => repository.sendEmailVerification());
    });

    blocTest<AuthFormCubit, AuthFormState>(
      'a verification email that fails to go out still signs up',
      setUp: () {
        when(() => repository.signUpWithEmail(any(), any()))
            .thenAnswer((_) async => const Ok(user));
        when(() => repository.sendEmailVerification())
            .thenAnswer((_) async => const Err(NetworkFailure()));
      },
      build: build,
      act: (cubit) => cubit.signUp('a@b.co', 'secret1'),
      expect: () => const [
        AuthFormState(status: AuthFormStatus.loading),
        AuthFormState(),
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
      'continueAsGuest starts a guest session',
      setUp: () =>
          when(() => repository.signInAnonymously())
              .thenAnswer((_) async => const Ok(AuthUser(id: 'g1'))),
      build: build,
      act: (cubit) => cubit.continueAsGuest(),
      expect: () => const [
        AuthFormState(status: AuthFormStatus.loading),
        AuthFormState(),
      ],
      verify: (_) => verify(() => repository.signInAnonymously()).called(1),
    );

    const offline = NetworkFailure('offline');
    blocTest<AuthFormCubit, AuthFormState>(
      'retry runs the failed action again',
      setUp: () {
        var calls = 0;
        when(() => repository.signInWithEmail('a@b.co', 'secret1')).thenAnswer(
          (_) async => calls++ == 0 ? const Err(offline) : const Ok(user),
        );
        when(() => repository.currentUser).thenReturn(null);
      },
      build: build,
      act: (cubit) async {
        await cubit.signIn('a@b.co', 'secret1');
        await cubit.retry();
      },
      expect: () => const [
        AuthFormState(status: AuthFormStatus.loading),
        AuthFormState(status: AuthFormStatus.failure, failure: offline),
        AuthFormState(status: AuthFormStatus.loading),
        AuthFormState(),
      ],
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'retry does nothing unless the last action failed',
      setUp: () =>
          when(() => repository.signInAnonymously())
              .thenAnswer((_) async => const Ok(AuthUser(id: 'g1'))),
      build: build,
      act: (cubit) async {
        await cubit.retry();
        await cubit.continueAsGuest();
        await cubit.retry();
      },
      verify: (_) => verify(() => repository.signInAnonymously()).called(1),
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
      signInAnonymously: SignInAnonymously(repository),
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
      'a closed provider sheet is cancelled, not a failure, and not retried',
      setUp: () => stubProvider(
        replaceGuest: false,
        result: const Err(AuthFailure('x', code: cancelledCode)),
      ),
      build: build,
      act: (cubit) async {
        await cubit.signInWith(SocialProvider.apple);
        await cubit.retry();
      },
      expect: () => const [
        AuthFormState(status: AuthFormStatus.loading),
        AuthFormState(status: AuthFormStatus.cancelled),
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

  group('EmailVerificationCubit', () {
    const unverified = AuthUser(
      id: 'u1',
      email: 'a@b.co',
      signInMethods: {SignInMethod.email},
    );
    const verified = AuthUser(
      id: 'u1',
      email: 'a@b.co',
      signInMethods: {SignInMethod.email},
      emailVerified: true,
    );
    const throttled = AuthFailure('x', code: 'too-many-requests');

    EmailVerificationCubit build() => EmailVerificationCubit(
      reloadUser: ReloadUser(repository),
      sendEmailVerification: SendEmailVerification(repository),
      changeEmail: ChangeEmail(repository),
      getVerificationSentAt: GetVerificationSentAt(repository),
      signOut: SignOut(repository),
    );

    setUp(() => when(() => repository.verificationSentAt).thenReturn(null));

    test('opened right after a link went out, Resend waits out the rest '
        'of the minute', () {
      when(() => repository.verificationSentAt)
          .thenReturn(DateTime.now().subtract(const Duration(seconds: 20)));
      final cubit = build();
      expect(cubit.state.resendIn, inInclusiveRange(39, 40));
      cubit.close();

      when(() => repository.verificationSentAt)
          .thenReturn(DateTime.now().subtract(const Duration(minutes: 2)));
      final later = build();
      expect(later.state.resendIn, 0);
      later.close();
    });

    test('opened before sign-up\'s link went out, Resend still waits: it '
        'starts the cooldown instead of sending', () {
      final cubit = build();
      expect(cubit.state.resendIn, 0);
      when(() => repository.verificationSentAt).thenReturn(DateTime.now());
      cubit.resend();
      expect(cubit.state.resendIn, inInclusiveRange(59, 60));
      verifyNever(() => repository.sendEmailVerification());
      cubit.close();
    });

    test('changeEmail sends the link to the new address, which the page '
        'then shows and Resend uses', () {
      fakeAsync((async) {
        when(() => repository.changeEmail('new@b.co'))
            .thenAnswer((_) async => const Ok(null));
        final cubit = build()..changeEmail(' new@b.co ');
        expect(cubit.state.status, EmailVerificationStatus.changingEmail);
        async.flushMicrotasks();
        expect(cubit.state.status, EmailVerificationStatus.emailChangeSent);
        expect(cubit.state.pendingEmail, 'new@b.co');
        expect(cubit.state.resendIn, EmailVerificationCubit.resendCooldown);

        async.elapse(const Duration(seconds: 60));
        cubit.resend();
        async.flushMicrotasks();
        verify(() => repository.changeEmail('new@b.co')).called(2);
        verifyNever(() => repository.sendEmailVerification());
        cubit.close();
        async.flushTimers();
      });
    });

    blocTest<EmailVerificationCubit, EmailVerificationState>(
      'a refused address keeps the old one and says why',
      setUp: () => when(() => repository.changeEmail(any())).thenAnswer(
        (_) async => const Err(AuthFailure('x', code: 'email-already-in-use')),
      ),
      build: build,
      act: (cubit) => cubit.changeEmail('taken@b.co'),
      expect: () => const [
        EmailVerificationState(status: EmailVerificationStatus.changingEmail),
        EmailVerificationState(
          status: EmailVerificationStatus.emailChangeFailed,
          failure: AuthFailure('x', code: 'email-already-in-use'),
        ),
      ],
    );

    test('watching reloads at once, then every few seconds until it '
        'stops', () {
      fakeAsync((async) {
        when(() => repository.reloadUser())
            .thenAnswer((_) async => const Ok(unverified));
        final cubit = build()..watch();
        async.flushMicrotasks();
        verify(() => repository.reloadUser()).called(1);

        async.elapse(EmailVerificationCubit.checkEvery * 2);
        verify(() => repository.reloadUser()).called(2);

        cubit.stopWatching();
        async.elapse(EmailVerificationCubit.checkEvery * 3);
        verifyNever(() => repository.reloadUser());
        expect(cubit.state, const EmailVerificationState());
        cubit.close();
      });
    });

    test('a slow reload is not doubled; a failed one waits for the next '
        'tick', () {
      fakeAsync((async) {
        final reload = Completer<Result<AuthUser>>();
        when(() => repository.reloadUser()).thenAnswer((_) => reload.future);
        final cubit = build()..watch();
        async.elapse(EmailVerificationCubit.checkEvery * 2);
        verify(() => repository.reloadUser()).called(1);

        reload.complete(const Err(NetworkFailure()));
        when(() => repository.reloadUser())
            .thenAnswer((_) async => const Ok(verified));
        async.elapse(EmailVerificationCubit.checkEvery);
        verify(() => repository.reloadUser()).called(1);
        expect(cubit.state, const EmailVerificationState());
        cubit.close();
      });
    });

    test('closing stops watching', () {
      fakeAsync((async) {
        when(() => repository.reloadUser())
            .thenAnswer((_) async => const Ok(unverified));
        build()
          ..watch()
          ..close();
        async.flushMicrotasks();
        clearInteractions(repository);
        async.elapse(EmailVerificationCubit.checkEvery * 2);
        verifyNever(() => repository.reloadUser());
      });
    });

    test('resend counts down a minute before it can send again', () {
      fakeAsync((async) {
        final cubit = build();
        cubit.resend();
        async.flushMicrotasks();
        expect(cubit.state.status, EmailVerificationStatus.sent);
        expect(cubit.state.resendIn, EmailVerificationCubit.resendCooldown);

        cubit.resend();
        async.elapse(const Duration(seconds: 59));
        expect(cubit.state.resendIn, 1);
        verify(() => repository.sendEmailVerification()).called(1);

        async.elapse(const Duration(seconds: 1));
        expect(cubit.state.resendIn, 0);
        cubit.resend();
        async.flushMicrotasks();
        verify(() => repository.sendEmailVerification()).called(1);
        cubit.close();
        async.flushTimers();
      });
    });

    test('a throttled send waits too; another failure does not', () {
      fakeAsync((async) {
        when(() => repository.sendEmailVerification())
            .thenAnswer((_) async => const Err(throttled));
        final throttledCubit = build()..resend();
        async.flushMicrotasks();
        expect(throttledCubit.state.status, EmailVerificationStatus.failure);
        expect(throttledCubit.state.resendIn, greaterThan(0));

        when(() => repository.sendEmailVerification())
            .thenAnswer((_) async => const Err(NetworkFailure()));
        final offlineCubit = build()..resend();
        async.flushMicrotasks();
        expect(offlineCubit.state.status, EmailVerificationStatus.failure);
        expect(offlineCubit.state.resendIn, 0);

        throttledCubit.close();
        offlineCubit.close();
        async.flushTimers();
      });
    });

    blocTest<EmailVerificationCubit, EmailVerificationState>(
      'signOut signs out',
      setUp: () =>
          when(() => repository.signOut())
              .thenAnswer((_) async => const Ok(null)),
      build: build,
      act: (cubit) => cubit.signOut(),
      expect: () => const [
        EmailVerificationState(status: EmailVerificationStatus.signingOut),
        EmailVerificationState(),
      ],
      verify: (_) => verify(() => repository.signOut()).called(1),
    );

    blocTest<EmailVerificationCubit, EmailVerificationState>(
      'ignores a second action while one runs',
      setUp: () =>
          when(() => repository.signOut())
              .thenAnswer((_) async => const Ok(null)),
      build: build,
      act: (cubit) =>
          Future.wait([cubit.signOut(), cubit.resend(), cubit.signOut()]),
      verify: (_) {
        verify(() => repository.signOut()).called(1);
        verifyNever(() => repository.sendEmailVerification());
      },
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
