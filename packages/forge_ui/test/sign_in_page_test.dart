import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(MaterialApp(theme: ForgeTheme.light(), home: child));

  SignInPage page(List<String> taps, {SignInOption? running}) => SignInPage(
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
    terms: 'By continuing you agree to the Terms and Privacy Policy.',
    signingInLabel: 'Signing in…',
    running: running,
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

  testWidgets('while one option runs it says so and the others are off', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(tester, page(taps, running: SignInOption.apple));

    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Signing in…'), findsOneWidget);
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

  testWidgets('the email form sends what was typed and shows field errors', (
    tester,
  ) async {
    final sent = <(String, String)>[];
    var back = 0;
    Widget form({String? passwordError}) => SignInEmailPage(
      backLabel: 'Other options',
      onBack: () => back++,
      title: 'Sign in with email',
      emailLabel: 'Email',
      passwordLabel: 'Password',
      signInLabel: 'Sign in',
      onSignIn: (email, password) => sent.add((email, password)),
      passwordError: passwordError,
    );
    await pump(tester, form());

    await tester.enterText(find.byType(TextField).first, ' name@example.com ');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.tap(find.text('Sign in'));
    expect(sent, [('name@example.com', 'secret')]);

    await pump(tester, form(passwordError: 'Wrong password. Try again.'));
    await tester.pump();
    expect(find.text('Wrong password. Try again.'), findsOneWidget);

    await tester.tap(find.text('Other options'));
    expect(back, 1);
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
