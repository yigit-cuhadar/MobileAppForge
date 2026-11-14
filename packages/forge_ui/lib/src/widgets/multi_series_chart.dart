import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_palette.dart';
import '../theme/forge_preset.dart';
import '../theme/forge_style.dart';
import 'card_frame.dart';
import 'chart_paint.dart';
import 'pressable.dart';
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

/// One series of a [MultiSeriesChart]: a value per day, written by
/// [format]. A [target] is a thin dashed line in the series' colour with
/// its [targetLabel] at the right end.
class ChartSeries {
  const ChartSeries({
    required this.label,
    required this.values,
    required this.format,
    required this.look,
    this.target,
    this.targetLabel,
  }) : bars = false,
       assert((target == null) == (targetLabel == null));

  /// A weekly series: info bars at 40% behind the lines.
  const ChartSeries.bars({
    required this.label,
    required this.values,
    required this.format,
  }) : look = SeriesLook.info,
       bars = true,
       target = null,
       targetLabel = null;

  final String label;
  final List<double> values;
  final String Function(double value) format;
  final SeriesLook look;
  final bool bars;
  final double? target;
  final String? targetLabel;
}

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

/// Up to three [series] on one chart in a card, each on its own scale. The
/// chosen series sit as chips above it with a sample of their line, and an
/// Add chip after them opens the app's list of more. A tap on the chart
/// shows every series' value on that day.
class MultiSeriesChart extends StatelessWidget {
  const MultiSeriesChart({
    super.key,
    required this.title,
    this.detail,
    required List<ChartSeries> this.series,
    required String Function(int index) this.dateLabel,
    required String this.startLabel,
    required String this.endLabel,
    required void Function(int index) this.onSeriesTap,
    required String this.addLabel,
    required VoidCallback this.onAdd,
    this.adding = false,
    this.caption,
    required String this.semanticLabel,
  }) : assert(series.length <= 3),
       _state = _State.filled,
       _messageTitle = null,
       message = null,
       actions = const [],
       onRetry = null,
       retryLabel = null;

  /// Shimmering chips and chart.
  const MultiSeriesChart.loading({super.key, required this.title, this.detail})
    : _state = _State.loading,
      series = null,
      dateLabel = null,
      startLabel = null,
      endLabel = null,
      onSeriesTap = null,
      addLabel = null,
      onAdd = null,
      adding = false,
      caption = null,
      semanticLabel = null,
      _messageTitle = null,
      message = null,
      actions = const [],
      onRetry = null,
      retryLabel = null;

