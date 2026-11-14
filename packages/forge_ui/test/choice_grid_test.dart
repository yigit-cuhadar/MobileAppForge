import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  late List<int> picks;
  late int skips;

  setUp(() {
    picks = [];
    skips = 0;
  });

  Future<void> pump(WidgetTester tester, {int? selected, bool skip = false}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          home: Scaffold(
            body: ChoiceGrid(
              title: 'Question title',
              detail: '[CONTEXT]',
              options: const [
                ChoiceOption(label: 'Option one', hint: '[HINT]'),
                ChoiceOption(label: 'Option two', hint: '[HINT]'),
                ChoiceOption(label: 'Option three', hint: '[HINT]'),
              ],
              selected: selected,
              onSelected: picks.add,
              onSkip: skip ? () => skips++ : null,
            ),
          ),
        ),
      );

  testWidgets('a tap on a row picks it', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Option two'));

    expect(picks, [1]);
  });

  testWidgets('Skip shows only with onSkip', (tester) async {
    await pump(tester);
    expect(find.text('Skip'), findsNothing);

    await pump(tester, skip: true);
    await tester.tap(find.text('Skip'));

    expect(skips, 1);
  });

  testWidgets('the chosen row reads as checked in a group', (tester) async {
    await pump(tester, selected: 2);

    expect(
      tester.getSemantics(find.text('Option three')),
      matchesSemantics(
        label: 'Option three\n[HINT]',
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
  });

  testWidgets('a focused row takes Enter', (tester) async {
    await pump(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(picks, [0]);
  });
}
