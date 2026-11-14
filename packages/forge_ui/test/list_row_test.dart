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

  testWidgets('the info icon calls onInfo, not onTap', (tester) async {
    var info = 0;
    var taps = 0;
    await pump(
      tester,
      ListRow(title: 'Field', onInfo: () => info++, onTap: () => taps++),
    );

    await tester.tap(find.byType(ForgeIcon));
    expect(info, 1);
    expect(taps, 0);
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
    await pump(tester, const SizedBox(width: 360, child: ListRow.loading()));

    expect(find.byType(SkeletonBar), findsNWidgets(3));
    expect(tester.getSize(find.byType(ListRow)).height, 52);
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
    await drag.up();
    await tester.pumpAndSettle();

    expect(moved.first, 0);
    expect(moved.last, greaterThan(0));
  });
}