  /// Nothing to chart yet: [emptyTitle], a [message] and up to two
  /// [actions] (Buttons).
  const MultiSeriesChart.empty({
    super.key,
    required this.title,
    this.detail,
    required String emptyTitle,
    required String this.message,
    this.actions = const [],
  }) : _state = _State.empty,
       _messageTitle = emptyTitle,
       series = null,
       dateLabel = null,
       startLabel = null,
       endLabel = null,
       onSeriesTap = null,
       addLabel = null,
       onAdd = null,
       adding = false,
       caption = null,
       semanticLabel = null,
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
    String this.retryLabel = 'Retry',
  }) : _state = _State.error,
       _messageTitle = errorTitle,
       series = null,
       dateLabel = null,
       startLabel = null,
       endLabel = null,
       onSeriesTap = null,
       addLabel = null,
       onAdd = null,
       adding = false,
       caption = null,
       semanticLabel = null,
       actions = const [];

  final String title;
  final String? detail;
  final List<ChartSeries>? series;

  /// The day of an index, for the tap tag.
  final String Function(int index)? dateLabel;
  final String? startLabel;
  final String? endLabel;

  /// A series chip was tapped.
  final void Function(int index)? onSeriesTap;
  final String? addLabel;
  final VoidCallback? onAdd;

  /// The list of more series is open: the Add chip shows chosen.
  final bool adding;

  /// A muted line under the chart.
  final String? caption;

  /// What the chart shows, for screen readers.
  final String? semanticLabel;
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
      _State.filled => [
        Wrap(
          spacing: Gap.sm,
          children: [
            for (final (i, s) in series!.indexed)
              _SeriesChip(
                label: s.label,
                sample: SeriesSample(s.look, bars: s.bars),
                chosen: true,
                onTap: () => onSeriesTap!(i),
              ),
            _SeriesChip(
              label: addLabel!,
              sample: const ForgeIcon(ForgeIcons.add, size: 14),
              chosen: adding,
              onTap: onAdd!,
            ),
          ],
        ),
        _Plot(
          series: series!,
          dateLabel: dateLabel!,
          semanticLabel: semanticLabel!,
        ),
        ChartEndLabels(start: startLabel!, end: endLabel!, size: 11),
        if (caption != null)
          Text(
            caption!,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: style.colors.inkMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
      ],
      _State.loading => [
        const Wrap(
          spacing: Gap.sm,
          children: [
            SkeletonBar(width: 84, height: 28, radius: ForgeRadii.button),
            SkeletonBar(width: 84, height: 28, radius: ForgeRadii.button),
            SkeletonBar(width: 60, height: 28, radius: ForgeRadii.button),
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
    final empty = _state == _State.empty;
    return CardFrame(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: empty ? Gap.md : Gap.sm,
          children: [
            ChartTitleRow(
              title: title,
              detail: detail,
              detailSize: empty ? 12 : 11,
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

enum _State { filled, loading, empty, error }

class _SeriesChip extends StatelessWidget {
  const _SeriesChip({
    required this.label,
    required this.sample,
    required this.chosen,
    required this.onTap,
  });

  final String label;
  final Widget sample;
  final bool chosen;
  final VoidCallback onTap;

  static const double height = 28;

  @override
  Widget build(BuildContext context) {
    final p = ForgeStyle.of(context).colors;
    final ink = chosen ? p.onAccentSoft : p.inkMuted;
    return Semantics(
      button: true,
      selected: chosen,
      child: Pressable(
        onTap: onTap,
        height: height,
        builder: (context, _) => Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
          decoration: BoxDecoration(
            color: chosen ? p.accentSoft : p.surface,
            borderRadius: const BorderRadius.all(
              Radius.circular(ForgeRadii.button),
            ),
            border: chosen
                ? Border.all(color: p.accent, width: 1.5)
                : Border.all(color: p.lineStrong),
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: ink),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: Gap.sm,
              children: [
                sample,
                Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelMedium!
                      .copyWith(color: ink, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Plot extends StatefulWidget {
  const _Plot({
    required this.series,
    required this.dateLabel,
    required this.semanticLabel,
  });

  final List<ChartSeries> series;
  final String Function(int index) dateLabel;
  final String semanticLabel;

  static const double height = 150;

  /// The line under the chart.
  static const double baseline = 126;

  /// Where each line's own range runs, top to bottom.
  static const double lineTop = 16;
  static const double lineBottom = 108;

  /// The top of the tallest bar.
  static const double barTop = 30;

  /// Room at the sides when there are no bars.
  static const double side = 6;

  /// The share of its day a bar is wide.
  static const double barShare = 0.52;

  @override
  State<_Plot> createState() => _PlotState();
}

class _PlotState extends State<_Plot> {
  int? _selected;

  int get _count =>
      widget.series.fold(0, (n, s) => math.max(n, s.values.length));

  @override
  void didUpdateWidget(_Plot old) {
    super.didUpdateWidget(old);
    if (_selected != null && _selected! >= _count) _selected = null;
  }

  List<double> _xs(double width) {
    final count = _count;
    if (widget.series.any((s) => s.bars)) {
      final slot = width / count;
      return [for (var i = 0; i < count; i++) slot * (i + 0.5)];
    }
    return spreadX(count, _Plot.side, width - _Plot.side);
  }

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final p = style.colors;
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: SizedBox(
        height: _Plot.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final xs = _xs(width);
            final selected = _selected;
            final targets = [
              for (final s in widget.series)
                if (s.target != null) (s, _scale(s).call(s.target!)),
            ];
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: xs.isEmpty
                  ? null
                  : (details) => setState(
                      () => _selected = nearest(xs, details.localPosition.dx),
                    ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PlotPainter(
                        series: widget.series,
                        xs: xs,
                        scales: [for (final s in widget.series) _scale(s)],
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
                          style: Theme.of(context).textTheme.labelSmall!
                              .copyWith(
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
                        delegate: _TagLayout(xs[selected]),
                        child: _Tag(
                          date: widget.dateLabel(selected),
                          rows: [
                            for (final s in widget.series)
                              if (selected < s.values.length)
                                (s, s.format(s.values[selected])),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// A series' own scale: lines across their range, bars up from zero.
  double Function(double) _scale(ChartSeries s) {
    if (s.bars) {
      final max = s.values.fold(0.0, math.max);
      return (v) => scaleY(v, 0, max, _Plot.barTop, _Plot.baseline);
    }
    final all = [...s.values, ?s.target];
    final min = all.reduce(math.min);
    final max = all.reduce(math.max);
    return (v) => scaleY(v, min, max, _Plot.lineTop, _Plot.lineBottom);
  }
}

class _PlotPainter extends CustomPainter {
  const _PlotPainter({
    required this.series,
    required this.xs,
    required this.scales,
    required this.selected,
    required this.colors,
  });

  final List<ChartSeries> series;
  final List<double> xs;
  final List<double Function(double)> scales;
  final int? selected;
  final ForgePalette colors;

  static const double _endDot = 3;
  static const double _ring = 4.5;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      const Offset(0, _Plot.baseline),
      Offset(size.width, _Plot.baseline),
      Paint()..color = colors.line,
    );
    final slot = xs.isEmpty ? 0.0 : size.width / xs.length;
    for (final (i, s) in series.indexed) {
      if (!s.bars) continue;
      final paint = Paint()..color = colors.info.withValues(alpha: 0.4);
      final width = slot * _Plot.barShare;
      for (final (j, v) in s.values.indexed) {
        canvas.drawRRect(
          RRect.fromLTRBR(
            xs[j] - width / 2,
            scales[i](v),
            xs[j] + width / 2,
            _Plot.baseline,
            const Radius.circular(2),
          ),
          paint,
        );
      }
    }
    for (final (i, s) in series.indexed) {
      if (s.bars || s.values.isEmpty) continue;
      final color = _color(s.look, colors);
      final points = [
        for (final (j, v) in s.values.indexed) Offset(xs[j], scales[i](v)),
      ];
      canvas.drawPath(
        _stroke(Path()..addPolygon(points, false), s.look),
        _linePaint(color),
      );
      if (this.selected == null) {
        canvas.drawCircle(points.last, _endDot, Paint()..color = color);
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
    final x = xs[selected];
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, _Plot.baseline),
      Paint()..color = colors.lineStrong,
    );
    for (final (i, s) in series.indexed) {
      if (s.bars || selected >= s.values.length) continue;
      final at = Offset(x, scales[i](s.values[selected]));
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
