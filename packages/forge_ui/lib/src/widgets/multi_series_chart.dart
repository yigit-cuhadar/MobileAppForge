import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_palette.dart';
import '../theme/forge_preset.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';
import 'card_frame.dart';
import 'error_line.dart';
import 'chart_paint.dart';
import 'forge_chip.dart';
import 'skeleton.dart';
import 'state_views.dart';

/// How a series of a [MultiSeriesChart] is drawn.
enum SeriesLook {
  /// A solid accent line.
  accent,

  /// A dashed info line.
  info,

  /// A dotted success line.
  success,
}

/// A value on a day.
typedef ChartPoint = ({DateTime day, double value});

/// One series of a [MultiSeriesChart]: dated [points], as sparse as the
/// entries are, written by [format]. A [target] is a thin dashed line in
/// the series' colour with its [targetLabel] at the right end.
class ChartSeries {
  const ChartSeries({
    required this.label,
    required this.points,
    required this.format,
    this.formatPoint,
    required this.look,
    this.target,
    this.targetLabel,
  }) : bars = false,
       average = null,
       dailyLabel = null,
       averageLabel = null,
       error = null,
       retryLabel = null,
       onRetry = null,
       assert((target == null) == (targetLabel == null));

  /// The daily [points] as a thin line-strong line under their [average]
  /// (such as a rolling 7-day mean) drawn thick in the series' look; a
  /// legend under the chart names both. One series of a chart at most.
  const ChartSeries.averaged({
    required this.label,
    required this.points,
    required List<ChartPoint> this.average,
    required String this.dailyLabel,
    required String this.averageLabel,
    required this.format,
    this.formatPoint,
    required this.look,
    this.target,
    this.targetLabel,
  }) : bars = false,
       error = null,
       retryLabel = null,
       onRetry = null,
       assert((target == null) == (targetLabel == null));

  /// A weekly series: each point is a week's first day, drawn as an info
  /// bar at 40% across that week behind the lines.
  const ChartSeries.bars({
    required this.label,
    required this.points,
    required this.format,
    this.formatPoint,
  }) : look = SeriesLook.info,
       bars = true,
       target = null,
       targetLabel = null,
       average = null,
       dailyLabel = null,
       averageLabel = null,
       error = null,
       retryLabel = null,
       onRetry = null;

  /// The series could not load: its chip stays, nothing is drawn, and
  /// its [error] shows under the chips with an outline Retry.
  const ChartSeries.failed({
    required this.label,
    required this.look,
    required String this.error,
    required String this.retryLabel,
    required VoidCallback this.onRetry,
  }) : points = const [],
       format = _none,
       formatPoint = null,
       bars = false,
       target = null,
       targetLabel = null,
       average = null,
       dailyLabel = null,
       averageLabel = null;

  final String label;
  final List<ChartPoint> points;
  final String Function(double value) format;

  /// Writes a point in the tap tag in place of [format], given the point
  /// itself, so the app can find the entry behind its day.
  final String Function(ChartPoint point)? formatPoint;
  final SeriesLook look;
  final bool bars;
  final double? target;
  final String? targetLabel;
  final List<ChartPoint>? average;
  final String? dailyLabel;
  final String? averageLabel;
  final String? error;
  final String? retryLabel;
  final VoidCallback? onRetry;
}

String _none(double value) => '';

/// The sample of a series' line (or bars) on its chip and in its tag row;
/// [SeriesSample.neutral] is the plain line of a series not on the chart
/// yet, ink-subtle when it is locked.
class SeriesSample extends StatelessWidget {
  const SeriesSample(SeriesLook this.look, {super.key, this.bars = false})
    : locked = false;

  const SeriesSample.neutral({super.key, this.locked = false})
    : look = null,
      bars = false;

