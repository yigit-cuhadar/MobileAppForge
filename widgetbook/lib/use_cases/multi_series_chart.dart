import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
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

String _format(double value) => '[VALUE]';

const _a = ChartSeries(
  label: 'Series A',
  values: [92, 91, 89, 90, 86, 85, 82, 83, 80, 77, 78, 75],
  format: _format,
  look: SeriesLook.accent,
);
const _b = ChartSeries(
  label: 'Series B',
  values: [30, 29, 28, 28, 25, 24, 22, 22, 19, 18, 17, 15],
  format: _format,
  look: SeriesLook.info,
);
const _c = ChartSeries(
  label: 'Series C',
  values: [60, 60, 58, 58, 56, 54, 54, 52, 50, 50, 48, 46],
  format: _format,
  look: SeriesLook.success,
);
const _bars = ChartSeries.bars(
  label: 'Series B',
  values: [52, 60, 44, 70, 66, 78, 58, 84, 74, 90, 80, 72],
  format: _format,
);

Widget _chart(List<ChartSeries> series, {bool adding = false}) =>
    MultiSeriesChart(
      title: 'Series',
      detail: '12 weeks',
      series: series,
      dateLabel: (i) => 'Week ${i + 1}',
      startLabel: 'Aug 25',
      endLabel: 'Nov 10',
      onSeriesTap: (_) {},
      addLabel: 'Add',
      onAdd: () {},
      adding: adding,
      semanticLabel: 'Series over 12 weeks',
    );

@widgetbook.UseCase(name: 'Three series', type: MultiSeriesChart)
Widget threeSeries(BuildContext context) => _page([
  MultiSeriesChart(
    title: 'Series',
    detail: '12 weeks',
    series: [_a, _b, _c],
    dateLabel: (i) => 'Week ${i + 1}',
    startLabel: 'Aug 25',
    endLabel: 'Nov 10',
    onSeriesTap: (_) {},
    addLabel: 'Add',
    onAdd: () {},
    caption: context.knobs.boolean(label: 'Caption', initialValue: true)
        ? 'Each series keeps its own scale; tap the chart for the values '
              'on a day.'
        : null,
    semanticLabel: 'Three series over 12 weeks',
  ),
]);

@widgetbook.UseCase(name: 'Bar series', type: MultiSeriesChart)
Widget barSeries(BuildContext context) => _page([
  _chart([_a, _bars]),
]);

@widgetbook.UseCase(name: 'Target', type: MultiSeriesChart)
Widget targetSeries(BuildContext context) => _page([
  _chart([
    ChartSeries(
      label: 'Series A',
      values: _a.values,
      format: _format,
      look: SeriesLook.accent,
      target: 78,
      targetLabel: 'Target',
    ),
    _c,
  ]),
]);

@widgetbook.UseCase(name: 'Add series list', type: MultiSeriesChart)
Widget addSeriesList(BuildContext context) => _page([
  _chart([_a, _b], adding: true),
  ListRowCard(
    children: [
      ListRow(
        title: 'Series D',
        leading: const SeriesSample.neutral(),
        end: ListRowEnd.chevron,
        onTap: () {},
      ),
      ListRow(
        title: 'Series E',
        leading: const SeriesSample.neutral(locked: true),
        trailing: const ForgeTag('Premium', kind: ForgeTagKind.premium),
        locked: true,
        onTap: () {},
      ),
      ListRow(
        title: 'Series F',
        leading: const SeriesSample.neutral(locked: true),
        trailing: const ForgeTag('Premium', kind: ForgeTagKind.premium),
        locked: true,
        onTap: () {},
      ),
    ],
  ),
]);

@widgetbook.UseCase(name: 'Loading', type: MultiSeriesChart)
Widget loadingSeries(BuildContext context) => _page([
  const MultiSeriesChart.loading(title: 'Series', detail: '12 weeks'),
]);

@widgetbook.UseCase(name: 'Empty', type: MultiSeriesChart)
Widget emptySeries(BuildContext context) => _page([
  MultiSeriesChart.empty(
    title: 'Series',
    detail: '12 weeks',
    emptyTitle: 'Nothing to chart yet',
    message: 'Series show here after the first entries.',
    actions: [
      ForgeButton(
        label: 'Add entries',
        onPressed: () {},
        variant: ForgeButtonVariant.secondary,
      ),
    ],
  ),
]);

@widgetbook.UseCase(name: 'Error', type: MultiSeriesChart)
Widget errorSeries(BuildContext context) => _page([
  MultiSeriesChart.error(
    title: 'Series',
    detail: '12 weeks',
    errorTitle: "Couldn't load the chart",
    message: 'Check your connection and try again.',
    onRetry: () {},
    retryLabel: 'Retry',
  ),
]);
