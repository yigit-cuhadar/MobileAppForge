import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _page(List<Widget> children) =>
    ListView(padding: const EdgeInsets.all(Gap.md), children: children);

@widgetbook.UseCase(name: 'Week · current', type: PeriodSelector)
Widget weekPeriod(BuildContext context) => _page([
  PeriodSelector(
    period: 'Nov 9–15',
    onPrevious: () {},
    onNext: null,
    onPeriodTap: () {},
    previousLabel: 'Previous',
    nextLabel: 'Next',
  ),
]);

@widgetbook.UseCase(name: 'Month', type: PeriodSelector)
Widget monthPeriod(BuildContext context) => _page([
  PeriodSelector(
    period: context.knobs.string(
      label: 'Period',
      initialValue: 'November 2026',
    ),
    onPrevious: () {},
    onNext: () {},
    onPeriodTap: () {},
    previousLabel: 'Previous',
    nextLabel: 'Next',
  ),
]);

@widgetbook.UseCase(name: 'Year', type: PeriodSelector)
Widget yearPeriod(BuildContext context) => _page([
  PeriodSelector(
    period: '2026',
    onPrevious: () {},
    onNext: () {},
    onPeriodTap: () {},
    previousLabel: 'Previous',
    nextLabel: 'Next',
  ),
]);
