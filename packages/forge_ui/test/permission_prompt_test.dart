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

  testWidgets('a note sits muted under the buttons', (tester) async {
    await pump(
      tester,
      PermissionPrompt.ask(
        icon: ForgeIcons.favorite,
        title: 'See your [DATA] here',
        message: 'Nothing else is read.',
        allowLabel: 'Allow access',
        onAllow: () {},
        note: 'Turned it off before? Open [SETTINGS].',
      ),
    );

    final note = find.text('Turned it off before? Open [SETTINGS].');
    expect(
      tester.getTopLeft(note).dy,
      greaterThan(tester.getBottomLeft(find.byType(ForgeButton)).dy),
    );
    final context = tester.element(note);
    expect(
      tester.widget<Text>(note).style?.color,
      ForgeStyle.of(context).colors.inkMuted,
    );
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

    // The buttons at the page's foot, the text centred in the room above.
    final page = tester.getRect(find.byType(Scaffold));
    final skip = tester.getRect(find.widgetWithText(ForgeButton, 'Not now'));
    expect(page.bottom - skip.bottom, lessThan(40));
    final title = tester.getRect(find.text('Turn on reminders?'));
    expect(title.center.dy, lessThan(page.center.dy));
    expect(title.top, greaterThan(page.top + page.height / 4));
  });

  testWidgets('a full page on a short screen scrolls', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 360)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(
      tester,
      PermissionPrompt.ask(
        icon: ForgeIcons.notifications,
        title: 'Turn on reminders?',
        message: 'One reminder at the time you choose.',
        allowLabel: 'Turn on reminders',
        onAllow: () {},
        skipLabel: 'Not now',
        onSkip: () {},
        page: true,
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Not now'), 50);
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

  testWidgets('unavailable has one secondary button and nothing to ask', (
    tester,
  ) async {
    var skipped = 0;
    await pump(
      tester,
      PermissionPrompt.unavailable(
        icon: ForgeIcons.noPhotography,
        title: 'No [DEVICE] found',
        message: 'This device has no [DEVICE].',
        skipLabel: 'Skip',
        onSkip: () => skipped++,
      ),
    );

    expect(find.byType(ForgeButton), findsOneWidget);
    expect(button(tester, 'Skip').variant, ForgeButtonVariant.secondary);
    expect(button(tester, 'Skip').size, ForgeButtonSize.regular);
    await tester.tap(find.text('Skip'));
    expect(skipped, 1);
  });

  testWidgets('unavailable without a skip has no button', (tester) async {
    await pump(
      tester,
      const PermissionPrompt.unavailable(
        icon: ForgeIcons.noPhotography,
        title: 'No [DEVICE] found',
        message: 'This device has no [DEVICE].',
      ),
    );

    expect(find.byType(ForgeButton), findsNothing);
    expect(find.text('No [DEVICE] found'), findsOneWidget);
  });

  testWidgets('unavailable as a page has the 48px button', (tester) async {
    await pump(
      tester,
      PermissionPrompt.unavailable(
        icon: ForgeIcons.noPhotography,
        title: 'No [DEVICE] found',
        message: 'This device has no [DEVICE].',
        skipLabel: 'Skip',
        onSkip: () {},
        page: true,
      ),
    );

    expect(button(tester, 'Skip').size, ForgeButtonSize.large);
  });

  testWidgets('consent as a page has two equal 48px secondary buttons', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(
      tester,
      PermissionPrompt.consent(
        icon: ForgeIcons.barChart,
        title: 'Help improve [APP NAME]?',
        message: 'Share usage statistics from this device.',
        allowLabel: 'Allow',
        onAllow: () => taps.add('allow'),
        declineLabel: "Don't allow",
        onDecline: () => taps.add('decline'),
        page: true,
      ),
    );

    for (final label in ['Allow', "Don't allow"]) {
      expect(button(tester, label).variant, ForgeButtonVariant.secondary);
      expect(button(tester, label).size, ForgeButtonSize.large);
    }
    final allow = tester.getRect(find.widgetWithText(ForgeButton, 'Allow'));
    final decline = tester.getRect(
      find.widgetWithText(ForgeButton, "Don't allow"),
    );
    expect(allow.size, decline.size);
    expect(allow.bottom, lessThanOrEqualTo(decline.top));
    await tester.tap(find.text('Allow'));
    await tester.tap(find.text("Don't allow"));
    expect(taps, ['allow', 'decline']);
  });

  testWidgets('consent in a card has two regular secondary buttons', (
    tester,
  ) async {
    await pump(
      tester,
      PermissionPrompt.consent(
        icon: ForgeIcons.barChart,
        title: 'Help improve [APP NAME]?',
        message: 'Share usage statistics from this device.',
        allowLabel: 'Allow',
        onAllow: () {},
        declineLabel: "Don't allow",
        onDecline: () {},
      ),
    );

    for (final label in ['Allow', "Don't allow"]) {
      expect(button(tester, label).variant, ForgeButtonVariant.secondary);
      expect(button(tester, label).size, ForgeButtonSize.regular);
    }
  });

  group('dialog', () {
    Future<void> open(WidgetTester tester, List<String> taps) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showForgeDialog<void>(
                  context: context,
                  builder: (context) => PermissionPrompt.dialog(
                    icon: ForgeIcons.notifications,
                    title: 'Allow notifications?',
                    message: 'Reminders are notifications.',
                    allowLabel: 'Allow',
                    onAllow: () {
                      taps.add('allow');
                      Navigator.pop(context);
                    },
                    notNowLabel: 'Not now',
                    onNotNow: () {
                      taps.add('later');
                      Navigator.pop(context);
                    },
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('a muted icon in a 44px circle, Allow over Not now', (
      tester,
    ) async {
      final taps = <String>[];
      await open(tester, taps);

      expect(find.byType(Dialog), findsOneWidget);
      final icon = tester.widget<ForgeIcon>(
        find.descendant(
          of: find.byType(PermissionPrompt),
          matching: find.byType(ForgeIcon),
        ),
      );
      final colors = ForgeStyle.of(
        tester.element(find.byType(PermissionPrompt)),
      ).colors;
      expect(icon.color, colors.inkMuted);
      expect(icon.size, 22);
      expect(button(tester, 'Allow').variant, ForgeButtonVariant.primary);
      expect(button(tester, 'Not now').variant, ForgeButtonVariant.text);
      final allow = tester.getRect(find.widgetWithText(ForgeButton, 'Allow'));
      final later = tester.getRect(find.widgetWithText(ForgeButton, 'Not now'));
      expect(allow.width, later.width);
      expect(allow.bottom, lessThanOrEqualTo(later.top));

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      await open(tester, taps);
      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();
      expect(taps, ['later', 'allow']);
    });

    testWidgets('names its route by the title', (tester) async {
      final semantics = tester.ensureSemantics();
      await open(tester, []);
      expect(find.bySemanticsLabel('Allow notifications?'), findsWidgets);
      semantics.dispose();
    });

    for (final scale in [2.0, 3.0]) {
      testWidgets('lays out at ${scale}x text', (tester) async {
        tester.view
          ..physicalSize = const Size(390, 844)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: ForgeTheme.light(),
            builder: (context, page) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: page!,
            ),
            home: PermissionPrompt.dialog(
              icon: ForgeIcons.timer,
              title: 'Notify when a rest ends?',
              message: 'Get a notification when a rest is over.',
              allowLabel: 'Allow',
              onAllow: () {},
              notNowLabel: 'Not now',
              onNotNow: () {},
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  for (final scale in [2.0, 3.0]) {
    testWidgets('consent as a page lays out at ${scale}x text', (tester) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          builder: (context, page) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: page!,
          ),
          home: Scaffold(
            body: PermissionPrompt.consent(
              icon: ForgeIcons.barChart,
              title: 'Help improve [APP NAME]?',
              message: 'Share usage statistics from this device.',
              allowLabel: 'Allow',
              onAllow: () {},
              declineLabel: "Don't allow",
              onDecline: () {},
              page: true,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
