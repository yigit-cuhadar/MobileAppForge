import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:forge_ui/src/widgets/busy_ring.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ),
  );

  group('ForgeButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await pump(tester, ForgeButton(label: 'Start', onPressed: () => taps++));

      await tester.tap(find.text('Start'));

      expect(taps, 1);
    });

    testWidgets('takes taps across a 44px band around the 40px box', (
      tester,
    ) async {
      var taps = 0;
      await pump(tester, ForgeButton(label: 'Start', onPressed: () => taps++));
      final band = tester.getRect(find.byType(ForgeButton));

      expect(band.height, ForgeTheme.tapMin);
      expect(
        tester.getSize(find.byType(Container).first).height,
        ForgeTheme.buttonHeight,
      );
      await tester.tapAt(band.topCenter + const Offset(0, 1));

      expect(taps, 1);
    });

    testWidgets('the small form is 32px with a 44px band', (tester) async {
      await pump(
        tester,
        ForgeButton(
          label: 'Start',
          size: ForgeButtonSize.small,
          onPressed: () {},
        ),
      );

      expect(
        tester.getSize(find.byType(ForgeButton)).height,
        ForgeTheme.tapMin,
      );
      expect(
        tester.getSize(find.byType(Container).first).height,
        ForgeButton.smallHeight,
      );
    });

    testWidgets('the large form is 48px and full width', (tester) async {
      await pump(
        tester,
        ForgeButton(
          label: 'Continue',
          size: ForgeButtonSize.large,
          onPressed: () {},
        ),
      );

      final size = tester.getSize(find.byType(ForgeButton));
      expect(size.height, ForgeTheme.buttonHeightLg);
      expect(size.width, 800);
    });

    testWidgets('reads as a disabled button without onPressed', (tester) async {
      await pump(tester, const ForgeButton(label: 'Save', onPressed: null));

      expect(
        tester.getSemantics(find.byType(ForgeButton)),
        matchesSemantics(isButton: true, hasEnabledState: true, label: 'Save'),
      );
    });

    testWidgets('shows a spinner and ignores taps while loading', (
      tester,
    ) async {
      var taps = 0;
      await pump(
        tester,
        ForgeButton(label: 'Saving', loading: true, onPressed: () => taps++),
      );

      await tester.tap(find.text('Saving'));

      expect(taps, 0);
      expect(find.byType(BusyRing), findsOneWidget);
    });

    testWidgets('a locked button shows a lock and stays tappable', (
      tester,
    ) async {
      var taps = 0;
      await pump(
        tester,
        ForgeButton(label: 'Start', locked: true, onPressed: () => taps++),
      );

      await tester.tap(find.text('Start'));

      expect(taps, 1);
      expect(
        find.byWidgetPredicate(
          (w) => w is ForgeIcon && w.icon == ForgeIcons.lock,
        ),
        findsOneWidget,
      );
    });

    testWidgets('draws a trailing icon after the label', (tester) async {
      await pump(
        tester,
        ForgeButton(
          label: 'Get [SYSTEM APP]',
          trailingIcon: ForgeIcons.openInNew,
          onPressed: () {},
        ),
      );

      final icon = find.byWidgetPredicate(
        (w) => w is ForgeIcon && w.icon == ForgeIcons.openInNew,
      );
      expect(icon, findsOneWidget);
      expect(
        tester.getCenter(icon).dx,
        greaterThan(tester.getCenter(find.text('Get [SYSTEM APP]')).dx),
      );
    });

    testWidgets('the primary fill darkens while pressed', (tester) async {
      await pump(tester, ForgeButton(label: 'Start', onPressed: () {}));
      final p = ForgeStyle.of(tester.element(find.text('Start'))).colors;
      Color? fill() =>
          (tester.widget<Container>(find.byType(Container).first).decoration!
                  as BoxDecoration)
              .color;

      expect(fill(), p.accent);
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Start')),
      );
      await tester.pump();

      expect(fill(), Color.lerp(p.accent, p.ink, 0.18));
      await gesture.up();
    });
  });

  group('ForgeAddButton', () {
    testWidgets('is full width and calls onPressed', (tester) async {
      var taps = 0;
      await pump(
        tester,
        ForgeAddButton(label: 'Add item', onPressed: () => taps++),
      );

      await tester.tap(find.text('Add item'));

      expect(taps, 1);
      expect(tester.getSize(find.byType(ForgeAddButton)).width, 800);
    });
  });
}
