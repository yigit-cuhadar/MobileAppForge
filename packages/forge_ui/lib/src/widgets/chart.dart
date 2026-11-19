import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import 'card_frame.dart';
import 'chart_paint.dart';
import 'skeleton.dart';
import 'state_views.dart';

/// One bar of [Chart.bar]: its [label] under it and, once it has a
/// [value], the [valueLabel] above it (none for a bar not worth a figure,
/// such as zero). A bar with no value yet is a short stub. Held, a bar
/// shows its [tooltip] ("5,739 steps · Mon, Nov 3"), or else its
/// [valueLabel], in a dark tag; screen readers read it per bar.
class ChartBar {
  const ChartBar({
    required this.label,
    this.value,
    this.valueLabel,
    this.tooltip,
  }) : assert(value != null || (valueLabel == null && tooltip == null));

  final String label;
  final double? value;
  final String? valueLabel;
  final String? tooltip;

  String? get _tag => tooltip ?? valueLabel;

  String get _spoken =>
      tooltip ?? [label, ?valueLabel].where((s) => s.isNotEmpty).join(', ');
}

/// A chart in a card under its [title] and [detail]: a line with a dot per
/// point, or bars with their values. A goal is a dashed success line.
/// Pressing and holding a bar darkens it, fades the others and shows its
/// [ChartBar.tooltip] in a dark tag above it; dragging moves the tag from
/// bar to bar, and letting go hides it. A tap on a bar shows the same until
/// a tap on it again or anywhere else.
class Chart extends StatelessWidget {
  /// A 2px accent line with a dot per point, no grid, [startLabel] and
  /// [endLabel] under its ends. A tap rings the nearest point and shows its
  /// [pointLabel] in a dark tag above it.
  const Chart.line({
    super.key,
    required this.title,
    this.detail,
    required List<double> this.values,
    required String Function(int index) this.pointLabel,
    this.target,
    required String this.startLabel,
    required String this.endLabel,
    required String this.semanticLabel,
  }) : _state = _State.line,
       band = null,
       card = true,
       smallLabels = false,
       bars = null,
       current = null,
       _messageTitle = null,
       message = null,
       actions = const [],
       onRetry = null,
       retryLabel = null;

  /// Bars with their value above and their label under them; the
  /// [current] bar (today) in accent, the others in accent at 55%. A
  /// [band] (such as 10–20) is a sunken stripe behind the bars, and each
  /// bar then takes the BandBar colours: a soft accent below the band,
  /// accent within it, danger above it. Without its [card] the chart sits
  /// on the page or sheet under its title. [smallLabels] sets the labels
  /// at 9px on one line, centred under their bar and free to run past it;
  /// give the bars between labelled ones an empty label.
  const Chart.bar({
    super.key,
    required this.title,
    this.detail,
    required List<ChartBar> this.bars,
    this.current,
    this.target,
    this.band,
    this.card = true,
    this.smallLabels = false,
    required String this.semanticLabel,
  }) : _state = _State.bar,
       values = null,
       pointLabel = null,
       startLabel = null,
       endLabel = null,
       _messageTitle = null,
       message = null,
       actions = const [],
       onRetry = null,
       retryLabel = null;

  /// Many bars (such as 30 days) 2px apart, with no values above them: the
  /// first and last bar's [ChartBar.label] sit under the ends. The
  /// [current] bar and a [target] as in [Chart.bar].
  const Chart.barDense({
    super.key,
    required this.title,
    this.detail,
    required List<ChartBar> this.bars,
    this.current,
    this.target,
    required String this.semanticLabel,
  }) : _state = _State.barDense,
       band = null,
       card = true,
       smallLabels = false,
       values = null,
       pointLabel = null,
       startLabel = null,
       endLabel = null,
       _messageTitle = null,
       message = null,
       actions = const [],
       onRetry = null,
       retryLabel = null;

  /// The title row stays; the chart and its end labels shimmer.
  const Chart.loading({super.key, required this.title, this.detail})
    : _state = _State.loading,
      band = null,
      card = true,
      smallLabels = false,
      values = null,
      pointLabel = null,
      startLabel = null,
      endLabel = null,
      semanticLabel = null,
      bars = null,
      current = null,
      target = null,
      _messageTitle = null,
      message = null,
      actions = const [],
      onRetry = null,
      retryLabel = null;

