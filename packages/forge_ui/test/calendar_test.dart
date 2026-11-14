import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:forge_ui/src/widgets/day_circle.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [child],
        ),
      ),
    ),
  );

  const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  testWidgets('WeekStrip reports the tapped day', (tester) async {
    final tapped = <int>[];
    await pump(
      tester,
      WeekStrip(
        title: 'This week',
        days: [
          for (var i = 0; i < 7; i++)
            WeekStripDay(
              weekday: weekdays[i],
              number: '${9 + i}',
              state: i == 4 ? DayState.today : DayState.none,
            ),
        ],
        onDayTap: tapped.add,
      ),
    );

    await tester.tap(find.text('11'));
    await tester.tap(find.text('13'));
    expect(tapped, [2, 4]);
  });

  group('MonthGrid', () {
    testWidgets('lays out the weeks that hold the month', (tester) async {
      final asked = <DateTime>[];
      await pump(
        tester,
        MonthGrid(
          month: DateTime(2026, 11),
          firstWeekday: DateTime.monday,
          weekdays: weekdays,
          stateOf: (day) {
            asked.add(day);
            return day == DateTime(2026, 11, 13)
                ? DayState.today
                : DayState.none;
          },
          summary: '4 done · 3 light · 1 missed',
          legend: const {DayState.done: 'Done', DayState.today: 'Today'},
        ),
      );

      // November 2026 starts on a Sunday: Oct 26 to Dec 6, six weeks.
      expect(asked, hasLength(42));
      expect(asked.first, DateTime(2026, 10, 26));
      expect(asked.last, DateTime(2026, 12, 6));
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('4 done · 3 light · 1 missed'), findsOneWidget);
      // Days outside the month are faded.
      expect(
        find.ancestor(
          of: find.text('26').first,
          matching: find.byType(Opacity),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(of: find.text('13'), matching: find.byType(Opacity)),
        findsNothing,
      );
    });

    testWidgets('a Sunday start shifts the grid', (tester) async {
      final asked = <DateTime>[];
      await pump(
        tester,
        MonthGrid(
          month: DateTime(2026, 11),
          firstWeekday: DateTime.sunday,
          weekdays: weekdays,
          stateOf: (day) {
            asked.add(day);
            return DayState.none;
          },
          summary: '',
          legend: const {},
        ),
      );
      expect(asked.first, DateTime(2026, 11, 1));
      expect(asked, hasLength(35));
    });

    testWidgets('loading keeps the weekday letters', (tester) async {
      await pump(tester, const MonthGrid.loading(weekdays: weekdays));
      expect(find.text('M'), findsOneWidget);
      expect(find.byType(SkeletonBar), findsNWidgets(1 + 42 + 4));
    });
  });

  group('PeriodSelector', () {
    testWidgets('steps and opens the picker', (tester) async {
      final calls = <String>[];
      await pump(
        tester,
        PeriodSelector(
          period: 'November 2026',
          onPrevious: () => calls.add('previous'),
          onNext: () => calls.add('next'),
          onPeriodTap: () => calls.add('period'),
          previousLabel: 'Previous month',
          nextLabel: 'Next month',
        ),
      );

      await tester.tap(find.bySemanticsLabel('Previous month'));
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.tap(find.text('November 2026'));
      expect(calls, ['previous', 'next', 'period']);
    });

    testWidgets('in the current period the forward arrow fades', (
      tester,
    ) async {
      await pump(
        tester,
        PeriodSelector(
          period: 'Nov 9–15',
          onPrevious: () {},
          onNext: null,
          onPeriodTap: () {},
          previousLabel: 'Previous',
          nextLabel: 'Next',
        ),
      );

      final next = find.bySemanticsLabel('Next');
      expect(tester.getSemantics(next), isSemantics(isEnabled: false));
      expect(
        tester
            .widget<Opacity>(
              find.ancestor(of: next, matching: find.byType(Opacity)),
            )
            .opacity,
        0.3,
      );
    });
  });

  testWidgets('today and done keeps the fill with a ring outside it', (
    tester,
  ) async {
    await pump(
      tester,
      const Center(
        child: DayCircle(state: DayState.todayDone, number: '13'),
      ),
    );
    final colors = ForgeTheme.light().extension<ForgeStyle>()!.colors;

    expect(tester.widget<Text>(find.text('13')).style!.color, colors.onAccent);
    expect(
      tester.getSize(find.byType(DayCircle)),
      const Size.square(DayCircle.daySize),
    );
    final ring = tester.widget<CustomPaint>(
      find
          .descendant(
            of: find.byType(DayCircle),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    expect(ring.foregroundPainter, isNotNull);
  });
}
