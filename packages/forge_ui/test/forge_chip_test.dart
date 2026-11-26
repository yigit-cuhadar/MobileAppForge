import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, ForgeChip chip) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(body: Center(child: chip)),
    ),
  );

  Finder icon(ForgeIconData data) =>
      find.byWidgetPredicate((w) => w is ForgeIcon && w.icon == data);

  testWidgets('calls onPressed across the 44px band', (tester) async {
    var taps = 0;
    await pump(tester, ForgeChip(label: 'Filter C', onPressed: () => taps++));
    final band = tester.getRect(find.byType(ForgeChip));

    expect(band.height, ForgeTheme.tapMin);
    await tester.tapAt(band.bottomCenter - const Offset(0, 1));

    expect(taps, 1);
  });

  testWidgets('a selected filter shows a check and reads as selected', (
    tester,
  ) async {
    await pump(
      tester,
      ForgeChip(label: 'Filter A', selected: true, onPressed: () {}),
    );

    expect(icon(ForgeIcons.check), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(ForgeChip)),
      matchesSemantics(
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
        label: 'Filter A',
      ),
    );
  });

  testWidgets('a count takes the place of the check', (tester) async {
    await pump(
      tester,
      ForgeChip(label: 'Group', selected: true, count: 2, onPressed: () {}),
    );

    expect(find.text('2'), findsOneWidget);
    expect(icon(ForgeIcons.check), findsNothing);
  });

  testWidgets('a locked chip shows a lock and stays tappable', (tester) async {
    var taps = 0;
    await pump(
      tester,
      ForgeChip(label: 'Locked action', locked: true, onPressed: () => taps++),
    );

    await tester.tap(find.text('Locked action'));

    expect(taps, 1);
    expect(icon(ForgeIcons.lock), findsOneWidget);
  });

  testWidgets('a removable chip shows a close icon and calls onRemoved', (
    tester,
  ) async {
    var removed = 0;
    await pump(
      tester,
      ForgeChip.removable(
        label: 'Filter A',
        onRemoved: () => removed++,
        removeHint: 'Removes the filter',
      ),
    );

    await tester.tap(icon(ForgeIcons.close));

    expect(removed, 1);
    expect(icon(ForgeIcons.check), findsNothing);
  });

  testWidgets('a series chip is 28px with its sample and no check', (
    tester,
  ) async {
    var taps = 0;
    await pump(
      tester,
      ForgeChip.series(
        label: 'Series A',
        sample: const SeriesSample(SeriesLook.accent),
        selected: true,
        onPressed: () => taps++,
      ),
    );

    expect(
      tester
          .getSize(
            find.descendant(
              of: find.byType(ForgeChip),
              matching: find.byType(Container),
            ),
          )
          .height,
      ForgeChip.seriesHeight,
    );
    expect(tester.getRect(find.byType(ForgeChip)).height, ForgeTheme.tapMin);
    expect(find.byType(SeriesSample), findsOneWidget);
    expect(icon(ForgeIcons.check), findsNothing);
    await tester.tap(find.text('Series A'));
    expect(taps, 1);
  });

  testWidgets('a removable chip is announced with its remove hint', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      ForgeChip.removable(
        label: 'Filter A',
        onRemoved: () {},
        removeHint: 'Removes the filter',
      ),
    );

    expect(
      tester.getSemantics(find.byType(ForgeChip)),
      matchesSemantics(
        label: 'Filter A',
        hint: 'Removes the filter',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a long label ends in an ellipsis in a narrow space', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              child: Wrap(
                children: [
                  ForgeChip(
                    label: 'A filter with a very long label',
                    onPressed: () {},
                    selected: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(ForgeChip)).width,
      lessThanOrEqualTo(120),
    );
    expect(
      tester
          .widget<Text>(find.text('A filter with a very long label'))
          .overflow,
      TextOverflow.ellipsis,
    );
  });

  testWidgets('the menu form shows a ▾ after the name and calls onPressed', (
    tester,
  ) async {
    var taps = 0;
    await pump(
      tester,
      ForgeChip.menu(label: 'Filter', onPressed: () => taps++),
    );

    expect(icon(ForgeIcons.expandMore), findsOneWidget);
    expect(
      tester.getTopLeft(icon(ForgeIcons.expandMore)).dx,
      greaterThan(tester.getTopRight(find.text('Filter')).dx),
    );
    await tester.tap(find.byType(ForgeChip));
    expect(taps, 1);
  });

  testWidgets('a leading icon sits before the label at 14px in its ink', (
    tester,
  ) async {
    await pump(
      tester,
      ForgeChip(
        label: 'Add',
        leading: const ForgeIcon(ForgeIcons.add),
        onPressed: () {},
      ),
    );
    final colors = ForgeStyle.of(tester.element(find.byType(ForgeChip))).colors;

    expect(tester.getSize(icon(ForgeIcons.add)), const Size.square(14));
    expect(
      tester.getTopRight(icon(ForgeIcons.add)).dx,
      lessThan(tester.getTopLeft(find.text('Add')).dx),
    );
    expect(
      IconTheme.of(tester.element(icon(ForgeIcons.add))).color,
      colors.ink,
    );
  });

  testWidgets('a long press opens the options, also as a reader action', (
    tester,
  ) async {
    var taps = 0;
    var options = 0;
    await pump(
      tester,
      ForgeChip(
        label: 'Item',
        onPressed: () => taps++,
        onOptions: () => options++,
        optionsLabel: 'Item options',
      ),
    );

    expect(icon(ForgeIcons.moreHoriz), findsNothing);
    await tester.longPress(find.byType(ForgeChip));
    await tester.tap(find.byType(ForgeChip));
    expect((taps, options), (1, 1));

    final node = tester.getSemantics(find.byType(ForgeChip));
    const action = CustomSemanticsAction(label: 'Item options');
    expect(
      node,
      matchesSemantics(
        isButton: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasLongPressAction: true,
        label: 'Item',
        customActions: [action],
      ),
    );
    node.owner!.performAction(
      node.id,
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(action),
    );
    expect(options, 2);
  });

  testWidgets('selected, it shows a ⋯; the ⋯, a tap and a long press open '
      'the options', (tester) async {
    var taps = 0;
    var options = 0;
    await pump(
      tester,
      ForgeChip(
        label: 'Item',
        selected: true,
        showCheck: false,
        onPressed: () => taps++,
        onOptions: () => options++,
        optionsLabel: 'Item options',
      ),
    );
    final more = icon(ForgeIcons.moreHoriz);
    final chip = tester.getRect(find.byType(ForgeChip));

    expect(tester.getSize(more), const Size.square(16));
    expect(chip.height, ForgeTheme.tapMin);
    expect(
      tester.getTopLeft(more).dx,
      greaterThan(tester.getTopRight(find.text('Item')).dx),
    );
    await tester.tapAt(tester.getCenter(more).translate(0, 20));
    await tester.tap(find.text('Item'));
    await tester.longPress(find.byType(ForgeChip));
    expect((taps, options), (0, 3));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Item options')),
      matchesSemantics(
        isButton: true,
        hasTapAction: true,
        label: 'Item options',
      ),
    );
    tester.semantics.tap(find.semantics.byLabel('Item options'));
    expect(options, 4);
  });

  testWidgets('a selected chip without the check keeps its fill and border', (
    tester,
  ) async {
    await pump(
      tester,
      ForgeChip(
        label: 'Item',
        selected: true,
        showCheck: false,
        onPressed: () {},
      ),
    );
    final colors = ForgeStyle.of(tester.element(find.byType(ForgeChip))).colors;
    final box =
        tester
                .widget<Container>(
                  find
                      .descendant(
                        of: find.byType(ForgeChip),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;

    expect(icon(ForgeIcons.check), findsNothing);
    expect(box.color, colors.accentSoft);
    expect(box.border, Border.all(color: colors.accent, width: 1.5));
  });

  testWidgets('the add form shows a + and its label in ink-muted', (
    tester,
  ) async {
    var taps = 0;
    await pump(tester, ForgeChip.add(label: 'Item', onPressed: () => taps++));
    final colors = ForgeStyle.of(tester.element(find.byType(ForgeChip))).colors;

    expect(tester.getSize(icon(ForgeIcons.add)), const Size.square(16));
    expect(
      IconTheme.of(tester.element(icon(ForgeIcons.add))).color,
      colors.inkMuted,
    );
    expect(
      tester.widget<Text>(find.text('Item')).style!.color,
      colors.inkMuted,
    );
    expect(
      tester.getTopRight(icon(ForgeIcons.add)).dx,
      lessThan(tester.getTopLeft(find.text('Item')).dx),
    );
    await tester.tap(find.byType(ForgeChip));
    expect(taps, 1);
  });

  group('a toned chip', () {
    double contrast(Color a, Color b) {
      final (x, y) = (a.computeLuminance(), b.computeLuminance());
      return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
    }

    for (final (brightness, theme) in [
      ('light', ForgeTheme.light()),
      ('dark', ForgeTheme.dark()),
    ]) {
      for (final tone in [ForgeChipTone.success, ForgeChipTone.danger]) {
        testWidgets('$tone in $brightness: a soft tint, filled when selected '
            'and 4.5:1 text both ways', (tester) async {
          for (final selected in [false, true]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                home: Scaffold(
                  body: Center(
                    child: ForgeChip(
                      label: 'Item',
                      tone: tone,
                      selected: selected,
                      showCheck: false,
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            );
            final p = ForgeStyle.of(tester.element(find.byType(ForgeChip)))
                .colors;
            final status = tone == ForgeChipTone.success ? p.success : p.danger;
            final box =
                tester
                        .widget<Container>(
                          find
                              .descendant(
                                of: find.byType(ForgeChip),
                                matching: find.byType(Container),
                              )
                              .first,
                        )
                        .decoration!
                    as BoxDecoration;
            final ink = tester.widget<Text>(find.text('Item')).style!.color!;

            if (selected) {
              expect(box.color, status);
              expect(ink, p.surface);
            } else {
              expect(box.color, Color.lerp(p.surface, status, 0.12));
              expect(box.border!.top.color, isNot(p.lineStrong));
            }
            expect(contrast(ink, box.color!), greaterThanOrEqualTo(4.5));
          }
        });
      }
    }
  });
}
