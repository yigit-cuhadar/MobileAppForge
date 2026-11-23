import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(MaterialApp(theme: ForgeTheme.light(), home: child));

  const background = Color(0xFF222B38);
  const foreground = Color(0xFFEEF1F5);

  testWidgets('the slow-start line appears only after the delay', (
    tester,
  ) async {
    await pump(
      tester,
      const SplashScreen(
        mark: SizedBox.square(dimension: 26),
        name: '[APP NAME]',
        background: background,
        foreground: foreground,
        slowAfter: Duration(seconds: 2),
      ),
    );

    expect(find.text('[APP NAME]'), findsOneWidget);
    expect(find.byType(ClipRRect), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(ClipRRect), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets("couldn't start keeps the mark and name over an outline Retry", (
    tester,
  ) async {
    var retries = 0;
    await pump(
      tester,
      SplashScreen.failed(
        mark: const SizedBox.square(dimension: 26),
        name: '[APP NAME]',
        background: background,
        foreground: foreground,
        message: "Couldn't start. Check your connection and try again.",
        retryLabel: 'Retry',
        onRetry: () => retries++,
      ),
    );

    expect(find.text('[APP NAME]'), findsOneWidget);
    expect(
      find.text("Couldn't start. Check your connection and try again."),
      findsOneWidget,
    );
    expect(find.byType(ClipRRect), findsNothing);
    final retry = tester.widget<ForgeButton>(find.byType(ForgeButton));
    expect(retry.variant, ForgeButtonVariant.outline);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('a start after Retry waits again before the slow line', (
    tester,
  ) async {
    const starting = SplashScreen(
      mark: SizedBox.square(dimension: 26),
      name: '[APP NAME]',
      background: background,
      foreground: foreground,
      slowAfter: Duration(seconds: 2),
    );
    await pump(tester, starting);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(ClipRRect), findsOneWidget);

    await pump(
      tester,
      SplashScreen.failed(
        mark: const SizedBox.square(dimension: 26),
        name: '[APP NAME]',
        background: background,
        foreground: foreground,
        message: "Couldn't start. Check your connection and try again.",
        retryLabel: 'Retry',
        onRetry: () {},
      ),
    );
    await pump(tester, starting);
    expect(find.byType(ClipRRect), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(ClipRRect), findsOneWidget);
  });

  testWidgets('a logo stands alone in place of the tile and the name', (
    tester,
  ) async {
    await pump(
      tester,
      const SplashScreen(
        mark: Text('mark'),
        name: '[APP NAME]',
        background: foreground,
        foreground: background,
        slowAfter: Duration(days: 1),
        logo: ColoredBox(key: Key('logo'), color: background),
      ),
    );

    expect(find.byKey(const Key('logo')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('logo'))),
      const Size.square(SplashScreen.logoSize),
    );
    expect(find.text('mark'), findsNothing);
    expect(find.text('[APP NAME]'), findsNothing);
    expect(find.bySemanticsLabel('[APP NAME]'), findsOneWidget);
    // In the middle of the whole screen, as a native launch screen has it.
    expect(
      tester.getCenter(find.byKey(const Key('logo'))),
      tester.getCenter(find.byType(SplashScreen)),
    );
  });
}
