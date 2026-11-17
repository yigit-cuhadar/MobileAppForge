import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_auth/forge_auth.dart';
import 'package:forge_auth/src/presentation/provider_mark.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockAuthFormCubit extends MockCubit<AuthFormState>
    implements AuthFormCubit {}

void main() {
  late MockAuthFormCubit form;
  late StreamController<AuthFormState> states;

  setUpAll(() => registerFallbackValue(SocialProvider.google));

  setUp(() {
    form = MockAuthFormCubit();
    states = StreamController<AuthFormState>.broadcast();
    whenListen(form, states.stream, initialState: const AuthFormState());
    when(() => form.signInWith(any())).thenAnswer((_) async {});
    when(() => form.signIn(any(), any())).thenAnswer((_) async {});
    when(() => form.signUp(any(), any())).thenAnswer((_) async {});
    when(() => form.continueAsGuest()).thenAnswer((_) async {});
    when(() => form.retry()).thenAnswer((_) async {});
    when(() => form.confirmReplaceGuest()).thenAnswer((_) async {});
    sl.registerFactory<AuthFormCubit>(() => form);
  });

  tearDown(() async {
    await states.close();
    await sl.reset();
  });

  Future<void> pump(
    WidgetTester tester, {
    AuthState auth = const Unauthenticated(),
    bool initialSignUp = false,
  }) {
    tester.view
      ..physicalSize = const Size(400, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = MockAuthCubit();
    when(() => cubit.state).thenReturn(auth);
    return tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: BlocProvider<AuthCubit>.value(
          value: cubit,
          child: AuthPage(
            mark: const Text('A'),
            name: '[APP NAME]',
            tagline: '[TAGLINE]',
            onTerms: () {},
            onPrivacy: () {},
            providers: SocialProvider.values,
            initialSignUp: initialSignUp,
          ),
        ),
      ),
    );
  }

  Future<void> emit(WidgetTester tester, AuthFormState state) async {
    when(() => form.state).thenReturn(state);
    states.add(state);
    await tester.pump();
    await tester.pump();
  }

  Finder mark(SocialProvider provider) => find.byWidgetPredicate(
    (w) => w is ProviderMark && w.provider == provider,
  );

  for (final (provider, label) in [
    (SocialProvider.google, 'Continue with Google'),
    (SocialProvider.apple, 'Continue with Apple'),
  ]) {
    testWidgets('$label shows its mark and signs in with it', (tester) async {
      await pump(tester);

      expect(mark(provider), findsOneWidget);
      await tester.tap(find.text(label));
      verify(() => form.signInWith(provider)).called(1);
    });
  }

  testWidgets('the marks are the same size', (tester) async {
    await pump(tester);
    expect(
      tester.getSize(mark(SocialProvider.google)),
      tester.getSize(mark(SocialProvider.apple)),
    );
  });

  testWidgets('the running option shows its label and the others are off', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Continue with Google'));
    await emit(tester, const AuthFormState(status: AuthFormStatus.loading));

    expect(find.text('Signing in…'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
    await tester.tap(find.text('Continue with Apple'));
    await tester.tap(find.text('Use email instead'));
    verify(() => form.signInWith(SocialProvider.google)).called(1);
    verifyNever(() => form.signInWith(SocialProvider.apple));
    expect(find.text('Other options'), findsNothing);
  });

  testWidgets('the guest link shows only while nobody is signed in', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Continue as guest'));
    verify(() => form.continueAsGuest()).called(1);

    await pump(
      tester,
      auth: const Authenticated(AuthUser(id: 'g1', isAnonymous: true)),
    );
    expect(find.text('Continue as guest'), findsNothing);
  });

  testWidgets('the terms line links Terms and Privacy Policy', (tester) async {
    await pump(tester);
    expect(find.text('Terms'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });

  Future<void> typeAndSubmit(
    WidgetTester tester,
    String email,
    String password,
    String submit,
  ) async {
    await tester.enterText(find.byType(EditableText).at(0), email);
    await tester.enterText(find.byType(EditableText).at(1), password);
    await tester.tap(find.widgetWithText(ForgeButton, submit).last);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Use email instead opens the form; Other options goes back', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Use email instead'));
    await tester.pump();

    expect(find.text('Sign in with email'), findsOneWidget);
    await tester.tap(find.text('Other options'));
    await tester.pump();
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('the form checks the fields inline before signing in', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Use email instead'));
    await tester.pump();

    await typeAndSubmit(tester, 'sam@example', '123', 'Sign in');
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Use at least 6 characters'), findsOneWidget);
    verifyNever(() => form.signIn(any(), any()));

    await typeAndSubmit(tester, 'sam@example.com', 'secret1', 'Sign in');
    expect(find.text('Enter a valid email'), findsNothing);
    verify(() => form.signIn('sam@example.com', 'secret1')).called(1);
  });

  testWidgets('a wrong password shows under the password field', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Use email instead'));
    await tester.pump();
    await typeAndSubmit(tester, 'sam@example.com', 'secret1', 'Sign in');

    await emit(
      tester,
      const AuthFormState(
        status: AuthFormStatus.failure,
        failure: AuthFailure('x', code: 'invalid-credential'),
      ),
    );
    expect(find.text('Email or password is incorrect'), findsOneWidget);
    expect(find.byType(ForgeSnackbar), findsNothing);
  });

  testWidgets('create mode opens first and shows an email in use inline', (
    tester,
  ) async {
    await pump(tester, initialSignUp: true);
    expect(find.text('Forgot password?'), findsNothing);
    await typeAndSubmit(tester, 'sam@example.com', 'secret1', 'Create account');
    verify(() => form.signUp('sam@example.com', 'secret1')).called(1);

    await emit(
      tester,
      const AuthFormState(
        status: AuthFormStatus.failure,
        failure: AuthFailure('x', code: 'email-already-in-use'),
      ),
    );
    expect(find.text('This email is already registered'), findsOneWidget);
  });

  testWidgets('any other failure is the snackbar with Retry', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Continue with Google'));
    await emit(
      tester,
      const AuthFormState(
        status: AuthFormStatus.failure,
        failure: NetworkFailure(),
      ),
    );

    expect(find.text("Sign-in didn't finish. Try again."), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Retry'));
    verify(() => form.retry()).called(1);
  });

  testWidgets('replacing the guest asks first', (tester) async {
    await pump(
      tester,
      auth: const Authenticated(AuthUser(id: 'g1', isAnonymous: true)),
    );
    await emit(
      tester,
      const AuthFormState(status: AuthFormStatus.confirmReplaceGuest),
    );
    await tester.pumpAndSettle();

    expect(find.text('Use existing account?'), findsOneWidget);
    await tester.tap(find.text('Use existing account'));
    await tester.pumpAndSettle();
    verify(() => form.confirmReplaceGuest()).called(1);
  });
}
