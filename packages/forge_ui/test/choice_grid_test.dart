import 'dart:ui' show SemanticsRole;

import 'package:material_ui/material_ui.dart';
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

  group('picture tiles', () {
    // A picture that takes hits, asking for more room than the tile gives.
    Widget picture(int i) => ColoredBox(
      key: ValueKey('picture $i'),
      color: const Color(0x00000000),
      child: SizedBox(
        height: 1000,
        child: Semantics(label: '[PICTURE]', image: true),
      ),
    );

    Future<void> pumpTiles(
      WidgetTester tester, {
      int? selected,
      int count = 2,
      bool disabledLast = false,
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
              width: 358,
              child: ChoiceGrid.pictures(
                options: [
                  for (var i = 0; i < count; i++)
                    ChoiceOption(
                      label: 'Option $i',
                      hint: i == 0 ? '[HINT]' : null,
                      picture: picture(i),
                      enabled: !(disabledLast && i == count - 1),
                    ),
                ],
                selected: selected,
                onSelected: picks.add,
              ),
            ),
          ),
        ),
      ),
    );

    Finder pictureOf(int i) => find.byKey(ValueKey('picture $i'));
    Finder tileOf(String label) => find
        .ancestor(of: find.text(label), matching: find.byType(Container))
        .last;

    testWidgets('a tap on a tile, its picture too, picks it', (tester) async {
      await pumpTiles(tester);

      await tester.tap(pictureOf(1));
      await tester.tap(find.text('Option 0'));

      expect(picks, [1, 0]);
    });

    testWidgets('lays tiles two to a row with 9:16 pictures', (tester) async {
      await pumpTiles(tester, count: 3);

      final first = tester.getRect(pictureOf(0));
      final second = tester.getRect(pictureOf(1));
      final third = tester.getRect(pictureOf(2));
      expect(second.top, first.top);
      expect(second.left - first.right, Gap.sm);
      expect(third.left, first.left);
      expect(third.top, greaterThan(first.bottom));
      expect(first.width, (358 - Gap.sm) / 2);
      // The picture sits under a 16px top inset of the 9:16 box.
      expect(first.height + Gap.md, closeTo(first.width * 16 / 9, 0.01));
    });

    testWidgets('tiles of a row share one height', (tester) async {
      await pumpTiles(tester);

      expect(
        tester.getSize(tileOf('Option 0')).height,
        tester.getSize(tileOf('Option 1')).height,
      );
    });

    testWidgets('reads as a radio group with the chosen tile checked', (
      tester,
    ) async {
      await pumpTiles(tester, selected: 1);

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics && w.properties.role == SemanticsRole.radioGroup,
        ),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.text('Option 1')),
        matchesSemantics(
          label: 'Option 1',
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
      expect(
        tester.getSemantics(find.text('Option 0')),
        matchesSemantics(
          label: 'Option 0\n[HINT]',
          hasCheckedState: true,
          isInMutuallyExclusiveGroup: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
    });

    testWidgets('the chosen tile sits on accent-soft with a filled radio', (
      tester,
    ) async {
      await pumpTiles(tester, selected: 0);
      final colors = ForgeStyle.of(tester.element(find.text('Option 0')))
          .colors;

      Color? groundOf(String label) =>
          (tester.widget<Container>(tileOf(label)).decoration as BoxDecoration?)
              ?.color;
      expect(groundOf('Option 0'), colors.accentSoft);
      expect(groundOf('Option 1'), colors.surface);
      expect(
        tester
            .widgetList<RadioMark>(find.byType(RadioMark))
            .map((r) => r.selected),
        [true, false],
      );
    });

    testWidgets('a focused tile takes Enter', (tester) async {
      await pumpTiles(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);

      expect(picks, [1]);
    });

    testWidgets('a disabled tile fades, takes no tap and reads as disabled', (
      tester,
    ) async {
      await pumpTiles(tester, disabledLast: true);

      await tester.tap(pictureOf(1));
      expect(picks, isEmpty);
      expect(
        tester
            .widget<Opacity>(
              find.ancestor(
                of: find.text('Option 1'),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        0.4,
      );
      expect(
        tester.getSemantics(find.text('Option 1')),
        matchesSemantics(
          label: 'Option 1',
          hasCheckedState: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
        ),
      );
    });

    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('lays out at ${scale}x text', (tester) async {
        await pumpTiles(tester, count: 3, scale: scale);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