  /// No data yet: [emptyTitle], a [message] and up to two [actions]
  /// (Buttons) in place of the chart.
  const Chart.empty({
    super.key,
    required this.title,
    this.detail,
    required String emptyTitle,
    required String this.message,
    this.actions = const [],
  }) : _state = _State.empty,
       band = null,
       card = true,
       smallLabels = false,
       _messageTitle = emptyTitle,
       values = null,
       pointLabel = null,
       startLabel = null,
       endLabel = null,
       semanticLabel = null,
       bars = null,
       current = null,
       target = null,
       onRetry = null,
       retryLabel = null;

  /// Loading failed: [errorTitle] over a [message] and an outline Retry
  /// in place of the chart.
  const Chart.error({
    super.key,
    required this.title,
    this.detail,
    required String errorTitle,
    required String this.message,
    required VoidCallback this.onRetry,
    required String this.retryLabel,
  }) : _state = _State.error,
       band = null,
       card = true,
       smallLabels = false,
       _messageTitle = errorTitle,
       values = null,
       pointLabel = null,
       startLabel = null,
       endLabel = null,
       semanticLabel = null,
       bars = null,
       current = null,
       target = null,
       actions = const [];

  final String title;
  final String? detail;
  final List<double>? values;
  final String Function(int index)? pointLabel;

  /// The goal, on the values' scale.
  final double? target;
  final String? startLabel;
  final String? endLabel;

  /// What the chart shows, for screen readers.
  final String? semanticLabel;
  final List<ChartBar>? bars;
  final int? current;

  /// The values a bar should land between.
  final ({double low, double high})? band;
  final bool card;
  final bool smallLabels;
  final String? _messageTitle;
  final String? message;
  final List<Widget> actions;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final _State _state;

  @override
  Widget build(BuildContext context) {
    final children = switch (_state) {
      _State.line => [
        _LineChart(
          values: values!,
          pointLabel: pointLabel!,
          target: target,
          semanticLabel: semanticLabel!,
        ),
        ChartEndLabels(start: startLabel!, end: endLabel!, size: 10),
      ],
      _State.bar => [
        _BarChart(
          bars: bars!,
          current: current,
          target: target,
          band: band,
          smallLabels: smallLabels,
          semanticLabel: semanticLabel!,
        ),
      ],
      _State.barDense => [
        _DenseBarChart(
          bars: bars!,
          current: current,
          target: target,
          semanticLabel: semanticLabel!,
        ),
        if (bars!.isNotEmpty)
          ChartEndLabels(
            start: bars!.first.label,
            end: bars!.last.label,
            size: 10,
          ),
      ],
      _State.loading => [
        SkeletonBar(
          widthFactor: 1,
          height: 120,
          radius: ForgeStyle.of(context).radii.sm,
        ),
        const ChartEndSkeletons(width: 60),
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
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Gap.sm,
      children: [
        ChartTitleRow(title: title, detail: detail),
        ...children,
      ],
    );
    if (!card) return column;
    return CardFrame(
      child: Padding(padding: const EdgeInsets.all(Gap.md), child: column),
    );
  }
}

enum _State { line, bar, barDense, loading, empty, error }

class _LineChart extends StatefulWidget {
  const _LineChart({
    required this.values,
    required this.pointLabel,
    required this.target,
    required this.semanticLabel,
  });

  final List<double> values;
  final String Function(int index) pointLabel;
  final double? target;
  final String semanticLabel;

  static const height = 150.0;

  /// Room at the sides and ends for the ringed dot.
  static const inset = 6.0;

