import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, ForgeAppBar bar) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(appBar: bar),
    ),
  );

  Future<void> push(
    WidgetTester tester, {
    bool fullscreenDialog = false,
  }) async {
    await pump(tester, const ForgeAppBar(title: 'Home'));
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          MaterialPageRoute<void>(
            fullscreenDialog: fullscreenDialog,
            builder: (_) =>
                const Scaffold(appBar: ForgeAppBar(title: 'Details')),
          ),
        );
    await tester.pumpAndSettle();
  }

  testWidgets('a tab root shows only its title, 52 high', (tester) async {
    await pump(tester, const ForgeAppBar(title: 'Home'));

    expect(find.text('Home'), findsOneWidget);
    expect(find.bySemanticsLabel('Back'), findsNothing);
    expect(find.bySemanticsLabel('Close'), findsNothing);
    expect(tester.getSize(find.byType(ForgeAppBar)).height, 52);
  });

  testWidgets('a pushed page shows back, which pops it', (tester) async {
    await push(tester);

    expect(find.bySemanticsLabel('Back'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('a page opened over the flow shows close instead of back', (
    tester,
  ) async {
    await push(tester, fullscreenDialog: true);

    expect(find.bySemanticsLabel('Back'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsNothing);
  });

  testWidgets('the title stays centred beside a wide action', (tester) async {
    await pump(
      tester,
      ForgeAppBar(
        title: 'Details',
        actions: [ForgeAppBarAction.text(label: 'Save all', onPressed: () {})],
      ),
    );

    expect(
      tester.getCenter(find.text('Details')).dx,
      tester.getCenter(find.byType(ForgeAppBar)).dx,
    );
  });

  testWidgets('a text action fades to 40% and ignores taps while off', (
    tester,
  ) async {
    await pump(
      tester,
      const ForgeAppBar(
        title: 'New item',
        actions: [ForgeAppBarAction.text(label: 'Save', onPressed: null)],
      ),
    );

    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('Save'), matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, 0.4);
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
  });

  testWidgets('an icon action fires and carries its count', (tester) async {
    var taps = 0;
    await pump(
      tester,
      ForgeAppBar(
        title: 'Item list',
        actions: [
          ForgeAppBarAction.icon(
            icon: ForgeIcons.tune,
            label: 'Filters',
            count: 2,
            onPressed: () => taps++,
          ),
        ],
      ),
    );

    expect(find.text('2'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Filters')),
      isSemantics(
        label: 'Filters',
        value: '2',
        isButton: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.bySemanticsLabel('Filters'));
    expect(taps, 1);
  });

  testWidgets('without a count there is no badge', (tester) async {
    await pump(
      tester,
      ForgeAppBar(
        title: 'Item',
        actions: [
          ForgeAppBarAction.icon(
            icon: ForgeIcons.moreVert,
            label: 'More',
            onPressed: () {},
          ),
        ],
      ),
    );

    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('status bar icons contrast with the ground', (tester) async {
    for (final (theme, expected) in [
      (ForgeTheme.light(), Brightness.dark),
      (ForgeTheme.dark(), Brightness.light),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(appBar: ForgeAppBar(title: 'Home')),
        ),
      );
      await tester.pumpAndSettle();
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.descendant(
          of: find.byType(ForgeAppBar),
          matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        ),
      );
      expect(region.value.statusBarIconBrightness, expected);
    }
  });
}
