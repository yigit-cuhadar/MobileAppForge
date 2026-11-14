import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, ForgeBottomActionBar bar) =>
      tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          home: Scaffold(bottomNavigationBar: bar),
        ),
      );

  final primary = FilledButton(onPressed: () {}, child: const Text('Next'));
  final secondary = ElevatedButton(onPressed: () {}, child: const Text('Back'));

  Rect rect(WidgetTester tester, String text) => tester.getRect(
    find.ancestor(
      of: find.text(text),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    ),
  );

  testWidgets('one action fills the bar inside its padding', (tester) async {
    await pump(tester, ForgeBottomActionBar(primary: primary));

    expect(
      rect(tester, 'Next').width,
      tester.getSize(find.byType(ForgeBottomActionBar)).width - 2 * Gap.md,
    );
  });

  testWidgets('side by side, the primary is twice the secondary', (
    tester,
  ) async {
    await pump(
      tester,
      ForgeBottomActionBar.sideBySide(secondary: secondary, primary: primary),
    );

    final back = rect(tester, 'Back');
    final next = rect(tester, 'Next');
    expect(back.right, lessThan(next.left));
    expect(next.width, closeTo(back.width * 2, 1));
  });

  testWidgets('stacked, the primary sits on top', (tester) async {
    await pump(
      tester,
      ForgeBottomActionBar.stacked(primary: primary, secondary: secondary),
    );

    expect(rect(tester, 'Next').bottom, lessThan(rect(tester, 'Back').top));
    expect(rect(tester, 'Next').width, rect(tester, 'Back').width);
  });

  testWidgets('a count reads ink and bold, or ink-muted when none is '
      'chosen', (tester) async {
    await pump(
      tester,
      ForgeBottomActionBar.count(count: '3 chosen', action: primary),
    );
    final colors = ForgeStyle.of(
      tester.element(find.byType(ForgeBottomActionBar)),
    ).colors;
    var style = tester.widget<Text>(find.text('3 chosen')).style!;
    expect(style.color, colors.ink);
    expect(style.fontWeight, FontWeight.w600);
    expect(rect(tester, 'Next').width, greaterThanOrEqualTo(120));

    await pump(
      tester,
      const ForgeBottomActionBar.count(
        count: 'None chosen',
        none: true,
        action: FilledButton(onPressed: null, child: Text('Next')),
      ),
    );
    style = tester.widget<Text>(find.text('None chosen')).style!;
    expect(style.color, colors.inkMuted);
    expect(style.fontWeight, FontWeight.w400);
  });

  testWidgets('a large Button beside a count sizes to its label, at least '
      '120 wide', (tester) async {
    await pump(
      tester,
      ForgeBottomActionBar.count(
        count: '3 chosen',
        action: ForgeButton(
          label: 'Next',
          onPressed: () {},
          size: ForgeButtonSize.large,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final button = tester.getRect(find.byType(ForgeButton));
    expect(button.width, greaterThanOrEqualTo(120));
    expect(
      button.right,
      tester.getSize(find.byType(ForgeBottomActionBar)).width - Gap.md,
    );
    expect(tester.getRect(find.text('3 chosen')).right, lessThan(button.left));
  });

  testWidgets('the bar pads to the bottom inset', (tester) async {
    tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
    addTearDown(tester.view.resetPadding);
    await pump(tester, ForgeBottomActionBar(primary: primary));

    final bar = tester.getRect(find.byType(ForgeBottomActionBar));
    expect(bar.bottom - rect(tester, 'Next').bottom, Gap.md + 34);
  });
}
