import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  group('time wheel', () {
    late List<TimeOfDay> times;

    setUp(() => times = []);

    Future<void> pumpTime(
      WidgetTester tester, {
      TimeOfDay initial = const TimeOfDay(hour: 18, minute: 0),
      bool h24 = false,
    }) => tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: h24),
          child: child!,
        ),
        home: Scaffold(
          body: ForgeTimeWheel(initial: initial, onChanged: times.add),
        ),
      ),
    );

    /// Drags the wheel showing [text] at its centre by [steps] rows; up
    /// for positive steps.
    Future<void> turn(WidgetTester tester, String text, int steps) async {
      await tester.dragFrom(
        tester.getCenter(find.text(text)),
        Offset(0, -NumberPicker.wheelPitch * steps),
        touchSlopX: 0,
        touchSlopY: 0,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the 12-hour form: hours 1 to 12, minutes and AM/PM', (
      tester,
    ) async {
      await pumpTime(tester);

      expect(find.text('6'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
      expect(find.text('AM'), findsOneWidget);
      expect(find.text('18'), findsNothing);
    });

    testWidgets('the 24-hour form follows the device setting', (tester) async {
      await pumpTime(tester, h24: true);

      expect(find.text('18'), findsOneWidget);
      expect(find.text('PM'), findsNothing);
      expect(find.text('AM'), findsNothing);
    });

    testWidgets('reports each wheel as it turns', (tester) async {
      await pumpTime(tester);

      await turn(tester, '6', 2);
      expect(times.last, const TimeOfDay(hour: 20, minute: 0));

      await turn(tester, 'PM', -1);
      expect(times.last, const TimeOfDay(hour: 8, minute: 0));

      await turn(tester, '00', 15);
      expect(times.last, const TimeOfDay(hour: 8, minute: 15));
    });

    testWidgets('hours and minutes go round', (tester) async {
      await pumpTime(tester, initial: const TimeOfDay(hour: 11, minute: 0));

      await turn(tester, '00', -1);
      expect(times.last, const TimeOfDay(hour: 11, minute: 59));

      await turn(tester, '11', 1);
      expect(times.last, const TimeOfDay(hour: 0, minute: 59));
    });

    testWidgets('a tap outside closes the dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showForgeTimeWheel(
                context: context,
                initial: const TimeOfDay(hour: 7, minute: 30),
                onChanged: times.add,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgeTimeWheel), findsOneWidget);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      expect(find.byType(ForgeTimeWheel), findsNothing);
      expect(times, isEmpty);
    });
  });

  group('duration wheel', () {
    late List<Duration> durations;

    setUp(() => durations = []);

    Future<void> pumpWheel(WidgetTester tester, ForgeDurationWheel wheel) =>
        tester.pumpWidget(
          MaterialApp(
            theme: ForgeTheme.light(),
            home: Scaffold(body: wheel),
          ),
        );

    Future<void> turn(WidgetTester tester, String text, int steps) async {
      await tester.dragFrom(
        tester.getCenter(find.text(text)),
        Offset(0, -NumberPicker.wheelPitch * steps),
        touchSlopX: 0,
        touchSlopY: 0,
      );
      await tester.pumpAndSettle();
    }

    ForgeDurationWheel hoursMinutes(Duration initial) =>
        ForgeDurationWheel.hoursMinutes(
          label: 'Duration',
          initial: initial,
          max: const Duration(hours: 24),
          hourUnit: 'h',
          minuteUnit: 'min',
          onChanged: durations.add,
        );

    testWidgets('hours and minutes, each with its unit', (tester) async {
      await pumpWheel(tester, hoursMinutes(const Duration(minutes: 50)));

      expect(find.text('h'), findsOneWidget);
      expect(find.text('min'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('h')).dx,
        lessThan(tester.getTopLeft(find.text('50')).dx),
      );

      await turn(tester, '0', 1);
      expect(durations.last, const Duration(hours: 1, minutes: 50));

      await turn(tester, '50', 15);
      expect(durations.last, const Duration(hours: 1, minutes: 5));
    });

    testWidgets('stops at max with the minutes at 0', (tester) async {
      await pumpWheel(
        tester,
        hoursMinutes(const Duration(hours: 23, minutes: 30)),
      );

      await turn(tester, '23', 3);

      expect(durations.last, const Duration(hours: 24));
      expect(find.text('24'), findsOneWidget);
      expect(
        tester.getCenter(find.text('00')).dy,
        moreOrLessEquals(tester.getCenter(find.text('24')).dy),
      );
    });

    testWidgets('minutes:seconds in steps, from 0:00 to max', (tester) async {
      await pumpWheel(
        tester,
        ForgeDurationWheel.minutesSeconds(
          label: 'Rest',
          initial: const Duration(minutes: 1, seconds: 30),
          max: const Duration(minutes: 10),
          step: const Duration(seconds: 15),
          onChanged: durations.add,
        ),
      );

      expect(find.text('1:30'), findsOneWidget);
      await turn(tester, '1:30', 2);
      expect(durations.last, const Duration(minutes: 2));

      await turn(tester, '2:00', 60);
      expect(durations.last, const Duration(minutes: 10));

      await turn(tester, '10:00', -100);
      expect(durations.last, Duration.zero);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Rest').last),
        matchesSemantics(
          label: 'Rest',
          value: '0:00',
          increasedValue: '0:15',
          isSlider: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
    });

    testWidgets('the widest minutes:seconds row fits on one line', (
      tester,
    ) async {
      for (final scale in [1.0, 1.5]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ForgeTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: ForgeDurationWheel.minutesSeconds(
                label: 'Rest',
                initial: const Duration(minutes: 10),
                max: const Duration(minutes: 10),
                step: const Duration(seconds: 15),
                onChanged: durations.add,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text('10:00'),
        );
        final column = tester.getRect(
          find
              .ancestor(of: find.text('10:00'), matching: find.byType(SizedBox))
              .last,
        );

        expect(tester.takeException(), isNull);
        // One line: as tall as the text laid out with no width limit.
        expect(
          paragraph.size.height,
          paragraph.getMaxIntrinsicHeight(double.infinity),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
          paragraph.getMaxIntrinsicWidth(double.infinity),
          lessThanOrEqualTo(paragraph.size.width + 0.01),
        );
        expect(paragraph.size.width, lessThanOrEqualTo(column.width));
      }
    });

    testWidgets('a tap outside closes the dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showForgeDurationWheel(
                context: context,
                wheel: hoursMinutes(const Duration(minutes: 50)),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgeDurationWheel), findsOneWidget);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      expect(find.byType(ForgeDurationWheel), findsNothing);
      expect(durations, isEmpty);
    });
  });
}
