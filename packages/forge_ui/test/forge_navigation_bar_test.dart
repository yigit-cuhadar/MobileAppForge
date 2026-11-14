import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  const destinations = [
    ForgeDestination(icon: ForgeIcons.home, label: '[TAB 1]'),
    ForgeDestination(icon: ForgeIcons.list, label: '[TAB 2]'),
    ForgeDestination(icon: ForgeIcons.person, label: '[TAB 3]'),
  ];

  Future<List<int>> pump(WidgetTester tester, {int selected = 0}) async {
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: Scaffold(
          bottomNavigationBar: ForgeNavigationBar(
            destinations: destinations,
            selectedIndex: selected,
            onSelected: taps.add,
          ),
        ),
      ),
    );
    return taps;
  }

  ForgeIcon icon(WidgetTester tester, String label) => tester.widget(
    find.descendant(
      of: find.bySemanticsLabel(label),
      matching: find.byType(ForgeIcon),
    ),
  );

  Text text(WidgetTester tester, String label) =>
      tester.widget(find.text(label));

  testWidgets('a tap selects that tab', (tester) async {
    final taps = await pump(tester);

    await tester.tap(find.text('[TAB 3]'));
    await tester.tap(find.text('[TAB 2]'));
    expect(taps, [2, 1]);
  });

  testWidgets('the selected tab is accent, heavier and bold', (tester) async {
    await pump(tester, selected: 1);
    final colors = ForgeStyle.of(
      tester.element(find.byType(ForgeNavigationBar)),
    ).colors;

    expect(icon(tester, '[TAB 2]').weight, ForgeIcon.selectedWeight);
    expect(icon(tester, '[TAB 2]').color, colors.accent);
    expect(text(tester, '[TAB 2]').style!.fontWeight, FontWeight.w700);
    expect(text(tester, '[TAB 2]').style!.color, colors.accent);

    expect(icon(tester, '[TAB 1]').weight, lessThan(ForgeIcon.selectedWeight));
    expect(icon(tester, '[TAB 1]').color, colors.inkSubtle);
    expect(text(tester, '[TAB 1]').style!.fontWeight, FontWeight.w500);
  });

  testWidgets('tabs report selection and share the 72px bar', (tester) async {
    await pump(tester, selected: 2);

    expect(
      tester.getSemantics(find.bySemanticsLabel('[TAB 3]')),
      isSemantics(
        label: '[TAB 3]',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(tester.getSize(find.byType(ForgeNavigationBar)).height, 72 + 1);
  });
}
