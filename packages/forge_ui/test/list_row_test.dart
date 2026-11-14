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

  ForgePalette colors(WidgetTester tester) =>
      ForgeStyle.of(tester.element(find.byType(Scaffold))).colors;

  Color? textColor(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  testWidgets('a card puts one divider between each two rows', (tester) async {
    await pump(
      tester,
      const ListRowCard(
        children: [
          ListRow(title: 'One'),
          ListRow(title: 'Two'),
          ListRow(title: 'Three'),
        ],
      ),
    );

    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('tapping a row calls onTap; the chevron and value show', (
    tester,
  ) async {
    var taps = 0;
    await pump(
      tester,
      ListRow(
        title: 'Units',
        value: '[VALUE]',
        end: ListRowEnd.chevron,
        onTap: () => taps++,
      ),
    );

    await tester.tap(find.text('Units'));
    expect(taps, 1);
    expect(find.text('[VALUE]'), findsOneWidget);
    expect(find.byType(ForgeIcon), findsOneWidget);
    expect(tester.getSize(find.byType(ListRow)).height, 52);
  });

  testWidgets('a destructive row has its title in danger', (tester) async {
    await pump(tester, const ListRow(title: 'Delete', destructive: true));

    expect(textColor(tester, 'Delete'), colors(tester).danger);
  });

  testWidgets('the info icon takes taps across a 44px square, the rest '
      'of the row opens it', (tester) async {
    var info = 0;
    var taps = 0;
    await pump(
      tester,
      SizedBox(
        width: 360,
        child: ListRow(
          title: 'Field',
          onInfo: () => info++,
          infoLabel: 'About this field',
          onTap: () => taps++,
        ),
      ),
    );

    final icon = find.byType(ForgeIcon);
    expect(tester.getSize(icon), const Size(16, 16));
    final centre = tester.getCenter(icon);
    await tester.tap(find.byType(ListRow), warnIfMissed: false);
    await tester.tapAt(centre);
    await tester.tapAt(centre + const Offset(20, 0));
    await tester.tapAt(centre + const Offset(0, -20));
    expect(info, 3);
    await tester.tapAt(centre + const Offset(40, 0));
    expect(taps, 2);
  });

  testWidgets('date box and info rows have a title-style title', (
    tester,
  ) async {
    await pump(
      tester,
      Column(
        children: [
          const ListRow(
            title: 'Dated',
            leading: ListRowDateBox(weekday: 'Thu', day: '12'),
          ),
          ListRow(title: 'Field', onInfo: () {}, infoLabel: 'About'),
          const ListRow(title: 'Plain'),
        ],
      ),
    );

    double? size(String text) =>
        tester.widget<Text>(find.text(text)).style?.fontSize;
    expect(size('Dated'), 15);
    expect(size('Field'), 15);
    expect(size('Plain'), 14);
  });

  testWidgets('a checked row reads as checked and turns accent-soft', (
    tester,
  ) async {
    await pump(tester, const ListRow(title: 'Item title', checked: true));

    expect(
      tester.getSemantics(find.byType(ListRow)),
      matchesSemantics(
        label: 'Item title',
        hasCheckedState: true,
        isChecked: true,
      ),
    );
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(ListRow),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, colors(tester).accentSoft);
    expect(textColor(tester, 'Item title'), colors(tester).onAccentSoft);
  });

  testWidgets('a missing value shows a danger dash and the error line', (
    tester,
  ) async {
    await pump(
      tester,
      const ListRow(
        title: 'Field two',
        value: '[VALUE]',
        missing: true,
        error: 'Required to save',
      ),
    );

    expect(find.text('[VALUE]'), findsNothing);
    expect(textColor(tester, '—'), colors(tester).danger);
    expect(textColor(tester, 'Required to save'), colors(tester).danger);
  });

  testWidgets('a locked row mutes its title and detail', (tester) async {
    await pump(
      tester,
      const ListRow(title: 'Item title', detail: '[DETAIL]', locked: true),
    );

    expect(textColor(tester, 'Item title'), colors(tester).inkMuted);
    expect(textColor(tester, '[DETAIL]'), colors(tester).inkSubtle);
  });

  testWidgets('a busy row turns a ring', (tester) async {
    await pump(
      tester,
      const ListRow(title: 'Item title', detail: 'Unlocking…', busy: true),
    );

    expect(find.byType(BusyRing), findsOneWidget);
  });

  testWidgets('a loading row keeps its height with three skeleton bars', (
    tester,
  ) async {
    await pump(
      tester,
      const SizedBox(width: 360, child: ListRow.loading(index: 1)),
    );

    expect(find.byType(SkeletonBar), findsNWidgets(3));
    expect(tester.getSize(find.byType(ListRow)).height, 52);
    expect(
      tester.widget<SkeletonBar>(find.byType(SkeletonBar).first).widthFactor,
      0.45,
    );
  });

  testWidgets('the date box is 40 by 44', (tester) async {
    await pump(
      tester,
      const ListRow(
        title: 'Item title',
        leading: ListRowDateBox(weekday: 'Fri', day: '13', today: true),
      ),
    );

    expect(tester.getSize(find.byType(ListRowDateBox)), const Size(40, 44));
  });

  testWidgets('dragging a handle reorders the rows in the card', (
    tester,
  ) async {
    var moved = <int>[];
    await pump(
      tester,
      SizedBox(
        width: 360,
        child: ListRowCard(
          onReorder: (from, to) => moved = [from, to],
          children: [
            for (final (i, title) in ['A', 'B', 'C'].indexed)
              ListRow(
                key: ValueKey(title),
                title: title,
                leading: ListRowDragHandle(index: i),
              ),
          ],
        ),
      ),
    );

    final handle = find.byType(ListRowDragHandle).first;
    final drag = await tester.startGesture(tester.getCenter(handle));
    await drag.moveBy(const Offset(0, 120));
    await tester.pump();
    final lifted = tester.widgetList<Material>(find.byType(Material));
    expect(lifted.every((m) => m.elevation == 0), isTrue);
    await drag.up();
    await tester.pumpAndSettle();

    expect(moved.first, 0);
    expect(moved.last, greaterThan(0));
  });

  testWidgets('the info icon is a button with its label', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      SizedBox(
        width: 360,
        child: ListRow(
          title: 'Field',
          onInfo: () {},
          infoLabel: 'About this field',
        ),
      ),
    );

    expect(find.bySemanticsLabel('About this field'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('About this field')),
      matchesSemantics(
        label: 'About this field',
        isButton: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a drag handle takes drags across a 44px square', (tester) async {
    var moved = <int>[];
    await pump(
      tester,
      SizedBox(
        width: 360,
        child: ListRowCard(
          onReorder: (from, to) => moved = [from, to],
          children: [
            for (final (i, title) in ['A', 'B', 'C'].indexed)
              ListRow(
                key: ValueKey(title),
                title: title,
                leading: ListRowDragHandle(index: i),
              ),
          ],
        ),
      ),
    );

    final handle = find.byType(ListRowDragHandle).first;
    expect(tester.getSize(handle), const Size(18, 18));
    final drag = await tester.startGesture(
      tester.getCenter(handle) + const Offset(20, 20),
    );
    await drag.moveBy(const Offset(0, 120));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();

    expect(moved.first, 0);
    expect(moved.last, greaterThan(0));
  });
}