  final SeriesLook? look;
  final bool bars;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final p = ForgeStyle.of(context).colors;
    final look = this.look;
    final color = look == null
        ? (locked ? p.inkSubtle : p.inkMuted)
        : _color(look, p);
    return SizedBox(
      width: 16,
      height: bars ? 10 : 6,
      child: CustomPaint(
        painter: _SamplePainter(look: look, bars: bars, color: color),
      ),
    );
  }
}

class _SamplePainter extends CustomPainter {
  const _SamplePainter({
    required this.look,
    required this.bars,
    required this.color,
  });

  final SeriesLook? look;
  final bool bars;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars) {
      final paint = Paint()..color = color.withValues(alpha: 0.5);
      for (final (x, y) in const [(1.0, 4.0), (6.0, 1.0), (11.0, 3.0)]) {
        canvas.drawRRect(
          RRect.fromLTRBR(x, y, x + 4, size.height, const Radius.circular(1)),
          paint,
        );
      }
      return;
    }
    final y = size.height / 2;
    canvas.drawPath(
      _stroke(
        Path()
          ..moveTo(0, y)
          ..lineTo(size.width, y),
        look,
      ),
      _linePaint(color),
    );
  }

  @override
  bool shouldRepaint(_SamplePainter old) =>
      old.look != look || old.bars != bars || old.color != color;
}

Color _color(SeriesLook look, ForgePalette p) => switch (look) {
  SeriesLook.accent => p.accent,
  SeriesLook.info => p.info,
  SeriesLook.success => p.success,
};

Path _stroke(Path path, SeriesLook? look) => switch (look) {
  SeriesLook.info => dashed(path, 6, 3),
  SeriesLook.success => dashed(path, 1, 4),
  _ => path,
};

Paint _linePaint(Color color) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// Up to three [series] on one chart in a card, each on its own scale,
/// across the days [from] to [to]. The chosen series sit as chips above it
/// with a sample of their line, and an Add chip after them opens the app's
/// list of more. A tap on the chart shows every series' value on the
/// nearest day with an entry. Under the chart: the legend of an averaged
/// series, a [range] control (a SegmentedControl), a muted [caption] and a
/// [lockedCaption] with a lock and a chevron that the app opens.
/// [MultiSeriesChart.shared] puts its series on one scale under a legend.
class MultiSeriesChart extends StatelessWidget {
  const MultiSeriesChart({
    super.key,
    required this.title,
    this.detail,
    required List<ChartSeries> this.series,
    required DateTime this.from,
    required DateTime this.to,
    required String Function(DateTime day) this.dateLabel,
    required String this.startLabel,
    required String this.endLabel,
    required void Function(int index) this.onSeriesTap,
    required String this.addLabel,
    required VoidCallback this.onAdd,
    this.adding = false,
    this.range,
    this.caption,
    this.lockedCaption,
    this.onLockedCaptionTap,
    required String this.semanticLabel,
  }) : assert(series.length <= 3),
       assert((lockedCaption == null) == (onLockedCaptionTap == null)),
       _state = _State.filled,
       gridlines = null,
       _messageTitle = null,
       message = null,
       actions = const [],
       onRetry = null,
       retryLabel = null;

  /// Up to three plain [series] on one value scale, named in a legend
  /// above the chart with a sample of each line, with no dot at their
  /// ends. Each of the [gridlines] is a thin line across the chart with its
  /// label centred on it in a column to the left; the scale spans them and
  /// every point. The end labels sit under the chart's ends. A tap shows
  /// every series' value on the nearest day with an entry.
  const MultiSeriesChart.shared({
    super.key,
    required this.title,
    this.detail,
    required List<ChartSeries> this.series,
    required List<({double value, String label})> this.gridlines,
    required DateTime this.from,
    required DateTime this.to,
    required String Function(DateTime day) this.dateLabel,
    required String this.startLabel,
    required String this.endLabel,
    required String this.semanticLabel,
  }) : assert(series.length <= 3),
       _state = _State.shared,
       onSeriesTap = null,
       addLabel = null,
       onAdd = null,
       adding = false,
       range = null,
       caption = null,
       lockedCaption = null,
       onLockedCaptionTap = null,
       _messageTitle = null,
       message = null,
       actions = const [],
       onRetry = null,
       retryLabel = null;

