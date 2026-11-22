import 'package:material_ui/material_ui.dart';
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

final _from = DateTime(2025, 8, 25);
final _to = DateTime(2025, 11, 16);

/// One point a week from [_from], skipping the weeks in [gaps].
List<ChartPoint> _weekly(List<double> values, {Set<int> gaps = const {}}) => [
  for (final (i, v) in values.indexed)
    if (!gaps.contains(i)) (day: DateTime(2025, 8, 25 + i * 7), value: v),
];

final _a = ChartSeries(
  label: 'Series A',
  points: _weekly(const [92, 91, 89, 90, 86, 85, 82, 83, 80, 77, 78, 75]),
  format: _format,
  look: SeriesLook.accent,
);
final _b = ChartSeries(
  label: 'Series B',
  points: _weekly(
    const [
      30, 29, 28, 28, 25, 24, 22, 22, 19, 18, 17, 15, //
    ],
    gaps: {2, 5, 6, 9},
  ),
  format: _format,
  look: SeriesLook.info,
);
final _c = ChartSeries(
  label: 'Series C',
  points: _weekly(const [60, 60, 58, 58, 56, 54, 54, 52, 50, 50, 48, 46]),
  format: _format,
  look: SeriesLook.success,
);
final _bars = ChartSeries.bars(
  label: 'Series B',
  points: _weekly(const [52, 60, 44, 70, 66, 78, 58, 84, 74, 90, 80, 72]),
  format: _format,
);

String _date(DateTime day) => '[DATE]';

Widget _chart(
  List<ChartSeries> series, {
  bool adding = false,
  Widget? range,
  String? caption,
  String? lockedCaption,
}) => MultiSeriesChart(
  title: 'Series',
  detail: '12 weeks',
  series: series,
  from: _from,
  to: _to,
  dateLabel: _date,
  startLabel: 'Aug 25',
  endLabel: 'Nov 16',
  onSeriesTap: (_) {},
  addLabel: 'Add',
  onAdd: () {},
  adding: adding,
  range: range,
  caption: caption,
  lockedCaption: lockedCaption,
  onLockedCaptionTap: lockedCaption == null ? null : () {},
  semanticLabel: 'Series over 12 weeks',
);

@widgetbook.UseCase(name: 'Three series', type: MultiSeriesChart)
Widget threeSeries(BuildContext context) => _page([
  _chart(
    [_a, _b, _c],
    caption: context.knobs.boolean(label: 'Caption', initialValue: true)
        ? 'Each series keeps its own scale; tap the chart for the values '
              'on a day.'
        : null,
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
      points: _a.points,
      format: _format,
      look: SeriesLook.accent,
      target: 74,
      targetLabel: 'Target',
    ),
    _c,
  ]),
]);

/// Daily values every second or third day with their rolling mean.
final _daily = [
  for (var i = 0; i < 84; i += i % 3 == 0 ? 2 : 3)
    (day: DateTime(2025, 8, 25 + i), value: 92 - i * 0.2 + (i % 4 - 1.5)),
];

/// The mean of the daily values in the 7 days ending [day].
ChartPoint _mean(DateTime day) {
  final week = [
    for (final p in _daily)
      if (!p.day.isAfter(day) && day.difference(p.day).inDays < 7) p.value,
  ];
  return (day: day, value: week.reduce((a, b) => a + b) / week.length);
}

@widgetbook.UseCase(name: 'Daily and average', type: MultiSeriesChart)
Widget averagedSeries(BuildContext context) => _page([
  _chart([
    ChartSeries.averaged(
      label: 'Series A',
      points: _daily,
      average: [for (final p in _daily) _mean(p.day)],
      dailyLabel: 'daily value',
      averageLabel: '7-day average',
      format: _format,
      look: SeriesLook.accent,
      target: 74,
      targetLabel: 'Target',
    ),
    _b,
  ]),
]);

