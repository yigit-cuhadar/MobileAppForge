import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  group('RulerPicker', () {
    late List<double> changes;

    setUp(() => changes = []);

    Future<void> pump(
      WidgetTester tester, {
      double min = 30,
      double max = 300,
      double step = 0.1,
      double value = 80,
    }) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: RulerPicker(
                min: min,
                max: max,
                step: step,
                value: value,
                onChanged: changes.add,
              ),
            ),
          ),
        ),
      ),
    );

    Future<void> drag(WidgetTester tester, double dx) async {
      await tester.drag(find.byType(RulerPicker), Offset(dx, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('reports nothing until dragged', (tester) async {
      await pump(tester);
      await tester.pumpAndSettle();

      expect(changes, isEmpty);
    });

    testWidgets('dragging left picks larger values on the steps, without '
        'floating-point noise', (tester) async {
      await pump(tester);

      await drag(tester, -RulerPicker.tickSpacing * 40);

      expect(changes, isNotEmpty);
      expect(changes.last, greaterThan(80));
      expect(changes.last, lessThanOrEqualTo(84));
      for (final value in changes) {
        expect(value.toString(), matches(RegExp(r'^\d+\.\d$')));
      }
    });

    testWidgets('dragging right picks smaller values', (tester) async {
      await pump(tester, step: 1, value: 100);

      await drag(tester, RulerPicker.tickSpacing * 20);

      expect(changes.last, lessThan(100));
      expect(changes.last, changes.last.roundToDouble());
    });

    testWidgets('stops at the ends', (tester) async {
      await pump(tester, min: 100, max: 120, step: 1, value: 110);

      await drag(tester, -RulerPicker.tickSpacing * 100);
      expect(changes.last, 120);

      await drag(tester, RulerPicker.tickSpacing * 100);
      expect(changes.last, 100);
    });

    testWidgets('follows a new value without reporting it', (tester) async {
      await pump(tester, step: 1, value: 80);
      await pump(tester, step: 1, value: 200);
      await tester.pumpAndSettle();

      expect(changes, isEmpty);

      await drag(tester, -RulerPicker.tickSpacing * 5);
      expect(changes.last, greaterThan(200));
      expect(changes.last, lessThanOrEqualTo(205));
    });

    testWidgets('moves to a new range', (tester) async {
      await pump(tester, min: 100, max: 250, step: 1, value: 180);
      await pump(tester, min: 40, max: 98, step: 1, value: 71);
      await tester.pumpAndSettle();

      await drag(tester, RulerPicker.tickSpacing * 5);
      expect(changes.last, lessThan(71));
      expect(changes.last, greaterThanOrEqualTo(66));
    });
  });
}