  /// Shimmering chips and chart.
  const MultiSeriesChart.loading({super.key, required this.title, this.detail})
    : _state = _State.loading,
      series = null,
      from = null,
      to = null,
      dateLabel = null,
      startLabel = null,
      endLabel = null,
      onSeriesTap = null,
      addLabel = null,
      onAdd = null,
      adding = false,
      range = null,
      caption = null,
      lockedCaption = null,
      onLockedCaptionTap = null,
      semanticLabel = null,
      gridlines = null,
      _messageTitle = null,
      message = null,
      actions = const [],
      onRetry = null,
      retryLabel = null;

  /// Nothing to chart yet: [emptyTitle], a [message] and up to two
  /// [actions] (Buttons). Nothing in the chosen range keeps the [range]
  /// control and the [lockedCaption] under them, as the filled form.
  const MultiSeriesChart.empty({
    super.key,
    required this.title,
    this.detail,
    required String emptyTitle,
    required String this.message,
    this.actions = const [],
    this.range,
    this.lockedCaption,
    this.onLockedCaptionTap,
  }) : assert((lockedCaption == null) == (onLockedCaptionTap == null)),
       _state = _State.empty,
       _messageTitle = emptyTitle,
       series = null,
       from = null,
       to = null,
       dateLabel = null,
       startLabel = null,
       endLabel = null,
       onSeriesTap = null,
       addLabel = null,
       onAdd = null,
       adding = false,
       caption = null,
       semanticLabel = null,
       gridlines = null,
       onRetry = null,
       retryLabel = null;

  /// Loading failed: [errorTitle] over a [message] and an outline Retry.
  const MultiSeriesChart.error({
    super.key,
    required this.title,
    this.detail,
    required String errorTitle,
    required String this.message,
    required VoidCallback this.onRetry,
    required String this.retryLabel,
  }) : _state = _State.error,
       _messageTitle = errorTitle,
       series = null,
       from = null,
       to = null,
       dateLabel = null,
       startLabel = null,
       endLabel = null,
       onSeriesTap = null,
       addLabel = null,
       onAdd = null,
       adding = false,
       range = null,
       caption = null,
       lockedCaption = null,
       onLockedCaptionTap = null,
       semanticLabel = null,
       gridlines = null,
       actions = const [];

  final String title;
  final String? detail;
  final List<ChartSeries>? series;

  /// The first and last day the chart spans.
  final DateTime? from;
  final DateTime? to;

  /// A day, for the tap tag.
  final String Function(DateTime day)? dateLabel;
  final String? startLabel;
  final String? endLabel;

  /// A series chip was tapped.
  final void Function(int index)? onSeriesTap;
  final String? addLabel;
  final VoidCallback? onAdd;

  /// The list of more series is open: the Add chip shows chosen.
  final bool adding;

  /// The range control under the chart.
  final Widget? range;

  /// A muted line under the chart.
  final String? caption;

  /// A muted line with a lock and a chevron, such as older results behind
  /// a paywall; [onLockedCaptionTap] opens it.
  final String? lockedCaption;
  final VoidCallback? onLockedCaptionTap;

  /// What the chart shows, for screen readers.
  final String? semanticLabel;

