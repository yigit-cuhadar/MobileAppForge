import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  late List<double> changes;

  setUp(() => changes = []);

  const width = 360.0;
  const unit = width / NumberPicker.rulerSpan;

  Future<void> pump(WidgetTester tester, NumberPicker picker) =>
      tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(width: width, child: picker),
            ),
          ),
        ),
      );

  NumberPicker ruler({
    double min = 30,
    double max = 300,
    double step = 0.1,
    double value = 80,
  }) => NumberPicker.ruler(
    label: 'Amount',
    unit: '[UNIT]',
    min: min,
    max: max,
    step: step,
    value: value,
    onChanged: changes.add,
  );

  NumberPicker wheel({double value = 1995}) => NumberPicker.wheel(
    label: 'Birth year',
    min: 1900,
    max: 2020,
    step: 1,
    value: value,
    onChanged: changes.add,
    grouped: false,
  );

  /// Drags [by] from just above the picker's bottom, on the wheel or the
  /// ruler.
  Future<void> drag(WidgetTester tester, Offset by) async {
    await tester.dragFrom(
      tester.getRect(find.byType(NumberPicker)).bottomCenter -
          const Offset(0, 20),
      by,
      touchSlopX: 0,
      touchSlopY: 0,
    );
    await tester.pumpAndSettle();
  }

  group('ruler', () {
    testWidgets('shows the value and the unit, reports nothing until '
        'dragged', (tester) async {
      await pump(tester, ruler());
      await tester.pumpAndSettle();

      expect(find.text('80.0'), findsOneWidget);
      expect(find.text('[UNIT]'), findsOneWidget);
      expect(changes, isEmpty);
    });

    testWidgets('dragging left picks larger values on the steps, without '
        'floating-point noise', (tester) async {
      await pump(tester, ruler());

      await drag(tester, const Offset(-unit * 2, 0));

      expect(changes.last, closeTo(82, 0.11));
      for (final value in changes) {
        expect(value.toString(), matches(RegExp(r'^\d+\.\d$')));
      }
      expect(find.text(changes.last.toStringAsFixed(1)), findsOneWidget);
    });

    testWidgets('stops at the ends', (tester) async {
      await pump(tester, ruler(min: 80, max: 84, step: 1, value: 82));

      await drag(tester, const Offset(-unit * 10, 0));
      expect(changes.last, 84);

      await drag(tester, const Offset(unit * 10, 0));
      expect(changes.last, 80);
    });

    testWidgets('follows a new value without reporting it', (tester) async {
      await pump(tester, ruler(step: 1, value: 80));
      await pump(tester, ruler(step: 1, value: 200));
      await tester.pumpAndSettle();

      expect(changes, isEmpty);
      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('never reports past max when the range is no whole number '
        'of steps', (tester) async {
      await pump(tester, ruler(min: 0, max: 10, step: 4, value: 4));

      await drag(tester, const Offset(-unit * 20, 0));

      expect(changes.last, 8);
    });
  });

  group('wheel', () {
    testWidgets('dragging up picks larger values', (tester) async {
      await pump(tester, wheel());

      await drag(tester, const Offset(0, -NumberPicker.wheelPitch * 2));

      expect(changes.last, 1997);
    });

    testWidgets('dragging down picks smaller values', (tester) async {
      await pump(tester, wheel());

      await drag(tester, const Offset(0, NumberPicker.wheelPitch * 3));

      expect(changes.last, 1992);
    });
  });

  group('grouping', () {
    testWidgets('groups the thousands by default', (tester) async {
      await pump(
        tester,
        NumberPicker.wheel(
          label: 'Amount',
          min: 0,
          max: 100000,
          step: 1000,
          value: 50000,
          onChanged: changes.add,
        ),
      );

      expect(find.text('50,000'), findsOneWidget);
      expect(find.text('1,000'), findsNothing);
      expect(find.text('49,000'), findsOneWidget);
    });

    testWidgets('a year stays whole when grouping is off', (tester) async {
      await pump(tester, wheel());

      expect(find.text('1995'), findsOneWidget);
      expect(find.text('1,995'), findsNothing);
    });
  });

  group('semantics', () {
    testWidgets('one slider node with the label, whole steps without '
        'decimals', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, wheel());

      expect(
        tester.getSemantics(find.byType(NumberPicker)),
        matchesSemantics(
          isSlider: true,
          label: 'Birth year',
          value: '1995',
          increasedValue: '1996',
          decreasedValue: '1994',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('increase and decrease move one step and report it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, ruler());
      final node = tester.getSemantics(find.byType(NumberPicker));

      node.owner!.performAction(node.id, SemanticsAction.increase);
      await tester.pumpAndSettle();
      expect(changes, [80.1]);

      node.owner!.performAction(node.id, SemanticsAction.decrease);
      await tester.pumpAndSettle();
      expect(changes, [80.1, 80.0]);
      handle.dispose();
    });
  });
}
