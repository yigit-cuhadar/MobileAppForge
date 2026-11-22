import 'package:material_ui/material_ui.dart';
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

    testWidgets('a subtitle sits muted 2px under the title', (tester) async {
      await pump(
        tester,
        (context) => showForgeBottomSheet<void>(
          context: context,
          builder: (_) => const ForgeBottomSheet(
            title: 'Item title',
            subtitle: '[VALUE] · [DETAIL]',
            child: Text('Option one'),
          ),
        ),
      );
      await open(tester);

      expect(
        tester.getTopLeft(find.text('[VALUE] · [DETAIL]')).dy -
            tester.getBottomLeft(find.text('Item title')).dy,
        2,
      );
      final context = tester.element(find.text('Item title'));
      expect(
        tester.widget<Text>(find.text('[VALUE] · [DETAIL]')).style?.color,
        ForgeStyle.of(context).colors.inkMuted,
      );
    });

    testWidgets('opens on the root navigator, over a nested one', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          home: Scaffold(
            body: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (context) => TextButton(
                  onPressed: () => showForgeBottomSheet<void>(
                    context: context,
                    builder: sheet,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
            bottomNavigationBar: const SizedBox(height: 80),
          ),
        ),
      );
      await open(tester);

      expect(
        tester.getBottomLeft(find.byType(ForgeBottomSheet)).dy,
        tester.getSize(find.byType(MaterialApp)).height,
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

    testWidgets('a choice puts its answers side by side, the main one at '
        'the end, and closes from its corner', (tester) async {
      await pump(
        tester,
        (context) => showForgeDialog<void>(
          context: context,
          builder: (context) => ForgeDialog.choice(
            title: 'Enjoying [APP NAME]?',
            message: 'Your answer helps us improve.',
            action: FilledButton(onPressed: () {}, child: const Text('Yes')),
            cancel: ElevatedButton(onPressed: () {}, child: const Text('No')),
            close: ForgeIconButton(
              icon: ForgeIcons.close,
              label: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      );
      await open(tester);

      final yes = tester.getRect(find.byType(FilledButton));
      final no = tester.getRect(find.byType(ElevatedButton));
      expect(no.top, yes.top);
      expect(no.right, lessThan(yes.left));
      expect(no.width, yes.width);
      final dialog = tester.getRect(
        find
            .descendant(
              of: find.byType(ForgeDialog),
              matching: find.byType(Material),
            )
            .first,
      );
      final close = tester.getRect(find.byType(ForgeIconButton));
      expect(close.right, lessThan(dialog.right));
      expect(close.right, greaterThan(dialog.right - Gap.md));
      expect(
        close.top,
        lessThan(tester.getRect(find.text('Enjoying [APP NAME]?')).top),
      );

      await tester.tap(find.bySemanticsLabel('Close'));
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
    testWidgets('puts the alternative 16px under the action, over Cancel', (
      tester,
    ) async {
      await pump(
        tester,
        (context) => showForgeDialog<void>(
          context: context,
          builder: (context) => ForgeDialog(
            title: 'Confirm it is you',
            field: const TextField(),
            action: FilledButton(onPressed: () {}, child: const Text('Delete')),
            alternative: const OrDivider(label: 'or'),
            cancel: ElevatedButton(
              onPressed: () {},
              child: const Text('Cancel'),
            ),
          ),
        ),
      );
      await open(tester);

      final alternative = tester.getRect(find.byType(OrDivider));
      expect(
        alternative.top - tester.getRect(find.byType(FilledButton)).bottom,
        Gap.md,
      );
      expect(
        alternative.bottom,
        lessThan(tester.getRect(find.byType(ElevatedButton)).top),
      );
    });

    testWidgets('without a message, the buttons follow the title', (
      tester,
    ) async {
      await pump(
        tester,
        (context) => showForgeDialog<void>(
          context: context,
          builder: (context) => ForgeDialog(
            title: 'Remove item?',
            action: FilledButton(onPressed: () {}, child: const Text('Remove')),
            cancel: ElevatedButton(
              onPressed: () {},
              child: const Text('Cancel'),
            ),
          ),
        ),
      );
      await open(tester);

      expect(
        find.descendant(
          of: find.byType(ForgeDialog),
          matching: find.byType(Text),
        ),
        findsNWidgets(3),
      );
      expect(
        tester.getRect(find.text('Remove item?')).bottom,
        lessThan(tester.getRect(find.byType(FilledButton)).top),
      );
    });

    group('list', () {
      Future<void> openList(WidgetTester tester, int rows) async {
        await pump(
          tester,
          (context) => showForgeDialog<void>(
            context: context,
            builder: (context) => ForgeDialog.list(
              title: 'Items to show',
              list: [
                for (var i = 0; i < rows; i++)
                  ListRow(title: 'Item $i', checked: i.isEven, onTap: () {}),
              ],
              action: FilledButton(onPressed: () {}, child: const Text('Done')),
              cancel: ElevatedButton(
                onPressed: () {},
                child: const Text('Cancel'),
              ),
            ),
          ),
        );
        await open(tester);
      }

      /// The fade over the list's bottom, if drawn.
      Finder fade() => find.descendant(
        of: find.byType(ForgeDialog),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).gradient != null,
        ),
      );

      testWidgets('puts the rows flush and untinted between title and '
          'buttons', (tester) async {
        await openList(tester, 3);

        final title = tester.getRect(find.text('Items to show'));
        final row = tester.getRect(find.byType(ListRow).first);
        expect(title.bottom, lessThan(row.top));
        expect(
          tester.getRect(find.byType(ListRow).last).bottom,
          lessThan(tester.getRect(find.byType(FilledButton)).top),
        );
        // Flush: the row is as wide as the buttons, 40px tall.
        expect(row.width, tester.getRect(find.byType(FilledButton)).width);
        expect(row.height, 40);
        final colors = ForgeStyle.of(tester.element(find.byType(ListRow).first))
            .colors;
        final material = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(ListRow).first,
                matching: find.byType(Material),
              )
              .first,
        );
        expect(material.color, isNot(colors.accentSoft));
        expect(
          tester.widget<Text>(find.text('Item 0')).style?.color,
          colors.ink,
        );
        expect(fade(), findsNothing);
      });

      testWidgets('a long list scrolls and fades out until its end', (
        tester,
      ) async {
        await openList(tester, 30);

        expect(fade(), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);
        await tester.dragUntilVisible(
          find.text('Item 29'),
          find.byType(SingleChildScrollView),
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();
        expect(fade(), findsNothing);
      });
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

    testWidgets('shown from a sheet, it lies over the sheet for 4 s and '
        'its action works', (tester) async {
      var retried = 0;
      await pump(
        tester,
        (context) => showForgeBottomSheet<void>(
          context: context,
          builder: (context) => ForgeBottomSheet(
            title: 'Item title',
            child: SizedBox(
              height: 300,
              child: TextButton(
                onPressed: () => showForgeSnackbar(
                  context,
                  message: "Couldn't save.",
                  actionLabel: 'Retry',
                  onAction: () => retried++,
                  error: true,
                ),
                child: const Text('Save'),
              ),
            ),
          ),
        ),
      );
      await open(tester);
      await tester.tap(find.text('Save'));
      await tester.pump();

      final strip = tester.getRect(find.byType(ForgeSnackbar));
      final screen = tester.getRect(find.byType(MaterialApp));
      expect(strip.bottom, screen.bottom - Gap.md);
      expect(strip.left, Gap.md);
      expect(
        strip.overlaps(tester.getRect(find.byType(ForgeBottomSheet))),
        isTrue,
      );
      expect(find.text('Retry').hitTestable(), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text("Couldn't save."), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text("Couldn't save."), findsNothing);

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retried, 1);
      expect(find.text("Couldn't save."), findsNothing);
    });

    testWidgets('a new one over a sheet takes the place of the last', (
      tester,
    ) async {
      var n = 0;
      await pump(
        tester,
        (context) => showForgeBottomSheet<void>(
          context: context,
          builder: (context) => ForgeBottomSheet(
            title: 'Item title',
            child: SizedBox(
              height: 300,
              child: Align(
                alignment: Alignment.topLeft,
                child: TextButton(
                  onPressed: () =>
                      showForgeSnackbar(context, message: 'Saved ${++n}'),
                  child: const Text('Save'),
                ),
              ),
            ),
          ),
        ),
      );
      await open(tester);
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Saved 1'), findsNothing);
      expect(find.text('Saved 2'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.byType(ForgeSnackbar), findsNothing);
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

  group('ForgeCheckSheet', () {
    const values = ['One', 'Two', 'Three'];

    Future<Set<String>?> openCheck(BuildContext context) =>
        showForgeCheckSheet<String>(
          context: context,
          title: 'Items',
          subtitle: 'Pick any',
          values: values,
          selected: {'Two'},
          labelOf: (value) => 'Item $value',
          saveLabel: 'Save',
        );

    testWidgets('lists the values as check rows with lines between, under '
        'the title and subtitle, Save full width', (tester) async {
      await pump(tester, openCheck);
      await open(tester);

      expect(find.text('Items'), findsOneWidget);
      expect(find.text('Pick any'), findsOneWidget);
      expect(find.byType(ListRow), findsNWidgets(3));
      expect(
        find.descendant(
          of: find.byType(ForgeCheckSheet<String>),
          matching: find.byType(Divider),
        ),
        findsNWidgets(2),
      );
      expect(
        tester.getSemantics(find.byType(ListRow).at(1)),
        matchesSemantics(
          label: 'Item Two',
          hasCheckedState: true,
          isChecked: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );
      expect(
        tester.getSize(find.byType(ForgeButton)).width,
        tester.getSize(find.byType(ListRow).first).width,
      );
    });

    testWidgets('Save returns the ticked values in their order', (
      tester,
    ) async {
      Set<String>? result;
      await pump(tester, (context) async => result = await openCheck(context));
      await open(tester);

      await tester.tap(find.text('Item Three'));
      await tester.tap(find.text('Item One'));
      await tester.tap(find.text('Item Two'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result?.toList(), ['One', 'Three']);
      expect(find.byType(ForgeCheckSheet<String>), findsNothing);
    });

    testWidgets('closing it returns null', (tester) async {
      Set<String>? result = {'unset'};
      await pump(tester, (context) async => result = await openCheck(context));
      await open(tester);

      await tester.tap(find.text('Item One'));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('a long list scrolls and keeps Save in view', (tester) async {
      await pump(
        tester,
        (context) => showForgeCheckSheet<int>(
          context: context,
          title: 'Items',
          values: List.generate(40, (i) => i),
          selected: const {},
          labelOf: (i) => 'Item $i',
          saveLabel: 'Save',
        ),
      );
      await open(tester);

      expect(find.text('Save').hitTestable(), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('Item 39'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(find.text('Item 39').hitTestable(), findsOneWidget);
    });

    testWidgets('opened from a sheet, it stacks over it and returns to it', (
      tester,
    ) async {
      Set<String>? result;
      await pump(
        tester,
        (context) => showForgeBottomSheet<void>(
          context: context,
          builder: (context) => ForgeBottomSheet(
            title: 'Filters',
            child: TextButton(
              onPressed: () async => result = await openCheck(context),
              child: const Text('Pick'),
            ),
          ),
        ),
      );
      await open(tester);
      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();

      expect(find.text('Filters'), findsOneWidget);
      await tester.tap(find.text('Item One'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, {'One', 'Two'});
      expect(find.byType(ForgeCheckSheet<String>), findsNothing);
      expect(find.text('Pick').hitTestable(), findsOneWidget);
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

    testWidgets('an icon sits before each label, danger in a destructive row', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          home: Scaffold(
            body: ForgeMenu(
              items: [
                ForgeMenuItem(
                  label: 'Edit',
                  icon: ForgeIcons.edit,
                  onTap: () => taps++,
                ),
                ForgeMenuItem(
                  label: 'Delete',
                  icon: ForgeIcons.delete,
                  destructive: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      final colors = ForgeStyle.of(tester.element(find.byType(ForgeMenu)))
          .colors;
      ForgeIcon icon(ForgeIconData data) => tester.widget<ForgeIcon>(
        find.byWidgetPredicate((w) => w is ForgeIcon && w.icon == data),
      );

      expect(icon(ForgeIcons.edit).color, colors.ink);
      expect(icon(ForgeIcons.delete).color, colors.danger);
      expect(
        tester.getTopRight(find.byType(ForgeIcon).first).dx,
        lessThan(tester.getTopLeft(find.text('Edit')).dx),
      );
      await tester.tap(find.byType(ForgeIcon).first);
      expect(taps, 1);
    });

    test('every row has an icon, or none', () {
      expect(
        () => ForgeMenu(
          items: [
            ForgeMenuItem(label: 'Edit', icon: ForgeIcons.edit, onTap: () {}),
            ForgeMenuItem(label: 'Other', onTap: () {}),
          ],
        ),
        throwsAssertionError,
      );
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

    testWidgets('a note sits in its own muted row under the facts', (
      tester,
    ) async {
      await pump(
        tester,
        (context) => showForgeInfo(
          context: context,
          title: '[VALUE]',
          facts: const [('Fact one', '[VALUE]')],
          note: 'One line about the value.',
        ),
      );
      await open(tester);
      final colors = ForgeStyle.of(tester.element(find.byType(ForgeInfoCard)))
          .colors;
      final note = find.text('One line about the value.');

      expect(tester.widget<Text>(note).style!.color, colors.inkMuted);
      expect(
        tester.getTopLeft(note).dy,
        greaterThan(tester.getBottomLeft(find.text('Fact one')).dy),
      );
      expect(
        tester.getRect(note).right,
        lessThanOrEqualTo(tester.getRect(find.byType(ForgeInfoCard)).right),
      );
    });

    testWidgets('a long value wraps, right-aligned, inside the card', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          home: const Scaffold(
            body: Center(
              child: ForgeInfoCard(
                title: '[VALUE] on [DETAIL]',
                facts: [
                  ('Short', '[VALUE]'),
                  ('Each side', '25 + 25 + 25 + 25 + 5 + 2.5 kg'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final card = tester.getRect(find.byType(ForgeInfoCard));
      final value = find.text('25 + 25 + 25 + 25 + 5 + 2.5 kg');
      expect(tester.getSize(value).height, greaterThan(30));
      expect(tester.getRect(value).right, lessThanOrEqualTo(card.right));
      expect(tester.widget<Text>(value).textAlign, TextAlign.end);
    });
  });
}