  /// The shared scale's lines, each a value and its label.
  final List<({double value, String label})>? gridlines;
  final String? _messageTitle;
  final String? message;
  final List<Widget> actions;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final _State _state;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final children = switch (_state) {
      _State.filled => _filled(context, style),
      _State.shared => _shared(context),
      _State.loading => [
        const Wrap(
          spacing: Gap.sm,
          children: [
            SkeletonBar(
              width: 84,
              height: ForgeChip.seriesHeight,
              radius: ForgeRadii.button,
            ),
            SkeletonBar(
              width: 84,
              height: ForgeChip.seriesHeight,
              radius: ForgeRadii.button,
            ),
            SkeletonBar(
              width: 60,
              height: ForgeChip.seriesHeight,
              radius: ForgeRadii.button,
            ),
          ],
        ),
        SkeletonBar(
          widthFactor: 1,
          height: _Plot.height,
          radius: style.radii.sm,
        ),
        const ChartEndSkeletons(width: 44),
      ],
      _State.empty => [
        EmptyView(
          icon: ForgeIcons.showChart,
          title: _messageTitle!,
          message: message!,
          actions: actions,
          compact: true,
        ),
        ?range,
        if (lockedCaption != null)
          _LockedCaption(text: lockedCaption!, onTap: onLockedCaptionTap!),
      ],
      _State.error => [
        ErrorView(
          title: _messageTitle!,
          message: message!,
          onRetry: onRetry!,
          retryLabel: retryLabel!,
          compact: true,
        ),
      ],
    };
    return CardFrame(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Gap.sm,
          children: [
            ChartTitleRow(title: title, detail: detail),
            ...children,
          ],
        ),
      ),
    );
  }

  List<Widget> _filled(BuildContext context, ForgeStyle style) {
    final series = this.series!;
    final averaged = series.where((s) => s.average != null).toList();
    assert(averaged.length <= 1);
    final muted = Theme.of(context).textTheme.labelSmall!
        .copyWith(color: style.colors.inkMuted, fontWeight: FontWeight.w400);
    return [
      Wrap(
        spacing: Gap.sm,
        children: [
          for (final (i, s) in series.indexed)
            ForgeChip.series(
              label: s.label,
              sample: SeriesSample(s.look, bars: s.bars),
              selected: true,
              onPressed: () => onSeriesTap!(i),
            ),
          ForgeChip.series(
            label: addLabel!,
            sample: const ForgeIcon(ForgeIcons.add, size: 14),
            selected: adding,
            onPressed: onAdd!,
          ),
        ],
      ),
      for (final s in series)
        if (s.error case final error?)
          ErrorLine(
            message: error,
            retryLabel: s.retryLabel!,
            onRetry: s.onRetry!,
          ),
      _Plot(
        series: [
          for (final s in series)
            if (s.error == null) s,
        ],
        gridlines: null,
        from: from!,
        to: to!,
        dateLabel: dateLabel!,
        semanticLabel: semanticLabel!,
      ),
      ChartEndLabels(start: startLabel!, end: endLabel!, size: 11),
      for (final s in averaged) _Legend(series: s, style: muted),
      ?range,
      if (caption != null) Text(caption!, style: muted),
      if (lockedCaption != null)
        _LockedCaption(text: lockedCaption!, onTap: onLockedCaptionTap!),
    ];
  }

  List<Widget> _shared(BuildContext context) {
    final series = this.series!;
    assert(
      series.every(
        (s) =>
            !s.bars && s.average == null && s.target == null && s.error == null,
      ),
    );
    return [
      Wrap(
        spacing: _legendGap,
        runSpacing: Gap.xs,
        children: [
          for (final s in series)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: Gap.xs,
              children: [
                SeriesSample(s.look),
                Text(
                  s.label,
                  style: Theme.of(context).textTheme.labelMedium!
                      .copyWith(color: ForgeStyle.of(context).colors.inkMuted),
                ),
              ],
            ),
        ],
      ),
      _Plot(
        series: series,
        gridlines: gridlines,
        from: from!,
        to: to!,
        dateLabel: dateLabel!,
        semanticLabel: semanticLabel!,
      ),
      Padding(
        padding: const EdgeInsets.only(left: _Plot.labelColumn),
        child: ChartEndLabels(start: startLabel!, end: endLabel!, size: 11),
      ),
    ];
  }

  /// The space between the shared form's legend items.
  static const double _legendGap = 18;
}

enum _State { filled, shared, loading, empty, error }

/// The legend of an averaged series: a thin line-strong sample for the
/// daily points and a thick one in the series' colour for the average.
class _Legend extends StatelessWidget {
  const _Legend({required this.series, required this.style});

