import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:forge_ui/src/widgets/busy_ring.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    // A phone-sized screen tall enough for the whole email form.
    tester.view
      ..physicalSize = const Size(400, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(theme: ForgeTheme.light(), home: child),
    );
  }

  SignInPage page(
    List<String> taps, {
    SignInOption? running,
    SignInEmailForm? email,
  }) => SignInPage(
    mark: const Text('A'),
    name: '[APP NAME]',
    tagline: '[TAGLINE]',
    apple: SignInProvider(
      mark: const SizedBox.square(dimension: 18),
      label: 'Continue with Apple',
      onPressed: () => taps.add('apple'),
    ),
    google: SignInProvider(
      mark: const SizedBox.square(dimension: 18),
      label: 'Continue with Google',
      onPressed: () => taps.add('google'),
    ),
    useEmailLabel: 'Use email instead',
    onUseEmail: () => taps.add('email'),
    guestLabel: 'Continue as guest',
    onGuest: () => taps.add('guest'),
    terms: SignInTerms(
      text: 'By continuing you agree to the {terms} and {privacy}.',
      termsLabel: 'Terms',
      onTerms: () => taps.add('terms'),
      privacyLabel: 'Privacy Policy',
      onPrivacy: () => taps.add('privacy'),
    ),
    signingInLabel: 'Signing in…',
    email: email,
    running: running,
  );

  SignInEmailForm signInForm(
    List<String> taps, {
    String? emailError,
    String? passwordError,
  }) => SignInEmailForm(
    backLabel: 'Other options',
    onBack: () => taps.add('back'),
    title: 'Sign in with email',
    emailLabel: 'Email',
    passwordLabel: 'Password',
    submitLabel: 'Sign in',
    onSubmit: (email, password) => taps.add('submit $email $password'),
    forgotPasswordLabel: 'Forgot password?',
    onForgotPassword: (email) => taps.add('forgot $email'),
    switchLabel: "Don't have an account? Create one",
    onSwitch: () => taps.add('create'),
    emailError: emailError,
    passwordError: passwordError,
  );

  testWidgets('every option reports its tap', (tester) async {
    final taps = <String>[];
    await pump(tester, page(taps));

    for (final label in [
      'Continue with Apple',
      'Continue with Google',
      'Use email instead',
      'Continue as guest',
    ]) {
      await tester.tap(find.text(label));
    }
    expect(taps, ['apple', 'google', 'email', 'guest']);
  });

  testWidgets('the terms line opens each document', (tester) async {
    final taps = <String>[];
    await pump(tester, page(taps));

    await tester.tap(find.text('Terms'));
    await tester.tap(find.text('Privacy Policy'));
    expect(taps, ['terms', 'privacy']);
  });

  testWidgets('while one option runs it says so and the others are off', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(tester, page(taps, running: SignInOption.apple));

    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Signing in…'), findsOneWidget);
    expect(find.byType(BusyRing), findsOneWidget);
    final colors = ForgeStyle.of(
      tester.element(find.text('Continue with Google')),
    ).colors;
    expect(
      tester.widget<Text>(find.text('Continue with Google')).style!.color,
      colors.lineStrong,
    );
    for (final label in [
      'Signing in…',
      'Continue with Google',
      'Use email instead',
      'Continue as guest',
    ]) {
      await tester.tap(find.text(label));
    }
    expect(taps, isEmpty);
  });

  testWidgets('the email form keeps the block and replaces the options', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(tester, page(taps, email: signInForm(taps)));

    expect(find.text('[APP NAME]'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Terms'), findsNothing);

    await tester.enterText(find.byType(TextField).first, ' name@example.com ');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.tap(find.text('Sign in'));
    await tester.tap(find.text('Forgot password?'));
    await tester.tap(find.text("Don't have an account? Create one"));
    await tester.tap(find.text('Other options'));
    expect(taps, [
      'submit name@example.com secret',
      'forgot name@example.com',
      'create',
      'back',
    ]);
  });

  testWidgets('the email form shows the errors under their fields', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(tester, page(taps, email: signInForm(taps)));
    await pump(
      tester,
      page(
        taps,
        email: signInForm(
          taps,
          emailError: 'Enter a valid email',
          passwordError: 'Use at least 6 characters',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Use at least 6 characters'), findsOneWidget);
  });

  testWidgets('switching to the create form keeps what was typed', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(tester, page(taps, email: signInForm(taps)));
    await tester.enterText(find.byType(TextField).first, 'name@example.com');

    await pump(
      tester,
      page(
        taps,
        email: SignInEmailForm(
          backLabel: 'Other options',
          onBack: () {},
          title: 'Create account',
          emailLabel: 'Email',
          passwordLabel: 'Password',
          submitLabel: 'Create account',
          onSubmit: (email, _) => taps.add('create $email'),
          switchLabel: 'Already have an account? Sign in',
          onSwitch: () {},
        ),
      ),
    );

    expect(find.text('Forgot password?'), findsNothing);
    await tester.tap(find.widgetWithText(ForgeButton, 'Create account'));
    expect(taps, ['create name@example.com']);
  });

  testWidgets('while the email sign-in runs the form holds', (tester) async {
    final taps = <String>[];
    await pump(
      tester,
      page(taps, email: signInForm(taps), running: SignInOption.email),
    );

    expect(
      tester
          .widget<ForgeButton>(find.widgetWithText(ForgeButton, 'Sign in'))
          .loading,
      isTrue,
    );
    await tester.tap(find.text('Sign in'));
    await tester.tap(find.text('Forgot password?'));
    await tester.tap(find.text("Don't have an account? Create one"));
    await tester.tap(find.text('Other options'));
    expect(taps, isEmpty);
  });

  testWidgets('replacing guest data asks first', (tester) async {
    bool? answer;
    await pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => answer = await confirmReplaceGuestData(
              context,
              title: 'Use existing account?',
              message: "This device's guest data will be replaced.",
              confirmLabel: 'Use existing account',
              cancelLabel: 'Cancel',
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final confirm = tester.widget<ForgeButton>(
      find.widgetWithText(ForgeButton, 'Use existing account'),
    );
    expect(confirm.variant, ForgeButtonVariant.danger);
    await tester.tap(find.text('Use existing account'));
    await tester.pumpAndSettle();
    expect(answer, isTrue);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(answer, isFalse);
  });
}
