import 'dart:ui' show SemanticsRole;

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
              skipLabel: skip ? 'Skip' : null,
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

  group('list form', () {
    Future<void> pumpList(
      WidgetTester tester,
      ChoiceListForm form, {
      int? selected,
    }) => tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: Scaffold(
          body: ChoiceGrid.list(
            form: form,
            options: const [
              ChoiceOption(label: 'Option one', hint: '[HINT]'),
              ChoiceOption(label: 'Option two', hint: '[HINT]'),
            ],
            selected: selected,
            onSelected: picks.add,
          ),
        ),
      ),
    );

    Finder rowOf(String label) => find
        .ancestor(of: find.text(label), matching: find.byType(Container))
        .last;

    testWidgets('has no card or header, and a tap picks a row', (tester) async {
      await pumpList(tester, ChoiceListForm.inline);

      expect(find.text('Question title'), findsNothing);
      await tester.tap(find.text('Option two'));

      expect(picks, [1]);
    });

    testWidgets('inline rows are 44px with the hint beside the label', (
      tester,
    ) async {
      await pumpList(tester, ChoiceListForm.inline);

      expect(tester.getSize(rowOf('Option one')).height, 44);
      expect(
        tester.getCenter(find.text('[HINT]').first).dx,
        greaterThan(tester.getCenter(find.text('Option one')).dx),
      );
    });

    testWidgets('stacked rows are 60px with the hint under the label', (
      tester,
    ) async {
      await pumpList(tester, ChoiceListForm.stacked);

      expect(tester.getSize(rowOf('Option one')).height, 60);
      expect(
        tester.getTopLeft(find.text('[HINT]').first).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.text('Option one')).dy),
      );
    });

    testWidgets('reads as a radio group with the chosen row checked', (
      tester,
    ) async {
      await pumpList(tester, ChoiceListForm.stacked, selected: 0);

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics && w.properties.role == SemanticsRole.radioGroup,
        ),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.text('Option one')),
        matchesSemantics(
          label: 'Option one\n[HINT]',
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
    });
  });
}
