import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:forge_ui/src/widgets/day_circle.dart';
import 'package:forge_ui/src/widgets/card_frame.dart';

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
              semanticLabel: 'Day ${9 + i}',
            ),
        ],
        onDayTap: tapped.add,
      ),
    );

    await tester.tap(find.text('11'));
    await tester.tap(find.text('13'));
    expect(tapped, [2, 4]);
    expect(
      tester.getSemantics(find.text('13')),
      matchesSemantics(
        label: 'Day 13',
        isButton: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
  });

  testWidgets('WeekStrip.plain draws no card or title', (tester) async {
    final tapped = <int>[];
    await pump(
      tester,
      WeekStrip.plain(
        days: [
          for (var i = 0; i < 7; i++)
            WeekStripDay(
              weekday: weekdays[i],
              number: '${9 + i}',
              state: DayState.none,
              semanticLabel: 'Day ${9 + i}',
            ),
        ],
        onDayTap: tapped.add,
      ),
    );

    expect(find.byType(CardFrame), findsNothing);
    expect(find.text('M'), findsOneWidget);
    await tester.tap(find.text('15'));
    expect(tapped, [6]);
    expect(find.bySemanticsLabel('Day 15'), findsOneWidget);
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

    testWidgets('a tap reports its day and the selected day is ringed', (
      tester,
    ) async {
      final tapped = <DateTime>[];
      await pump(
        tester,
        MonthGrid(
          month: DateTime(2026, 11),
          firstWeekday: DateTime.monday,
          weekdays: weekdays,
          stateOf: (day) => day.day == 9 ? DayState.done : DayState.none,
          summary: '',
          legend: const {},
          selected: DateTime(2026, 11, 14),
          onDayTap: tapped.add,
        ),
      );

      await tester.tap(find.text('18'));
      expect(tapped, [DateTime(2026, 11, 18)]);

      DayCircle circle(String n) => tester.widget(
        find.ancestor(of: find.text(n), matching: find.byType(DayCircle)),
      );
      expect(circle('14').selected, isTrue);
      expect(circle('18').selected, isFalse);
    });

    testWidgets('error keeps the letters and retries on one line', (
      tester,
    ) async {
      var retries = 0;
      await pump(
        tester,
        MonthGrid.error(
          weekdays: weekdays,
          message: "Couldn't load the month",
          retryLabel: 'Retry',
          onRetry: () => retries++,
        ),
      );
      expect(find.text('M'), findsOneWidget);
      expect(find.byType(DayCircle), findsNothing);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('without a summary the letters lead the card', (tester) async {
      await pump(
        tester,
        MonthGrid(
          month: DateTime(2026, 11),
          firstWeekday: DateTime.monday,
          weekdays: weekdays,
          stateOf: (_) => DayState.none,
          legend: const {},
        ),
      );
      final card = tester.getRect(find.byType(MonthGrid));
      expect(
        tester.getTopLeft(find.text('M')).dy - card.top,
        lessThan(Gap.md + 16),
      );
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

  testWidgets('a selected empty day is accent-soft inside an accent ring', (
    tester,
  ) async {
    await pump(
      tester,
      const Center(
        child: DayCircle(state: DayState.none, number: '14', selected: true),
      ),
    );
    final colors = ForgeTheme.light().extension<ForgeStyle>()!.colors;
    final decoration =
        tester
                .widget<Container>(
                  find.ancestor(
                    of: find.text('14'),
                    matching: find.byType(Container),
                  ),
                )
                .decoration!
            as BoxDecoration;
    expect(decoration.color, colors.accentSoft);
    expect(decoration.border!.top.color, colors.accent);
    expect(decoration.border!.top.width, 1.5);
  });

  testWidgets('a selected marked day keeps its fill and gains a ring', (
    tester,
  ) async {
    await pump(
      tester,
      const Center(
        child: DayCircle(state: DayState.done, number: '9', selected: true),
      ),
    );
    final colors = ForgeTheme.light().extension<ForgeStyle>()!.colors;
    final decoration =
        tester
                .widget<Container>(
                  find.ancestor(
                    of: find.text('9'),
                    matching: find.byType(Container),
                  ),
                )
                .decoration!
            as BoxDecoration;
    expect(decoration.color, colors.accent);
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

  group('ForgeDatePicker', () {
    late List<DateTime?> picked;

    setUp(() => picked = []);

    Future<void> openPicker(WidgetTester tester, {DateTime? initial}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => picked.add(
                  await showForgeDatePicker(
                    context: context,
                    picker: ForgeDatePicker(
                      title: 'Select date',
                      initial: initial ?? DateTime(2026, 11, 13, 8, 10),
                      lastDate: DateTime(2026, 11, 13, 23),
                      firstWeekday: DateTime.monday,
                      weekdays: weekdays,
                      okLabel: 'OK',
                      cancelLabel: 'Cancel',
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    Finder day(String number) => find
        .descendant(
          of: find.byType(ForgeDatePicker),
          matching: find.text(number),
        )
        .first;

    testWidgets('shows the chosen day and its month, the day filled', (
      tester,
    ) async {
      await openPicker(tester);

      expect(find.text('Select date'), findsOneWidget);
      expect(find.text('Fri, Nov 13'), findsOneWidget);
      expect(find.text('November 2026'), findsOneWidget);
      expect(
        tester.widget<DayCircle>(
          find.ancestor(of: day('13'), matching: find.byType(DayCircle)),
        ),
        isA<DayCircle>().having((c) => c.state, 'state', DayState.done),
      );
    });

    testWidgets('OK returns the tapped day as a date', (tester) async {
      await openPicker(tester);

      await tester.tap(day('10'));
      await tester.pump();
      expect(find.text('Tue, Nov 10'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(picked, [DateTime(2026, 11, 10)]);
      expect(find.byType(ForgeDatePicker), findsNothing);
    });

    testWidgets('Cancel returns null', (tester) async {
      await openPicker(tester);

      await tester.tap(day('10'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(picked, [null]);
    });

    testWidgets('days after the last date are line-strong and take no tap', (
      tester,
    ) async {
      await openPicker(tester);

      final colors = ForgeStyle.of(tester.element(find.byType(ForgeDatePicker)))
          .colors;
      expect(tester.widget<Text>(day('14')).style?.color, colors.lineStrong);
      await tester.tap(day('14'));
      await tester.pump();
      expect(find.text('Fri, Nov 13'), findsOneWidget);
    });

    testWidgets('the next arrow is off in the last month; previous steps '
        'back and next returns', (tester) async {
      await openPicker(tester);

      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();
      expect(find.text('November 2026'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Previous month'));
      await tester.pump();
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Fri, Nov 13'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();
      expect(find.text('November 2026'), findsOneWidget);
    });

    testWidgets('a day of the month before is picked and shows its month', (
      tester,
    ) async {
      await openPicker(tester);

      // The first week starts on Monday, October 26.
      await tester.tap(day('26'));
      await tester.pump();

      expect(find.text('Mon, Oct 26'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
    });
  });
}