@widgetbook.UseCase(name: 'One point', type: MultiSeriesChart)
Widget onePointSeries(BuildContext context) {
  final point = (day: DateTime(2025, 11, 16), value: 80.0);
  return _page([
    _chart([
      ChartSeries.averaged(
        label: 'Series A',
        points: [point],
        average: [point],
        dailyLabel: 'daily value',
        averageLabel: '7-day average',
        format: _format,
        look: SeriesLook.accent,
        target: 74,
        targetLabel: 'Target',
      ),
    ]),
  ]);
}

@widgetbook.UseCase(name: 'Range and locked caption', type: MultiSeriesChart)
Widget rangeSeries(BuildContext context) => _page([
  _chart(
    [_a, _b],
    range: ForgeSegmentedControl<int>(
      segments: const [
        ForgeSegment(value: 0, label: '12 weeks'),
        ForgeSegment(value: 1, label: '6 months', locked: true),
        ForgeSegment(value: 2, label: '1 year', locked: true),
        ForgeSegment(value: 3, label: 'All', locked: true),
      ],
      selected: 0,
      onChanged: (_) {},
      onLocked: (_) {},
    ),
    lockedCaption:
        context.knobs.boolean(label: 'Locked caption', initialValue: true)
        ? 'See older results with Premium'
        : null,
  ),
]);

@widgetbook.UseCase(name: 'Series error', type: MultiSeriesChart)
Widget seriesError(BuildContext context) => _page([
  _chart([
    _a,
    ChartSeries.failed(
      label: 'Series B',
      look: SeriesLook.info,
      error: "Couldn't load Series B.",
      retryLabel: 'Retry',
      onRetry: () {},
    ),
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

/// A share from 0 to 1 a week, falling by [step]; [weeks] of the 12 have
/// one, the latest missing.
ChartSeries _share(
  String label,
  SeriesLook look,
  double first,
  double step,
  int weeks,
) => ChartSeries(
  label: label,
  points: _weekly([for (var i = 0; i < weeks; i++) first - i * step]),
  format: _format,
  look: look,
);

@widgetbook.UseCase(name: 'Shared scale', type: MultiSeriesChart)
Widget sharedScale(BuildContext context) {
  final count = context.knobs.int.slider(
    label: 'Series',
    initialValue: 3,
    min: 1,
    max: 3,
  );
  return _page([
    MultiSeriesChart.shared(
      title: 'Series',
      detail: '12 weeks',
      series: [
        _share('Series A', SeriesLook.accent, 0.58, 0.008, 12),
        _share('Series B', SeriesLook.info, 0.31, 0.006, 11),
        _share('Series C', SeriesLook.success, 0.16, 0.004, 8),
      ].take(count).toList(),
      gridlines: const [
        (value: 0, label: '0%'),
        (value: 0.25, label: '25%'),
        (value: 0.5, label: '50%'),
      ],
      from: _from,
      to: DateTime(2025, 11, 10),
      dateLabel: _date,
      startLabel: 'Aug 25',
      endLabel: 'Nov 10',
      semanticLabel: 'Series over 12 weeks',
    ),
  ]);
}

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

@widgetbook.UseCase(name: 'Empty range', type: MultiSeriesChart)
Widget emptyRangeSeries(BuildContext context) => _page([
  MultiSeriesChart.empty(
    title: '12 weeks',
    emptyTitle: 'Nothing in this range',
    message: 'Nothing to show in this range yet.',
    range: ForgeSegmentedControl<int>(
      segments: const [
        ForgeSegment(value: 0, label: '12 weeks'),
        ForgeSegment(value: 1, label: '6 months', locked: true),
        ForgeSegment(value: 2, label: '1 year', locked: true),
        ForgeSegment(value: 3, label: 'All', locked: true),
      ],
      selected: 0,
      onChanged: (_) {},
      onLocked: (_) {},
    ),
    lockedCaption: 'See older results with Premium',
    onLockedCaptionTap: () {},
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
