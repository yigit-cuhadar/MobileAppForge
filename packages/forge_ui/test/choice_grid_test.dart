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
        hasEnabledState: true,
        isEnabled: true,
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
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
    });

    testWidgets('a row without a hint shows its label alone, centred', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          home: Scaffold(
            body: ChoiceGrid.list(
              form: ChoiceListForm.stacked,
              options: const [ChoiceOption(label: 'Option one')],
              selected: null,
              onSelected: picks.add,
            ),
          ),
        ),
      );

      expect(tester.getSize(rowOf('Option one')).height, 60);
      expect(
        tester.getCenter(find.text('Option one')).dy,
        tester.getCenter(rowOf('Option one')).dy,
      );
    });

    testWidgets('a disabled row fades, takes no tap and reads as disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          home: Scaffold(
            body: ChoiceGrid.list(
              form: ChoiceListForm.inline,
              options: const [
                ChoiceOption(label: 'Option one', hint: '[HINT]'),
                ChoiceOption(label: 'Option two', enabled: false),
              ],
              selected: null,
              onSelected: picks.add,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Option two'));
      expect(picks, isEmpty);
      expect(
        tester
            .widget<Opacity>(
              find.ancestor(
                of: find.text('Option two'),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        0.4,
      );
      expect(
        tester.getSemantics(find.text('Option two')),
        matchesSemantics(
          label: 'Option two',
          hasCheckedState: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
        ),
      );
    });

    group('tag', () {
      Future<void> pumpTag(
        WidgetTester tester,
        ChoiceListForm form, {
        double scale = 1,
      }) => tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          builder: (context, page) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: page!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 390,
                child: ChoiceGrid.list(
                  form: form,
                  options: const [
                    ChoiceOption(label: 'Option one', hint: '[HINT]'),
                    ChoiceOption(
                      label: 'Option two',
                      hint: '[HINT]',
                      tag: ForgeTag('[TAG]', kind: ForgeTagKind.record),
                    ),
                  ],
                  selected: null,
                  onSelected: picks.add,
                ),
              ),
            ),
          ),
        ),
      );

      testWidgets('sits right after its label, and a tap on it picks', (
        tester,
      ) async {
        await pumpTag(tester, ChoiceListForm.stacked);

        expect(find.byType(ForgeTag), findsOneWidget);
        final label = tester.getRect(find.text('Option two'));
        final tag = tester.getRect(find.byType(ForgeTag));
        expect(tag.left - label.right, Gap.sm);
        expect(tag.center.dy, closeTo(label.center.dy, 1));

        await tester.tap(find.text('[TAG]'));
        expect(picks, [1]);
      });

      for (final scale in [1.0, 2.0, 3.0]) {
        testWidgets('lays out at ${scale}x text', (tester) async {
          for (final form in ChoiceListForm.values) {
            await pumpTag(tester, form, scale: scale);
            expect(tester.takeException(), isNull, reason: '$form');
          }
        });
      }
    });

    group('info button', () {
      late List<String> infos;

      Future<void> pumpInfo(
        WidgetTester tester,
        ChoiceListForm form, {
        double scale = 1,
      }) {
        infos = [];
        return tester.pumpWidget(
          MaterialApp(
            theme: ForgeTheme.light(),
            builder: (context, page) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: page!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 390,
                  child: ChoiceGrid.list(
                    form: form,
                    options: [
                      for (final label in ['Option one', 'Option two'])
                        ChoiceOption(
                          label: label,
                          onInfo: () => infos.add(label),
                          infoLabel: 'Details of $label',
                        ),
                    ],
                    selected: 1,
                    onSelected: picks.add,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      testWidgets('sits at the row end and opens without picking', (
        tester,
      ) async {
        await pumpInfo(tester, ChoiceListForm.inline);

        final buttons = find.byType(ForgeIconButton);
        expect(buttons, findsNWidgets(2));
        final row = tester.getRect(rowOf('Option one'));
        final button = tester.getRect(buttons.first);
        expect(row.right - button.right, Gap.xs);
        expect(tester.getSize(rowOf('Option one')).height, 44);

        await tester.tap(buttons.first);
        expect(infos, ['Option one']);
        expect(picks, isEmpty);

        await tester.tap(find.text('Option one'));
        expect(picks, [0]);
        expect(infos, ['Option one']);
      });

      testWidgets('reads as its own labelled button', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpInfo(tester, ChoiceListForm.stacked);

        expect(find.bySemanticsLabel('Details of Option two'), findsOneWidget);
        semantics.dispose();
      });

      for (final scale in [1.0, 2.0, 3.0]) {
        testWidgets('lays out at ${scale}x text', (tester) async {
          for (final form in ChoiceListForm.values) {
            await pumpInfo(tester, form, scale: scale);
            expect(tester.takeException(), isNull, reason: '$form');
          }
        });
      }
    });
  });
}
