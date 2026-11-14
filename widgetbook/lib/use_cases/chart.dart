import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _page(Widget child) =>
    ListView(padding: const EdgeInsets.all(Gap.md), children: [child]);

const _values = <double>[92, 91, 89, 90, 86, 85, 82, 83, 80, 77, 78, 75];

@widgetbook.UseCase(name: 'Line', type: Chart)
Widget lineChart(BuildContext context) => _page(
  Chart.line(
    title: context.knobs.string(label: 'Title', initialValue: 'Value'),
    detail: '— target [VALUE]',
    values: _values,
    pointLabel: (i) => '[VALUE] · week ${i + 1}',
    target: context.knobs.boolean(label: 'Target', initialValue: true)
        ? 52
        : null,
    startLabel: '12 weeks ago',
    endLabel: 'now · [VALUE]',
    semanticLabel: 'Value over 12 weeks with a target line',
  ),
);

@widgetbook.UseCase(name: 'Bar', type: Chart)
Widget barChart(BuildContext context) => _page(
  Chart.bar(
    title: 'Count · this week',
    detail: 'goal [VALUE]',
    bars: const [
      ChartBar(label: 'M', value: 8.2, valueLabel: '8.2k'),
      ChartBar(label: 'T', value: 11.4, valueLabel: '11.4k'),
      ChartBar(label: 'W', value: 6.9, valueLabel: '6.9k'),
      ChartBar(label: 'T', value: 10.3, valueLabel: '10.3k'),
      ChartBar(label: 'F', value: 6.2, valueLabel: '6.2k'),
      ChartBar(label: 'S'),
      ChartBar(label: 'S'),
    ],
    current: context.knobs.int.slider(
      label: 'Current bar',
      initialValue: 4,
      max: 6,
    ),
    target: 10,
    semanticLabel: 'Count this week with a goal line',
  ),
);

@widgetbook.UseCase(name: 'Loading', type: Chart)
Widget loadingChart(BuildContext context) =>
    _page(const Chart.loading(title: 'Value', detail: '12 weeks'));

@widgetbook.UseCase(name: 'Empty', type: Chart)
Widget emptyChart(BuildContext context) => _page(
  Chart.empty(
    title: 'Value',
    detail: '12 weeks',
    emptyTitle: 'No entries yet',
    message: 'Add an entry to start the line.',
    actions: [
      ForgeButton(
        label: 'Add entry',
        onPressed: () {},
        variant: ForgeButtonVariant.secondary,
      ),
    ],
  ),
);

@widgetbook.UseCase(name: 'Error', type: Chart)
Widget errorChart(BuildContext context) => _page(
  Chart.error(
    title: 'Value',
    detail: '12 weeks',
    errorTitle: "Couldn't load the chart",
    message: 'Check your connection and try again.',
    onRetry: () {},
  ),
);
