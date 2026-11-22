import 'package:material_ui/material_ui.dart';
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

/// Tap a bar to pin its tag (tap it again or anywhere else to hide it), or
/// hold and drag across the bars.
@widgetbook.UseCase(name: 'Bar', type: Chart)
Widget barChart(BuildContext context) => _page(_weekBars(context));

/// The bar chart among other content: the page scrolls over it, and a tap
/// outside it hides a pinned tag.
@widgetbook.UseCase(name: 'Bar · on a scrolling page', type: Chart)
Widget barChartScrolling(BuildContext context) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    _weekBars(context),
    for (var i = 0; i < 12; i++) ListRow(title: '[ROW ${i + 1}]'),
  ],
);

Widget _weekBars(BuildContext context) => Chart.bar(
  title: 'Count · this week',
  detail: 'goal [VALUE]',
  bars: const [
    ChartBar(
      label: 'M',
      value: 8.2,
      valueLabel: '8.2k',
      tooltip: '[VALUE] · [DAY 1]',
    ),
    ChartBar(
      label: 'T',
      value: 11.4,
      valueLabel: '11.4k',
      tooltip: '[VALUE] · [DAY 2]',
    ),
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
);

const _bandBars = [
  ChartBar(label: '24', value: 11, valueLabel: '11'),
  ChartBar(label: '31', value: 12, valueLabel: '12'),
  ChartBar(label: '7', value: 13, valueLabel: '13'),
  ChartBar(label: '14', value: 8, valueLabel: '8'),
  ChartBar(label: '21', value: 14, valueLabel: '14'),
  ChartBar(label: '28', value: 16, valueLabel: '16'),
  ChartBar(label: '5', value: 0, valueLabel: '0'),
  ChartBar(label: '12', value: 13, valueLabel: '13'),
  ChartBar(label: '19', value: 15, valueLabel: '15'),
  ChartBar(label: '26', value: 16, valueLabel: '16'),
  ChartBar(label: '2', value: 22, valueLabel: '22'),
  ChartBar(label: '9', value: 14, valueLabel: '14'),
];

@widgetbook.UseCase(name: 'Bar · band', type: Chart)
Widget bandBarChart(BuildContext context) => _page(
  const Chart.bar(
    title: 'Last 12 weeks',
    bars: _bandBars,
    band: (low: 10, high: 20),
    semanticLabel: 'Count over 12 weeks against a 10 to 20 band',
  ),
);

@widgetbook.UseCase(name: 'Bar · band without card', type: Chart)
Widget bareBandBarChart(BuildContext context) => ColoredBox(
  color: Theme.of(context).colorScheme.surface,
  child: _page(
    const Chart.bar(
      title: 'Last 12 weeks',
      bars: _bandBars,
      band: (low: 10, high: 20),
      card: false,
      semanticLabel: 'Count over 12 weeks against a 10 to 20 band',
    ),
  ),
);

@widgetbook.UseCase(name: 'Bar · small labels', type: Chart)
Widget smallLabelBarChart(BuildContext context) => _page(
  Chart.bar(
    title: '12 weeks',
    detail: '[UNIT]',
    bars: [
      for (var i = 0; i < 12; i++)
        ChartBar(
          label: i.isOdd ? '[DATE]' : '',
          value: 30.0 + i * 7919 % 45,
          valueLabel: '${30 + i * 7919 % 45}',
        ),
    ],
    current: 11,
    smallLabels: true,
    semanticLabel: 'Minutes over 12 weeks',
  ),
);

@widgetbook.UseCase(name: 'Bar · dense (30 days)', type: Chart)
Widget denseBarChart(BuildContext context) => _page(
  Chart.barDense(
    title: 'Last 30 days',
    detail: 'goal [VALUE]',
    bars: [
      for (var i = 0; i < 30; i++)
        ChartBar(
          label: '[DATE ${i + 1}]',
          value: 6 + (i * 7919 % 60) / 10,
          tooltip: '[VALUE] · [DATE ${i + 1}]',
        ),
    ],
    current: 29,
    target: 10,
    semanticLabel: 'Count over the last 30 days with a goal line',
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
    retryLabel: 'Retry',
  ),
);
