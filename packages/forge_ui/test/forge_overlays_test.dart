import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  /// Pumps a page with one 'Open' button running [onOpen].
  Future<void> pump(
    WidgetTester tester,
    void Function(BuildContext context) onOpen,
  ) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => onOpen(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('ForgeBottomSheet', () {
    Widget sheet(BuildContext context) => ForgeBottomSheet(
      title: 'Filters',
      headerAction: TextButton(onPressed: () {}, child: const Text('Clear')),
      action: FilledButton(
        onPressed: () => Navigator.pop(context, 'saved'),
        child: const Text('Show results'),
      ),
      child: const Text('Option one'),
    );

    testWidgets('shows its parts, the action full width, and returns the '
        'result', (tester) async {
      String? result;
      await pump(tester, (context) async {
        result = await showForgeBottomSheet<String>(
          context: context,
          builder: sheet,
        );
      });
      await open(tester);

      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Option one'), findsOneWidget);
      expect(
        tester.getSize(find.byType(FilledButton)).width,
        tester.getSize(find.byType(ForgeBottomSheet)).width - 2 * Gap.md,
      );

      await tester.tap(find.text('Show results'));
      await tester.pumpAndSettle();
      expect(result, 'saved');
    });

    testWidgets('a swipe down closes it', (tester) async {
      await pump(
        tester,
        (context) =>
            showForgeBottomSheet<void>(context: context, builder: sheet),
      );
      await open(tester);

      await tester.fling(find.text('Filters'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(find.byType(ForgeBottomSheet), findsNothing);
    });

    testWidgets('without a main action, the content ends the sheet', (
      tester,
    ) async {
      await pump(
        tester,
        (context) => showForgeBottomSheet<void>(
          context: context,
          builder: (_) => const ForgeBottomSheet(
            title: 'Choose one',
            child: Text('Option one'),
          ),
        ),
      );
      await open(tester);

      expect(
        tester.getBottomLeft(find.byType(ForgeBottomSheet)).dy -
            tester.getBottomLeft(find.text('Option one')).dy,
        Gap.lg,
      );
    });
  });

  group('ForgeDialog', () {
    testWidgets('stacks the main action over Cancel, full width, and is '
        'named by its title', (tester) async {
      await pump(
        tester,
        (context) => showForgeDialog<void>(
          context: context,
          builder: (context) => ForgeDialog(
            title: 'Discard changes?',
            message: "Your changes will be lost. This can't be undone.",
            action: OutlinedButton(
              onPressed: () {},
              child: const Text('Discard'),
            ),
            cancel: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ),
      );
      await open(tester);

      final discard = tester.getRect(find.byType(OutlinedButton));
      final cancel = tester.getRect(find.byType(ElevatedButton));
      expect(discard.bottom, lessThan(cancel.top));
      expect(discard.width, cancel.width);
      expect(
        tester
            .getSize(
              find
                  .descendant(
                    of: find.byType(ForgeDialog),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .width,
        ForgeDialog.maxWidth,
      );
      expect(find.bySemanticsLabel('Discard changes?'), findsWidgets);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgeDialog), findsNothing);
    });

    testWidgets('puts the field between the text and the buttons', (
      tester,
    ) async {
      await pump(
        tester,
        (context) => showForgeDialog<void>(
          context: context,
          builder: (context) => ForgeDialog(
            title: 'Set a goal',
            message: 'Pick a number.',
            field: const TextField(),
            action: FilledButton(onPressed: () {}, child: const Text('Save')),
            cancel: ElevatedButton(
              onPressed: () {},
              child: const Text('Cancel'),
            ),
          ),
        ),
      );
      await open(tester);

      final field = tester.getRect(find.byType(TextField));
      expect(
        tester.getRect(find.text('Pick a number.')).bottom,
        lessThan(field.top),
      );
      expect(
        field.bottom,
        lessThan(tester.getRect(find.byType(FilledButton)).top),
      );
    });
  });

  group('ForgeSnackbar', () {
    testWidgets('lasts 4 s, with an action too', (tester) async {
      await pump(
        tester,
        (context) => showForgeSnackbar(
          context,
          message: 'Item removed',
          actionLabel: 'Undo',
          onAction: () {},
        ),
      );
      await open(tester);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Item removed'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Item removed'), findsNothing);
    });

    testWidgets('its action hides it, then runs', (tester) async {
      var undone = 0;
      await pump(
        tester,
        (context) => showForgeSnackbar(
          context,
          message: 'Item removed',
          actionLabel: 'Undo',
          onAction: () => undone++,
        ),
      );
      await open(tester);

      expect(find.text('Item removed'), findsOneWidget);
      expect(find.byType(ForgeIcon), findsNothing);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(undone, 1);
      expect(find.text('Item removed'), findsNothing);
    });

    testWidgets('an error carries the danger-tinted icon', (tester) async {
      await pump(
        tester,
        (context) =>
            showForgeSnackbar(context, message: "Couldn't save.", error: true),
      );
      await open(tester);

      final icon = tester.widget<ForgeIcon>(find.byType(ForgeIcon));
      expect(icon.icon, ForgeIcons.error);
      final colors = ForgeStyle.of(tester.element(find.byType(ForgeIcon)))
          .colors;
      expect(icon.color, Color.lerp(colors.ground, colors.danger, 0.55));
    });
  });

  group('ForgeMenu', () {
    testWidgets('opens under its button, right edges aligned; a row closes '
        'it and runs', (tester) async {
      final picked = <String>[];
      await pump(
        tester,
        (context) => showForgeMenu(
          context: context,
          items: [
            ForgeMenuItem(label: 'Edit', onTap: () => picked.add('Edit')),
            ForgeMenuItem(
              label: 'Delete',
              destructive: true,
              onTap: () => picked.add('Delete'),
            ),
          ],
        ),
      );
      await open(tester);

      final button = tester.getRect(find.byType(TextButton));
      final menu = tester.getRect(find.byType(ForgeMenu));
      expect(menu.top, button.bottom);
      expect(menu.right, lessThanOrEqualTo(button.right));
      expect(menu.width, 240);

      final colors = ForgeStyle.of(tester.element(find.byType(ForgeMenu)))
          .colors;
      expect(
        tester.widget<Text>(find.text('Delete')).style!.color,
        colors.danger,
      );
      expect(tester.widget<Text>(find.text('Edit')).style!.color, colors.ink);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(picked, ['Delete']);
      expect(find.byType(ForgeMenu), findsNothing);
    });

    testWidgets('a tap outside closes it without running a row', (
      tester,
    ) async {
      final picked = <String>[];
      await pump(
        tester,
        (context) => showForgeMenu(
          context: context,
          items: [ForgeMenuItem(label: 'Open', onTap: () => picked.add('x'))],
        ),
      );
      await open(tester);

      await tester.tapAt(const Offset(20, 500));
      await tester.pumpAndSettle();
      expect(find.byType(ForgeMenu), findsNothing);
      expect(picked, isEmpty);
    });

    testWidgets('the selected row carries a check', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          home: Scaffold(
            body: ForgeMenu(
              items: [
                ForgeMenuItem(label: 'Replace', onTap: () {}),
                ForgeMenuItem(label: 'Keep', selected: true, onTap: () {}),
              ],
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.ancestor(of: find.text('Keep'), matching: find.byType(Row)),
          matching: find.byType(ForgeIcon),
        ),
        findsOneWidget,
      );
      expect(find.byType(ForgeIcon), findsOneWidget);
    });

    test('only the last row may be destructive', () {
      expect(
        () => ForgeMenu(
          items: [
            ForgeMenuItem(label: 'Delete', destructive: true, onTap: () {}),
            ForgeMenuItem(label: 'Edit', onTap: () {}),
          ],
        ),
        throwsAssertionError,
      );
    });

    testWidgets('the info card lists its facts and closes on a tap outside', (
      tester,
    ) async {
      await pump(
        tester,
        (context) => showForgeInfo(
          context: context,
          title: '[VALUE] on [DETAIL]',
          facts: const [('Fact one', '[VALUE]'), ('Fact two', '2 × [VALUE]')],
        ),
      );
      await open(tester);

      expect(find.text('[VALUE] on [DETAIL]'), findsOneWidget);
      expect(find.text('Fact two'), findsOneWidget);
      expect(
        tester.getRect(find.byType(ForgeInfoCard)).top,
        tester.getRect(find.byType(TextButton)).bottom + Gap.sm,
      );

      await tester.tapAt(const Offset(20, 500));
      await tester.pumpAndSettle();
      expect(find.byType(ForgeInfoCard), findsNothing);
    });
  });
}