  final ChartSeries series;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final p = ForgeStyle.of(context).colors;
    Widget item(Color color, double height, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Gap.xs,
      children: [
        SizedBox(
          width: 14,
          height: height,
          child: ColoredBox(color: color),
        ),
        Text(label, style: style),
      ],
    );
    return Wrap(
      spacing: 12,
      runSpacing: Gap.xs,
      children: [
        item(p.lineStrong, 2, series.dailyLabel!),
        item(_color(series.look, p), 3, series.averageLabel!),
      ],
    );
  }
}

/// A muted line between a lock and a chevron; the whole line is the tap
/// target.
class _LockedCaption extends StatelessWidget {
  const _LockedCaption({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = ForgeStyle.of(context).colors.inkMuted;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: ForgeTheme.tapMin),
          child: Row(
            spacing: 6,
            children: [
              ForgeIcon(ForgeIcons.lock, size: 14, color: muted),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.labelMedium!
                      .copyWith(color: muted, fontWeight: FontWeight.w400),
                ),
              ),
              ForgeIcon(ForgeIcons.chevronRight, size: 16, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// A day as a whole number of days after [from], free of daylight saving.
int _dayOf(DateTime day, DateTime from) => DateTime.utc(
  day.year,
  day.month,
  day.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

class _Plot extends StatefulWidget {
  const _Plot({
    required this.series,
    required this.gridlines,
    required this.from,
    required this.to,
    required this.dateLabel,
    required this.semanticLabel,
  });

  final List<ChartSeries> series;

  /// Lines of one scale shared by every series; each has its own without.
  final List<({double value, String label})>? gridlines;
  final DateTime from;
  final DateTime to;
  final String Function(DateTime day) dateLabel;
  final String semanticLabel;

  static const double height = 150;

  /// The line under the chart.
  static const double baseline = 126;

  /// Where each line's own range runs, top to bottom.
  static const double lineTop = 16;
  static const double lineBottom = 108;

  /// The top of the tallest bar.
  static const double barTop = 30;

  /// The share of its week a bar is wide.
  static const double barShare = 0.52;

  /// The width of the gridline labels' column left of a shared scale.
  static const double labelColumn = 40;

  @override
  State<_Plot> createState() => _PlotState();
}

class _PlotState extends State<_Plot> {
  /// The tapped day, in days after `from`.
  int? _selected;

  int get _days => _dayOf(widget.to, widget.from) + 1;

  /// Every day with an entry, in order.
  List<int> get _entryDays => {
    for (final s in widget.series)
      for (final p in s.points) _dayOf(p.day, widget.from),
  }.toList()..sort();

  @override
  void didUpdateWidget(_Plot old) {
    super.didUpdateWidget(old);
    if (!_entryDays.contains(_selected)) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final p = style.colors;
    final shared = _sharedScale();
    final scales = [for (final s in widget.series) shared ?? _scale(s)];
    final gridlines = [
      for (final g in widget.gridlines ?? const <Never>[])
        (g, shared!(g.value)),
    ];
    final plot = SizedBox(
      height: _Plot.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final dayWidth = width / _days;
          // A day's centre.
          double x(int day) => dayWidth * (day + 0.5);
          final entryDays = _entryDays;
          final selected = _selected;
          final targets = [
            for (final (i, s) in widget.series.indexed)
              if (s.target != null) (s, scales[i](s.target!)),
          ];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: entryDays.isEmpty
                ? null
                : (details) => setState(
                    () => _selected =
                        entryDays[nearest([
                          for (final d in entryDays) x(d),
                        ], details.localPosition.dx)],
                  ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PlotPainter(
                      series: widget.series,
                      from: widget.from,
                      dayWidth: dayWidth,
                      scales: scales,
                      gridlines: [for (final (_, y) in gridlines) y],
                      endDots: shared == null,
                      selected: selected,
                      colors: p,
                    ),
                  ),
                ),
                for (final (s, y) in targets)
                  Positioned(
                    right: 0,
                    top: y - 18,
                    child: Container(
                      color: p.surface,
                      padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
                      child: Text(
                        s.targetLabel!,
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _color(s.look, p),
                        ),
                      ),
                    ),
                  ),
                if (selected != null)
                  Positioned.fill(
                    child: CustomSingleChildLayout(
                      delegate: _TagLayout(x(selected)),
                      child: _Tag(
                        date: widget.dateLabel(
                          DateTime(
                            widget.from.year,
                            widget.from.month,
                            widget.from.day + selected,
                          ),
                        ),
                        rows: [
                          for (final s in widget.series)
                            for (final point in s.points)
                              if (_dayOf(point.day, widget.from) == selected)
                                (
                                  s,
                                  s.formatPoint?.call(point) ??
                                      s.format(point.value),
                                ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
    final label = style.data.copyWith(fontSize: 12, color: p.inkMuted);
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: shared == null
          ? plot
          : Row(
              children: [
                SizedBox(
                  width: _Plot.labelColumn,
                  height: _Plot.height,
                  // The chart's label tells screen readers what it shows.
                  child: ExcludeSemantics(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final (g, y) in gridlines)
                          Positioned(
                            left: 0,
                            top: y,
                            // Centred on its line.
                            child: FractionalTranslation(
                              translation: const Offset(0, -0.5),
                              child: Text(g.label, style: label),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: plot),
              ],
            ),
    );
  }

  /// The scale every series shares, from the lowest of the gridlines and
  /// points on the baseline to the highest; none without gridlines.
  double Function(double)? _sharedScale() {
    final gridlines = widget.gridlines;
    if (gridlines == null) return null;
    final all = [
      for (final g in gridlines) g.value,
      for (final s in widget.series)
        for (final p in s.points) p.value,
    ];
    if (all.isEmpty) return (_) => _Plot.baseline;
    final min = all.reduce(math.min);
    final max = all.reduce(math.max);
    return (v) => scaleY(v, min, max, _Plot.lineTop, _Plot.baseline);
  }

  /// A series' own scale: lines across their range, bars up from zero.
  double Function(double) _scale(ChartSeries s) {
    if (s.bars) {
      final max = s.points.fold(0.0, (m, p) => math.max(m, p.value));
      return (v) => scaleY(v, 0, max, _Plot.barTop, _Plot.baseline);
    }
    final all = [
      for (final p in s.points) p.value,
      for (final p in s.average ?? const <ChartPoint>[]) p.value,
      ?s.target,
    ];
    // A line with nothing to draw yet.
    if (all.isEmpty) return (_) => _Plot.lineBottom;
    final min = all.reduce(math.min);
    final max = all.reduce(math.max);
    return (v) => scaleY(v, min, max, _Plot.lineTop, _Plot.lineBottom);
  }
}

class _PlotPainter extends CustomPainter {
  const _PlotPainter({
    required this.series,
    required this.from,
    required this.dayWidth,
    required this.scales,
    required this.gridlines,
    required this.endDots,
    required this.selected,
    required this.colors,
  });

  final List<ChartSeries> series;
  final DateTime from;
  final double dayWidth;
  final List<double Function(double)> scales;

  /// The gridlines' heights.
  final List<double> gridlines;

  /// A dot on each line's last point.
  final bool endDots;
  final int? selected;
  final ForgePalette colors;

  static const double _endDot = 3;
  static const double _ring = 4.5;
  static const double _averageWidth = 2.5;

  double _x(DateTime day) => dayWidth * (_dayOf(day, from) + 0.5);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = colors.line;
    for (final y in [...gridlines, _Plot.baseline]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (final (i, s) in series.indexed) {
      if (!s.bars) continue;
      final paint = Paint()..color = colors.info.withValues(alpha: 0.4);
      final width = dayWidth * 7 * _Plot.barShare;
      for (final p in s.points) {
        final centre = _x(p.day) + dayWidth * 3;
        canvas.drawRRect(
          RRect.fromLTRBR(
            centre - width / 2,
            scales[i](p.value),
            centre + width / 2,
            _Plot.baseline,
            const Radius.circular(2),
          ),
          paint,
        );
      }
    }
    List<Offset> line(List<ChartPoint> points, int i) => [
      for (final p in [...points]..sort((a, b) => a.day.compareTo(b.day)))
        Offset(_x(p.day), scales[i](p.value)),
    ];
    for (final (i, s) in series.indexed) {
      if (s.bars || s.points.isEmpty) continue;
      final color = _color(s.look, colors);
      final daily = line(s.points, i);
      final average = s.average;
      final List<Offset> main;
      if (average == null) {
        main = daily;
        canvas.drawPath(
          _stroke(Path()..addPolygon(daily, false), s.look),
          _linePaint(color),
        );
      } else {
        canvas.drawPath(
          Path()..addPolygon(daily, false),
          _linePaint(colors.lineStrong)..strokeWidth = 1,
        );
        main = line(average, i);
        canvas.drawPath(
          _stroke(Path()..addPolygon(main, false), s.look),
          _linePaint(color)..strokeWidth = _averageWidth,
        );
      }
      if (endDots && this.selected == null && main.isNotEmpty) {
        canvas.drawCircle(main.last, _endDot, Paint()..color = color);
      }
      final target = s.target;
      if (target != null) {
        final y = scales[i](target);
        canvas.drawPath(
          dashed(
            Path()
              ..moveTo(0, y)
              ..lineTo(size.width, y),
            4,
            3,
          ),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
    final selected = this.selected;
    if (selected == null) return;
    final x = dayWidth * (selected + 0.5);
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, _Plot.baseline),
      Paint()..color = colors.lineStrong,
    );
    for (final (i, s) in series.indexed) {
      if (s.bars) continue;
      for (final p in s.points) {
        if (_dayOf(p.day, from) != selected) continue;
        final at = Offset(x, scales[i](p.value));
        canvas.drawCircle(at, _ring, Paint()..color = colors.surface);
        canvas.drawCircle(
          at,
          _ring,
          Paint()
            ..color = _color(s.look, colors)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PlotPainter old) => true;
}

/// Centres the tag on the tapped day near the chart's top, inside its
/// width.
class _TagLayout extends SingleChildLayoutDelegate {
  const _TagLayout(this.x);

  final double x;

  static const double _top = 6;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) => Offset(
    (x - child.width / 2)
        .clamp(0.0, math.max(0.0, size.width - child.width))
        .toDouble(),
    _top,
  );

  @override
  bool shouldRelayout(_TagLayout old) => old.x != x;
}

class _Tag extends StatelessWidget {
  const _Tag({required this.date, required this.rows});

  final String date;
  final List<(ChartSeries, String)> rows;

  static const double _minWidth = 140;
  static const double _sampleWidth = 14;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final p = style.colors;
    final text = style.data.copyWith(fontSize: 11, color: p.surface);
    return Container(
      constraints: const BoxConstraints(minWidth: _minWidth),
      padding: const EdgeInsets.all(Gap.sm),
      decoration: BoxDecoration(
        color: p.ink,
        borderRadius: const BorderRadius.all(
          Radius.circular(ForgeRadii.button),
        ),
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Gap.xs,
          children: [
            Text(
              date,
              style: text.copyWith(color: p.surface.withValues(alpha: 0.7)),
            ),
            for (final (s, value) in rows)
              Row(
                spacing: Gap.sm,
                children: [
                  SizedBox(
                    width: _sampleWidth,
                    height: s.bars ? 10 : 6,
                    child: CustomPaint(
                      painter: _SamplePainter(
                        look: s.look,
                        bars: s.bars,
                        color: _color(s.look, p),
                      ),
                    ),
                  ),
                  Expanded(child: Text(s.label, style: text)),
                  Text(value, style: text),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
