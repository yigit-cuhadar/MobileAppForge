import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(body: child),
    ),
  );

  ForgeButton button(WidgetTester tester, String label) =>
      tester.widget<ForgeButton>(find.widgetWithText(ForgeButton, label));

  testWidgets('asking in a card allows with a primary button', (tester) async {
    var allowed = 0;
    await pump(
      tester,
      PermissionPrompt.ask(
        icon: ForgeIcons.favorite,
        title: 'See your [DATA] here',
        message: 'Nothing else is read.',
        allowLabel: 'Allow access',
        onAllow: () => allowed++,
      ),
    );

    expect(button(tester, 'Allow access').variant, ForgeButtonVariant.primary);
    expect(button(tester, 'Allow access').size, ForgeButtonSize.regular);
    await tester.tap(find.text('Allow access'));
    expect(allowed, 1);
  });

  testWidgets('the full page has the 48px button and a skip link', (
    tester,
  ) async {
    var skipped = 0;
    await pump(
      tester,
      PermissionPrompt.ask(
        icon: ForgeIcons.notifications,
        title: 'Turn on reminders?',
        message: 'One reminder at the time you choose.',
        allowLabel: 'Turn on reminders',
        onAllow: () {},
        skipLabel: 'Not now',
        onSkip: () => skipped++,
        page: true,
      ),
    );

    expect(button(tester, 'Turn on reminders').size, ForgeButtonSize.large);
    expect(button(tester, 'Not now').variant, ForgeButtonVariant.text);
    await tester.tap(find.text('Not now'));
    expect(skipped, 1);
  });

  testWidgets('refused offers Ask again only when given', (tester) async {
    await pump(
      tester,
      PermissionPrompt.refused(
        title: 'Access is off',
        message: 'Turn access on in Settings.',
        settingsLabel: 'Open settings',
        onOpenSettings: () {},
      ),
    );

    expect(find.byType(ForgeButton), findsOneWidget);
    final icon = tester.widget<ForgeIcon>(find.byType(ForgeIcon));
    expect(icon.icon, ForgeIcons.block);
  });

  testWidgets('failed shows the icon in danger and an outline Retry', (
    tester,
  ) async {
    var retries = 0;
    await pump(
      tester,
      PermissionPrompt.failed(
        title: "Couldn't ask for access",
        message: 'Try again in a moment.',
        retryLabel: 'Retry',
        onRetry: () => retries++,
      ),
    );

    final colors = ForgeStyle.of(tester.element(find.byType(PermissionPrompt)))
        .colors;
    final icon = tester.widget<ForgeIcon>(
      find.descendant(
        of: find.byType(PermissionPrompt),
        matching: find.byType(ForgeIcon),
      ),
    );
    expect(icon.color, colors.danger);
    expect(button(tester, 'Retry').variant, ForgeButtonVariant.outline);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('a missing system app links to its store page', (tester) async {
    final taps = <String>[];
    await pump(
      tester,
      PermissionPrompt.missing(
        title: '[SYSTEM APP] is needed',
        message: 'Install it, then come back.',
        getLabel: 'Get [SYSTEM APP]',
        onGet: () => taps.add('get'),
        notNowLabel: 'Not now',
        onNotNow: () => taps.add('later'),
      ),
    );

    expect(
      button(tester, 'Get [SYSTEM APP]').trailingIcon,
      ForgeIcons.openInNew,
    );
    await tester.tap(find.text('Get [SYSTEM APP]'));
    await tester.tap(find.text('Not now'));
    expect(taps, ['get', 'later']);
  });
}
