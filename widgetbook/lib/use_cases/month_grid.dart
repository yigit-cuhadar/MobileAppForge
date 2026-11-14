import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _page(List<Widget> children) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    for (final (i, child) in children.indexed) ...[
      if (i > 0) const SizedBox(height: Gap.sm),
      child,
    ],
  ],
);

const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// The card's sample week, as WeekStrip draws it.
const _week = {
  9: DayState.done,
  10: DayState.light,
  11: DayState.missed,
  12: DayState.light,
  13: DayState.today,
  15: DayState.planned,
};

/// The card's sample month: the week above plus a few days around it.
DayState _monthState(DateTime day) {
  if (day.month == 10) {
    return day.day.isEven ? DayState.done : DayState.none;
  }
  if (day.month != 11) return DayState.none;
  return switch (day.day) {
    2 || 4 || 6 => DayState.done,
    16 || 18 || 20 => DayState.planned,
    _ => _week[day.day] ?? DayState.none,
  };
}

@widgetbook.UseCase(name: 'Month', type: MonthGrid)
Widget monthGrid(BuildContext context) => _page([
  PeriodSelector(
    period: 'November 2026',
    onPrevious: () {},
    onNext: null,
    onPeriodTap: () {},
    previousLabel: 'Previous month',
    nextLabel: 'Next month',
  ),
  MonthGrid(
    month: DateTime(2026, 11),
    firstWeekday: DateTime.monday,
    weekdays: _weekdays,
    stateOf: _monthState,
    summary: '4 done · 3 light · 1 missed',
    legend: const {
      DayState.done: 'Done',
      DayState.light: 'Light',
      DayState.planned: 'Planned',
      DayState.missed: 'Missed',
      DayState.today: 'Today',
    },
  ),
]);

@widgetbook.UseCase(name: 'Loading', type: MonthGrid)
Widget loadingMonthGrid(BuildContext context) =>
    _page([const MonthGrid.loading(weekdays: _weekdays)]);
