import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  late List<String> changes;
  late List<String> locked;

  setUp(() {
    changes = [];
    locked = [];
  });

  Future<void> pump(
    WidgetTester tester, {
    bool lockThird = false,
    TextDirection direction = TextDirection.ltr,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: ForgeSegmentedControl<String>(
              segments: [
                const ForgeSegment(value: 'a', label: 'Previous'),
                const ForgeSegment(value: 'b', label: 'First'),
                ForgeSegment(
                  value: 'c',
                  label: 'Other date',
                  locked: lockThird,
                ),
              ],
              selected: 'a',
              onChanged: changes.add,
              onLocked: locked.add,
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('tapping a segment reports its value', (tester) async {
    await pump(tester);

    await tester.tap(find.text('First'));

    expect(changes, ['b']);
  });

  testWidgets('the 36px track takes taps across a 44px band', (tester) async {
    await pump(tester);
    final band = tester.getRect(find.byType(ForgeSegmentedControl<String>));

    expect(band.height, ForgeTheme.tapMin);
    await tester.tapAt(Offset(band.right - 10, band.top + 1));

    expect(changes, ['c']);
  });

  testWidgets('right to left, a tap in the band picks the segment drawn '
      'there', (tester) async {
    await pump(tester, direction: TextDirection.rtl);
    final band = tester.getRect(find.byType(ForgeSegmentedControl<String>));

    await tester.tapAt(Offset(band.right - 10, band.top + 1));
    await tester.tapAt(Offset(band.left + 10, band.top + 1));

    expect(
      tester.getCenter(find.text('Previous')).dx,
      greaterThan(band.center.dx),
    );
    expect(changes, ['a', 'c']);
  });

  testWidgets('a locked segment shows a lock and calls onLocked instead', (
    tester,
  ) async {
    await pump(tester, lockThird: true);

    await tester.tap(find.text('Other date'));

    expect(changes, isEmpty);
    expect(locked, ['c']);
    expect(
      find.byWidgetPredicate(
        (w) => w is ForgeIcon && w.icon == ForgeIcons.lock,
      ),
      findsOneWidget,
    );
  });

  testWidgets('the chosen segment reads as selected', (tester) async {
    await pump(tester);

    expect(
      tester.getSemantics(find.text('Previous')),
      matchesSemantics(
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
        label: 'Previous',
      ),
    );
  });
}
