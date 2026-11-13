import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

    testWidgets('never reports past max when the range is no whole number '
        'of steps', (tester) async {
      await pump(tester, min: 0, max: 10, step: 4, value: 4);

      await drag(tester, -RulerPicker.tickSpacing * 20);

      expect(changes.last, 8);
    });

    testWidgets('a fling comes to rest on a tick', (tester) async {
      await pump(tester, step: 1, value: 100);

      await tester.fling(find.byType(RulerPicker), const Offset(-123, 0), 1000);
      await tester.pumpAndSettle();

      final pixels = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .pixels;
      expect(pixels % RulerPicker.tickSpacing, closeTo(0, 1e-6));
      expect(changes.last, 100 + pixels / RulerPicker.tickSpacing - 70);
    });

    group('semantics', () {
      testWidgets('one slider node, whole steps without decimals', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pump(tester, step: 1, value: 80);

        expect(
          tester.getSemantics(find.byType(RulerPicker)),
          matchesSemantics(
            isSlider: true,
            value: '80',
            increasedValue: '81',
            decreasedValue: '79',
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
        await pump(tester, value: 80);
        final node = tester.getSemantics(find.byType(RulerPicker));

        node.owner!.performAction(node.id, SemanticsAction.increase);
        await tester.pumpAndSettle();
        expect(changes, [80.1]);
        expect(
          tester.getSemantics(find.byType(RulerPicker)),
          matchesSemantics(
            isSlider: true,
            value: '80.1',
            increasedValue: '80.2',
            decreasedValue: '80.0',
            hasIncreaseAction: true,
            hasDecreaseAction: true,
          ),
        );

        node.owner!.performAction(node.id, SemanticsAction.decrease);
        await tester.pumpAndSettle();
        expect(changes, [80.1, 80.0]);
        handle.dispose();
      });
    });
  });
}
