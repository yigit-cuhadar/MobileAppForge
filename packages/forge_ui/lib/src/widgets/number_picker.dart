import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';
import 'numbers.dart';

/// Picks a number from [min] to [max] in steps of [step] under its [label],
/// by dragging a wheel or a ruler.
///
/// [onChanged] reports each step the user moves to. A new [value] from the
/// parent moves the picker to the nearest step without reporting it, and
/// ends a drag under way. The last step is the last one that does not pass
/// [max].
class NumberPicker extends StatefulWidget {
  /// The chosen value large in mono with smaller faded neighbours above and
  /// below; dragging up picks larger values.
  const NumberPicker.wheel({
    super.key,
    required this.label,
    required this.min,
    required this.max,
    required this.step,
    required this.value,
    required this.onChanged,
  }) : unit = null;

  /// The value large above a ruler of thin ticks with whole-number labels,
  /// under a fixed accent pointer; dragging left picks larger values.
  const NumberPicker.ruler({
    super.key,
    required this.label,
    required String this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? unit;
  final double min;
  final double max;
  final double step;
  final double value;
  final ValueChanged<double> onChanged;

  static const double wheelHeight = 200;
  static const double rulerHeight = 52;

  /// Whole numbers the ruler shows across its width.
  static const int rulerSpan = 6;

  /// Ticks per whole number on the ruler.
  static const int rulerTicks = 5;

  /// How far the wheel's centre row moves for one step.
  static const double wheelPitch = 36;

  @override
  State<NumberPicker> createState() => _NumberPickerState();
}

class _NumberPickerState extends State<NumberPicker>
    with SingleTickerProviderStateMixin {
  late int _index = _indexOf(widget.value);

  /// The picker's position in steps from [NumberPicker.min], between steps
  /// while dragged.
  late final _position = AnimationController.unbounded(
    vsync: this,
    value: _index.toDouble(),
  )..addListener(_onMove);

  /// Set while the picker follows a new [NumberPicker.value].
  bool _following = false;
  double _width = 0;

  bool get _ruler => widget.unit != null;

  // The epsilon keeps a last step that lands on max from rounding away.
  int get _count =>
      ((widget.max - widget.min) / widget.step + 1e-9).floor() + 1;

  int _indexOf(double value) =>
      ((value - widget.min) / widget.step).round().clamp(0, _count - 1);

  double _valueAt(int index) => stepValue(widget.min, widget.step, index);

  String _text(int index) =>
      _valueAt(index.clamp(0, _count - 1))
          .toStringAsFixed(decimalsOf(widget.step));

  double get _pixelsPerStep => _ruler
      ? _width / NumberPicker.rulerSpan * widget.step
      : NumberPicker.wheelPitch;

  @override
  void didUpdateWidget(NumberPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = _indexOf(widget.value);
    if (index == _index &&
        widget.min == oldWidget.min &&
        widget.step == oldWidget.step) {
      return;
    }
    _jump(index, report: false);
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _onMove() {
    if (_following) return;
    final index = _position.value.round().clamp(0, _count - 1);
    if (index == _index) return;
    _index = index;
    HapticFeedback.selectionClick();
    widget.onChanged(_valueAt(index));
  }

  void _jump(int index, {required bool report}) {
    _position.stop();
    if (!report) {
      _following = true;
      _index = index;
    }
    _position.value = index.toDouble();
    _following = false;
  }

  /// [pixels] toward larger values.
  void _drag(double pixels) {
    if (_pixelsPerStep <= 0) return;
    _position.stop();
    _position.value = (_position.value + pixels / _pixelsPerStep).clamp(
      0,
      _count - 1,
    );
  }

  /// Comes to rest on a step, a little further along a fling.
  void _settle(double velocity) {
    final projected = _pixelsPerStep <= 0
        ? _position.value
        : _position.value + velocity / _pixelsPerStep * 0.2;
    _position.animateTo(
      projected.round().clamp(0, _count - 1).toDouble(),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final text = Theme.of(context).textTheme;
    final picker = _ruler ? _buildRuler(style, text) : _buildWheel(style);
    return AnimatedBuilder(
      animation: _position,
      builder: (context, child) => Semantics(
        slider: true,
        label: widget.label,
        value: _text(_index),
        increasedValue: _text(_index + 1),
        decreasedValue: _text(_index - 1),
        onIncrease: () =>
            _jump((_index + 1).clamp(0, _count - 1), report: true),
        onDecrease: () =>
            _jump((_index - 1).clamp(0, _count - 1), report: true),
        child: child,
      ),
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Gap.sm,
          children: [
            Text(
              widget.label,
              style: text.labelMedium!.copyWith(color: style.colors.inkMuted),
            ),
            picker,
          ],
        ),
      ),
    );
  }

  Widget _buildWheel(ForgeStyle style) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onVerticalDragUpdate: (d) => _drag(-d.delta.dy),
    onVerticalDragEnd: (d) => _settle(-d.velocity.pixelsPerSecond.dy),
    child: SizedBox(
      height: NumberPicker.wheelHeight,
      width: double.infinity,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _position,
          builder: (context, _) {
            final at = _position.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                for (
                  var i = (at - 4).ceil().clamp(0, _count - 1);
                  i <= (at + 4).floor().clamp(0, _count - 1);
                  i++
                )
                  _wheelRow(style, i, i - at),
              ],
            );
          },
        ),
      ),
    ),
  );

  /// Row [index], [distance] steps from the centre.
  Widget _wheelRow(ForgeStyle style, int index, double distance) {
    final d = distance.abs();
    final centre = d < 0.5;
    final colors = style.colors;
    return Transform.translate(
      offset: Offset(0, distance.sign * _along(d, _wheelOffsets)),
      child: Text(
        _text(index),
        style: style.data.copyWith(
          fontSize: _along(d, _wheelSizes),
          height: 1,
          fontWeight: centre ? FontWeight.w600 : FontWeight.w400,
          color: (centre ? colors.ink : colors.inkMuted).withValues(
            alpha: _along(d, _wheelOpacities),
          ),
        ),
      ),
    );
  }

  // The rows 0, 1, 2, 3 and 4 steps from the centre: the centre row is
  // 44px tall, the others 28px.
  static const _wheelOffsets = <double>[0, 36, 64, 92, 120];
  static const _wheelSizes = <double>[34, 18, 15, 15, 15];
  static const _wheelOpacities = <double>[1, 0.55, 0.3, 0.15, 0];

  /// [stops] read at [d] steps from the centre, linear between steps.
  static double _along(double d, List<double> stops) {
    final i = d.floor();
    if (i >= stops.length - 1) return stops.last;
    return stops[i] + (stops[i + 1] - stops[i]) * (d - i);
  }

  Widget _buildRuler(ForgeStyle style, TextTheme text) {
    final colors = style.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Gap.sm,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: Gap.xs,
          children: [
            AnimatedBuilder(
              animation: _position,
              builder: (context, _) => Text(
                _text(_index),
                style: text.headlineSmall!.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.56,
                ),
              ),
            ),
            Text(
              widget.unit!,
              style: text.bodyMedium!.copyWith(color: colors.inkMuted),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            _width = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (d) => _drag(-d.delta.dx),
              onHorizontalDragEnd: (d) =>
                  _settle(-d.velocity.pixelsPerSecond.dx),
              child: SizedBox(
                height: NumberPicker.rulerHeight,
                width: double.infinity,
                child: ClipRect(
                  child: CustomPaint(
                    painter: _RulerPainter(
                      position: _position,
                      min: widget.min,
                      max: widget.max,
                      step: widget.step,
                      major: colors.ink.withValues(alpha: 0.7),
                      minor: colors.lineStrong,
                      pointer: colors.accent,
                      labelStyle: style.data.copyWith(
                        fontSize: 10,
                        height: 1.2,
                        color: colors.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.position,
    required this.min,
    required this.max,
    required this.step,
    required this.major,
    required this.minor,
    required this.pointer,
    required this.labelStyle,
  }) : super(repaint: position);

  final Animation<double> position;
  final double min;
  final double max;
  final double step;
  final Color major;
  final Color minor;
  final Color pointer;
  final TextStyle labelStyle;

  static const _tickBottom = 14.0;
  static const _majorHeight = 22.0;
  static const _minorHeight = 12.0;
  static const _pointerBottom = 12.0;
  static const _pointerHeight = 34.0;
  static const _arrowWidth = 12.0;
  static const _arrowHeight = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / NumberPicker.rulerSpan;
    final centre = size.width / 2;
    final value = min + position.value * step;
    final tickBase = size.height - _tickBottom;
    const ticks = NumberPicker.rulerTicks;
    final first = ((value - NumberPicker.rulerSpan) * ticks).floor();
    final last = ((value + NumberPicker.rulerSpan) * ticks).ceil();
    final paint = Paint();
    for (var k = first; k <= last; k++) {
      final at = k / ticks;
      if (at < min - 1e-9 || at > max + 1e-9) continue;
      final x = centre + (at - value) * unit;
      final whole = k % ticks == 0;
      final (width, height) = whole ? (2.0, _majorHeight) : (1.5, _minorHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - width / 2, tickBase - height, width, height),
          const Radius.circular(1),
        ),
        paint..color = whole ? major : minor,
      );
      if (whole) {
        final label = TextPainter(
          text: TextSpan(text: '${k ~/ ticks}', style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(
          canvas,
          Offset(x - label.width / 2, size.height - label.height),
        );
        label.dispose();
      }
    }
    paint.color = pointer;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centre - 1,
          size.height - _pointerBottom - _pointerHeight,
          2,
          _pointerHeight,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(centre - _arrowWidth / 2, 0)
        ..lineTo(centre + _arrowWidth / 2, 0)
        ..lineTo(centre, _arrowHeight)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.min != min ||
      old.max != max ||
      old.step != step ||
      old.major != major ||
      old.minor != minor ||
      old.pointer != pointer ||
      old.labelStyle != labelStyle;
}
