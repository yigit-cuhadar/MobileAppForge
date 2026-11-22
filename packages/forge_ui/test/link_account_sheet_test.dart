import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget sheet) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(
        body: Align(alignment: Alignment.bottomCenter, child: sheet),
      ),
    ),
  );

  LinkAccountSheet sheet(List<String> taps, {SignInOption? running}) =>
      LinkAccountSheet(
        title: 'Keep your data',
        message: 'Create an account to back it up.',
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
        notNowLabel: 'Not now',
        onNotNow: () => taps.add('notNow'),
        signingInLabel: 'Signing in…',
        running: running,
      );

  testWidgets('every option reports its tap', (tester) async {
    final taps = <String>[];
    await pump(tester, sheet(taps));

    expect(find.text('Keep your data'), findsOneWidget);
    expect(find.text('Create an account to back it up.'), findsOneWidget);
    for (final label in [
      'Continue with Apple',
      'Continue with Google',
      'Use email instead',
      'Not now',
    ]) {
      await tester.tap(find.text(label));
    }
    expect(taps, ['apple', 'google', 'email', 'notNow']);
  });

  testWidgets('while a provider runs it says so and the rest are off', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(tester, sheet(taps, running: SignInOption.google));

    expect(find.text('Signing in…'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
    for (final label in [
      'Continue with Apple',
      'Use email instead',
      'Not now',
    ]) {
      await tester.tap(find.text(label));
    }
    await tester.tap(find.text('Signing in…'));
    expect(taps, isEmpty);
  });
}