  @override
  State<_LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<_LineChart> {
  int? _selected;

  @override
  void didUpdateWidget(_LineChart old) {
    super.didUpdateWidget(old);
    if (_selected != null && _selected! >= widget.values.length) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: SizedBox(
        height: _LineChart.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, _LineChart.height);
            final points = _points(size);
            final selected = _selected;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: points.isEmpty
                  ? null
                  : (details) => setState(
                      () => _selected = nearest([
                        for (final p in points) p.dx,
                      ], details.localPosition.dx),
                    ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LinePainter(
                        points: points,
                        targetY: _targetY(size),
                        selected: selected,
                        line: colors.accent,
                        target: colors.success,
                        surface: colors.surface,
                      ),
                    ),
                  ),
                  if (selected != null)
                    Positioned.fill(
                      child: CustomSingleChildLayout(
                        delegate: _TagLayout(points[selected]),
                        child: _Tag(widget.pointLabel(selected)),
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

  (double, double) _range() {
    final all = [...widget.values, ?widget.target];
    return (all.reduce(math.min), all.reduce(math.max));
  }

  List<Offset> _points(Size size) {
    final values = widget.values;
    if (values.isEmpty) return const [];
    final (min, max) = _range();
    const inset = _LineChart.inset;
    final xs = spreadX(values.length, inset, size.width - inset);
    return [
      for (final (i, v) in values.indexed)
        Offset(xs[i], scaleY(v, min, max, inset, size.height - inset)),
    ];
  }

  double? _targetY(Size size) {
    final target = widget.target;
    if (target == null || widget.values.isEmpty) return null;
    final (min, max) = _range();
    const inset = _LineChart.inset;
    return scaleY(target, min, max, inset, size.height - inset);
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.points,
    required this.targetY,
    required this.selected,
    required this.line,
    required this.target,
    required this.surface,
  });

  final List<Offset> points;
  final double? targetY;
  final int? selected;
  final Color line;
  final Color target;
  final Color surface;

  static const dot = 3.0;
  static const selectedDot = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final targetY = this.targetY;
    if (targetY != null) {
      canvas.drawPath(
        dashed(
          Path()
            ..moveTo(0, targetY)
            ..lineTo(size.width, targetY),
          4,
          4,
        ),
        Paint()
          ..color = target
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    if (points.isEmpty) return;
    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(Path()..addPolygon(points, false), stroke);
    final fill = Paint()..color = line;
    for (final (i, p) in points.indexed) {
      if (i == selected) {
        canvas.drawCircle(p, selectedDot, Paint()..color = surface);
        canvas.drawCircle(p, selectedDot, stroke);
      } else {
        canvas.drawCircle(p, dot, fill);
        canvas.drawCircle(p, dot, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points ||
      old.targetY != targetY ||
      old.selected != selected ||
      old.line != line ||
      old.target != target ||
      old.surface != surface;
}

/// Places the tag centred above [point], inside the chart's width; below
/// the point when there is no room above.
class _TagLayout extends SingleChildLayoutDelegate {
  const _TagLayout(this.point);

  final Offset point;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) {
    final x = (point.dx - child.width / 2)
        .clamp(0.0, math.max(0.0, size.width - child.width))
        .toDouble();
    final above = point.dy - _LinePainter.selectedDot - Gap.xs - child.height;
    final y = above >= 0 ? above : point.dy + _LinePainter.selectedDot + Gap.xs;
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_TagLayout old) => old.point != point;
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
      decoration: BoxDecoration(
        color: style.colors.ink,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          maxLines: 1,
          style: style.data.copyWith(fontSize: 11, color: style.colors.surface),
        ),
      ),
    );
  }
}

class _BarChart extends StatefulWidget {
  const _BarChart({
    required this.bars,
    required this.current,
    required this.target,
    required this.band,
    required this.smallLabels,
    required this.semanticLabel,
  });

  final List<ChartBar> bars;
  final int? current;
  final double? target;
  final ({double low, double high})? band;
  final bool smallLabels;
  final String semanticLabel;

  /// The small labels' size and line height.
  static const smallSize = 9.0;
  static const smallLine = 12.0;

  static const height = 130.0;
  static const radius = BorderRadius.all(Radius.circular(4));

  /// The highest of the values and the goal reaches this share of the bars'
  /// height.
  static const peak = 0.95;

  /// A bar with no value yet: a stub of this share.
  static const stub = 0.03;

  @override
  State<_BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<_BarChart> with _Held<_BarChart> {
  @override
  List<ChartBar> get _bars => widget.bars;

  @override
  Widget build(BuildContext context) {
    final _BarChart(:bars, :current, :target, :band, :semanticLabel) = widget;
    const height = _BarChart.height;
    const radius = _BarChart.radius;
    const stub = _BarChart.stub;
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final valueStyle = style.data.copyWith(fontSize: 10);
    final painter = TextPainter(
      text: TextSpan(text: '0', style: valueStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final labelHeight = painter.height;
    painter.dispose();
    final barArea = height - labelHeight - Gap.xs;
    final top =
        [
          for (final bar in bars) ?bar.value,
          ?target,
          ?band?.high,
        ].fold<double>(0, math.max) /
        _BarChart.peak;
    // Bars grow up from zero: a negative value draws none.
    double share(double value) => top <= 0 ? 0 : math.max(0.0, value) / top;
    final held = _held;
    Color fill(int i, double value) {
      final color = band == null
          ? i == current || i == held
                ? colors.accent
                : colors.accent.withValues(alpha: 0.55)
          : value < band.low
          ? Color.lerp(colors.surface, colors.accent, 0.4)!
          : value > band.high
          ? colors.danger
          : colors.accent;
      return held == null || i == held ? color : _faded(color);
    }

    return _semantics(
      semanticLabel,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Gap.sm,
        children: [
          SizedBox(
            height: height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                // Each bar's share of the row, after the gaps between them.
                final barWidth = bars.isEmpty
                    ? 0.0
                    : (width - Gap.sm * (bars.length - 1)) / bars.length;
                final pitch = barWidth + Gap.sm;
                return _holdable(
                  (x) => ((x + Gap.sm / 2) / pitch).floor(),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (band != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: barArea * share(band.low),
                          height:
                              barArea * (share(band.high) - share(band.low)),
                          child: ColoredBox(color: colors.surfaceSunken),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: Gap.sm,
                        children: [
                          for (final (i, bar) in bars.indexed)
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: Gap.xs,
                                children: bar.value == null
                                    ? [
                                        Container(
                                          height: barArea * stub,
                                          decoration: BoxDecoration(
                                            color: colors.surfaceSunken,
                                            borderRadius: radius,
                                          ),
                                        ),
                                      ]
                                    : [
                                        Text(
                                          bar.valueLabel ?? '',
                                          maxLines: 1,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.visible,
                                          softWrap: false,
                                          style: valueStyle.copyWith(
                                            color: i == current
                                                ? colors.ink
                                                : colors.inkMuted,
                                          ),
                                        ),
                                        Container(
                                          height: barArea * share(bar.value!),
                                          decoration: BoxDecoration(
                                            color: fill(i, bar.value!),
                                            borderRadius: radius,
                                          ),
                                        ),
                                      ],
                              ),
                            ),
                        ],
                      ),
                      if (target != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: barArea * share(target) - 0.75,
                          height: 1.5,
                          child: CustomPaint(
                            painter: _GoalPainter(colors.success),
                          ),
                        ),
                      if (held != null)
                        Positioned.fill(
                          child: CustomSingleChildLayout(
                            delegate: _TagLayout(
                              Offset(
                                pitch * held + barWidth / 2,
                                height - barArea * share(bars[held].value!),
                              ),
                            ),
                            child: _Tag(bars[held]._tag!),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            spacing: Gap.sm,
            children: [
              for (final (i, bar) in bars.indexed)
                Expanded(child: _label(context, i, bar.label)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, int i, String label) {
    final _BarChart(:current, :smallLabels) = widget;
    final colors = ForgeStyle.of(context).colors;
    var style = Theme.of(context).textTheme.labelSmall!.copyWith(
      color: i == current ? colors.ink : colors.inkMuted,
      fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
    );
    if (!smallLabels) {
      return Text(label, textAlign: TextAlign.center, style: style);
    }
    style = style.copyWith(
      fontSize: _BarChart.smallSize,
      height: _BarChart.smallLine / _BarChart.smallSize,
    );
    return SizedBox(
      height: MediaQuery.textScalerOf(context).scale(_BarChart.smallLine),
      // Centred on the bar, running past its edges rather than wrapping.
      child: OverflowBox(
        maxWidth: double.infinity,
        child: Text(label, maxLines: 1, softWrap: false, style: style),
      ),
    );
  }
}

class _DenseBarChart extends StatefulWidget {
  const _DenseBarChart({
    required this.bars,
    required this.current,
    required this.target,
    required this.semanticLabel,
  });

  final List<ChartBar> bars;
  final int? current;
  final double? target;
  final String semanticLabel;

  static const height = 120.0;
  static const gap = 2.0;

  /// Room above the tallest bar for the tag.
  static const top = 28.0;
  static const radius = BorderRadius.all(Radius.circular(2));

  @override
  State<_DenseBarChart> createState() => _DenseBarChartState();
}

class _DenseBarChartState extends State<_DenseBarChart>
    with _Held<_DenseBarChart> {
  @override
  List<ChartBar> get _bars => widget.bars;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final bars = widget.bars;
    final target = widget.target;
    const area = _DenseBarChart.height - _DenseBarChart.top;
    final peak = [
      for (final bar in bars) ?bar.value,
      ?target,
    ].fold<double>(0, math.max);
    double height(double value) =>
        peak <= 0 ? 0 : math.max(0.0, value) / peak * area;
    final held = _held;
    return _semantics(
      widget.semanticLabel,
      SizedBox(
        height: _DenseBarChart.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final slot = bars.isEmpty ? 0.0 : width / bars.length;
            return _holdable(
              (x) => (x / slot).floor(),
              Stack(
                // The bars stand on the chart's floor, the tag's room above.
                alignment: AlignmentDirectional.bottomStart,
                clipBehavior: Clip.none,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: _DenseBarChart.gap,
                    children: [
                      for (final (i, bar) in bars.indexed)
                        Expanded(
                          child: Container(
                            height: bar.value == null
                                ? area * _BarChart.stub
                                : height(bar.value!),
                            decoration: BoxDecoration(
                              color: bar.value == null
                                  ? colors.surfaceSunken
                                  : held != null
                                  ? i == held
                                        ? colors.accent
                                        : _faded(colors.accent)
                                  : i == widget.current
                                  ? colors.accent
                                  : colors.accent.withValues(alpha: 0.55),
                              borderRadius: _DenseBarChart.radius,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (target != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: height(target) - 0.75,
                      height: 1.5,
                      child: CustomPaint(painter: _GoalPainter(colors.success)),
                    ),
                  if (held != null)
                    Positioned.fill(
                      child: CustomSingleChildLayout(
                        delegate: _TagLayout(
                          Offset(
                            slot * (held + 0.5),
                            _DenseBarChart.height - height(bars[held].value!),
                          ),
                        ),
                        child: _Tag(bars[held]._tag!),
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
}

/// Press-and-hold on a bar chart: the held bar's index while a finger is
/// down, moving with it from bar to bar; or the tapped bar's, until the
/// next tap.
mixin _Held<T extends StatefulWidget> on State<T> {
  int? _held;

  /// A finger holds a bar, rather than a tap showing its tag.
  bool _pressed = false;

  List<ChartBar> get _bars;

  /// The other bars while one is held: their colour at a quarter.
  Color _faded(Color color) => color.withValues(alpha: color.a * 0.25);

  /// A tap shows [index]'s tag, or hides it when it shows already.
  void _tap(int index) {
    final bars = _bars;
    if (bars.isEmpty) return;
    final tapped = index.clamp(0, bars.length - 1);
    _hold(tapped == _held ? null : tapped);
  }

  void _hold(int? index) {
    final bars = _bars;
    final next = index == null || bars.isEmpty
        ? null
        : index.clamp(0, bars.length - 1);
    final held = next != null && bars[next]._tag != null ? next : null;
    if (held == _held) return;
    if (held != null) HapticFeedback.selectionClick();
    setState(() => _held = held);
  }

  @override
  void didUpdateWidget(T old) {
    super.didUpdateWidget(old);
    final held = _held;
    if (held != null && (held >= _bars.length || _bars[held]._tag == null)) {
      _held = null;
    }
  }

  /// [chart] taking the hold and taps; [indexAt] finds the bar under an
  /// x. A tap outside the chart hides a tapped bar's tag.
  Widget _holdable(int Function(double x) indexAt, Widget chart) => TapRegion(
    onTapOutside: (_) => _hold(null),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) => _tap(indexAt(d.localPosition.dx)),
      onLongPressStart: (d) {
        _pressed = true;
        _hold(indexAt(d.localPosition.dx));
      },
      onLongPressMoveUpdate: (d) => _hold(indexAt(d.localPosition.dx)),
      onLongPressEnd: (_) => _release(),
      // A tap cancels the long press that never started too; only a held
      // bar lets go.
      onLongPressCancel: () {
        if (_pressed) _release();
      },
      child: chart,
    ),
  );

  void _release() {
    _pressed = false;
    _hold(null);
  }

  /// The chart named for screen readers, with one node per bar that reads
  /// what holding it shows.
  Widget _semantics(String label, Widget chart) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: label,
    child: Stack(
      children: [
        ExcludeSemantics(child: chart),
        Positioned.fill(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final bar in _bars)
                Expanded(
                  child: Semantics(
                    container: true,
                    label: bar._spoken,
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _GoalPainter extends CustomPainter {
  const _GoalPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawPath(
      dashed(
        Path()
          ..moveTo(0, y)
          ..lineTo(size.width, y),
        4,
        4,
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.height,
    );
  }

  @override
  bool shouldRepaint(_GoalPainter old) => old.color != color;
}
