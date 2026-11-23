import 'package:material_ui/material_ui.dart';
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
    testWidgets('with onValueTap the value is underlined and a tap on it '
        'calls it', (tester) async {
      var taps = 0;
      await pump(
        tester,
        NumberPicker.ruler(
          label: 'Amount',
          unit: '[UNIT]',
          min: 100,
          max: 250,
          step: 1,
          value: 180,
          onChanged: changes.add,
          onValueTap: () => taps++,
        ),
      );

      final underline = find.ancestor(
        of: find.text('180'),
        matching: find.byType(DecoratedBox),
      );
      expect(underline, findsOneWidget);
      final colors = ForgeStyle.of(tester.element(find.text('180'))).colors;
      expect(
        (tester.widget<DecoratedBox>(underline).decoration as BoxDecoration)
            .border,
        Border(bottom: BorderSide(color: colors.line)),
      );

      await tester.tap(find.text('180'));
      expect(taps, 1);
      expect(changes, isEmpty);
    });

    testWidgets('parts write the value as numbers with small units while '
        'the ruler counts the value', (tester) async {
      await pump(
        tester,
        NumberPicker.ruler(
          label: 'Height',
          parts: (inches) => [
            ('${inches ~/ 12}', 'ft'),
            ('${(inches % 12).round()}', 'in'),
          ],
          min: 48,
          max: 96,
          step: 1,
          value: 71,
          onChanged: changes.add,
          onValueTap: () {},
        ),
      );

      for (final text in ['5', 'ft', '11', 'in']) {
        expect(find.text(text), findsOneWidget);
      }
      final number = tester.widget<Text>(find.text('11')).style!;
      final small = tester.widget<Text>(find.text('in')).style!;
      expect(small.fontSize, lessThan(number.fontSize!));
      // Each number is underlined, as the one value is.
      for (final text in ['5', '11']) {
        expect(
          find.ancestor(
            of: find.text(text),
            matching: find.byType(DecoratedBox),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.ancestor(of: find.text('ft'), matching: find.byType(DecoratedBox)),
        findsNothing,
      );

      await drag(tester, const Offset(-unit, 0));
      expect(changes.last, 72);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('without onValueTap the value is plain', (tester) async {
      await pump(tester, ruler());

      expect(
        find.ancestor(
          of: find.text('80.0'),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    });

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

    testWidgets('the value stays in mono through a drag', (tester) async {
      await pump(tester, ruler(step: 1, value: 80));
      final mono = ForgeStyle.of(tester.element(find.byType(NumberPicker)))
          .data
          .fontFamily;
      String? family(String value) => tester
          .renderObject<RenderParagraph>(find.text(value))
          .text
          .style
          ?.fontFamily;

      expect(family('80'), mono);
      await drag(tester, const Offset(-unit * 2, 0));
      expect(family('82'), mono);
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

    testWidgets('the label goes to screen readers only', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, ruler());

      expect(find.text('Amount'), findsNothing);
      expect(
        tester.getSemantics(find.byType(NumberPicker)),
        matchesSemantics(
          isSlider: true,
          label: 'Amount',
          value: '80.0',
          increasedValue: '80.1',
          decreasedValue: '79.9',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );

      await pump(tester, wheel());
      expect(find.text('Birth year'), findsNothing);
      handle.dispose();
    });

    group('marker', () {
      NumberPicker marked(double at) => NumberPicker.ruler(
        label: 'Amount',
        unit: '[UNIT]',
        min: 30,
        max: 300,
        step: 0.1,
        value: 80,
        onChanged: changes.add,
        marker: (value: at, label: 'Now [VALUE]'),
      );

      RenderObject rulerOf(WidgetTester tester) => tester.renderObject(
        find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == '_RulerPainter',
        ),
      );

      // The test font draws each glyph as wide as its size: 11 × 11px, and
      // 6px either side.
      const tag = 11.0 * 11 + 12;

      PaintPattern tagAt(double left, [Color? color]) => paints
        ..something(
          (method, args) =>
              method == #drawRRect &&
              args[0] ==
                  RRect.fromRectAndRadius(
                    Rect.fromLTWH(left, 0, tag, 20),
                    const Radius.circular(6),
                  ) &&
              (color == null ||
                  (args[1] as Paint).color.toARGB32() == color.toARGB32()),
        );

      testWidgets('tags its value just left of the tick', (tester) async {
        await pump(tester, marked(81));
        final colors = ForgeStyle.of(tester.element(find.byType(NumberPicker)))
            .colors;
        // 81 sits one whole number right of the centred 80.
        const tick = width / 2 + unit;
        expect(rulerOf(tester), tagAt(tick - 6 - tag, colors.accentSoft));
      });

      testWidgets('flips right of the tick near the left edge', (tester) async {
        await pump(tester, marked(78));
        const tick = width / 2 - 2 * unit;
        expect(rulerOf(tester), tagAt(tick + 6));
      });

      testWidgets('reads its label as a hint', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester, marked(81));
        expect(
          tester.getSemantics(find.byType(NumberPicker)),
          matchesSemantics(
            isSlider: true,
            label: 'Amount',
            hint: 'Now [VALUE]',
            value: '80.0',
            increasedValue: '80.1',
            decreasedValue: '79.9',
            hasIncreaseAction: true,
            hasDecreaseAction: true,
          ),
        );
        handle.dispose();
      });

      testWidgets('stays put while the ruler is dragged', (tester) async {
        await pump(tester, marked(81));
        await drag(tester, const Offset(-unit, 0));
        expect(changes.last, closeTo(81, 1e-9));
        // Now centred, the tag ends 6px left of the centre.
        expect(rulerOf(tester), tagAt(width / 2 - 6 - tag));
      });
    });

    testWidgets('a ruler in parts reads them out', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        NumberPicker.ruler(
          label: 'Height',
          parts: (inches) => [
            ('${inches ~/ 12}', 'ft'),
            ('${(inches % 12).round()}', 'in'),
          ],
          min: 48,
          max: 96,
          step: 1,
          value: 71,
          onChanged: changes.add,
        ),
      );

      expect(
        tester.getSemantics(find.byType(NumberPicker)),
        matchesSemantics(
          isSlider: true,
          label: 'Height',
          value: '5 ft 11 in',
          increasedValue: '6 ft 0 in',
          decreasedValue: '5 ft 10 in',
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

    ForgeDurationWheel hoursMinutesSeconds(Duration initial, Duration max) =>
        ForgeDurationWheel.hoursMinutesSeconds(
          label: 'Duration',
          initial: initial,
          max: max,
          hourUnit: 'h',
          minuteUnit: 'min',
          secondUnit: 's',
          onChanged: durations.add,
        );

    testWidgets('hours, minutes and seconds, each with its unit, seconds in '
        '1-second steps', (tester) async {
      await pumpWheel(
        tester,
        hoursMinutesSeconds(
          const Duration(minutes: 28, seconds: 40),
          const Duration(hours: 24),
        ),
      );

      for (final unit in ['h', 'min', 's']) {
        expect(find.text(unit), findsOneWidget);
      }
      final h = tester.getCenter(find.text('h')).dx;
      final min = tester.getCenter(find.text('min')).dx;
      expect(tester.getCenter(find.text('28')).dx, inExclusiveRange(h, min));
      expect(
        tester.getCenter(find.text('40')).dx,
        inExclusiveRange(min, tester.getCenter(find.text('s')).dx),
      );
      expect(tester.takeException(), isNull);

      await turn(tester, '40', 1);
      expect(durations.last, const Duration(minutes: 28, seconds: 41));
      await turn(tester, '41', -1);
      expect(durations.last, const Duration(minutes: 28, seconds: 40));

      await turn(tester, '0', 1);
      expect(
        durations.last,
        const Duration(hours: 1, minutes: 28, seconds: 40),
      );
    });

    testWidgets('seconds go round without moving the minutes', (tester) async {
      await pumpWheel(
        tester,
        hoursMinutesSeconds(
          const Duration(minutes: 28, seconds: 59),
          const Duration(hours: 24),
        ),
      );

      await turn(tester, '59', 1);

      expect(durations.last, const Duration(minutes: 28));
    });

    testWidgets('three wheels fit the dialog at large text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: Scaffold(
            body: hoursMinutesSeconds(
              const Duration(hours: 1),
              const Duration(hours: 24),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a turn past max stays at max', (tester) async {
      await pumpWheel(
        tester,
        hoursMinutesSeconds(
          const Duration(minutes: 59, seconds: 50),
          const Duration(hours: 1),
        ),
      );

      await turn(tester, '0', 1);

      expect(durations.last, const Duration(hours: 1));
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
