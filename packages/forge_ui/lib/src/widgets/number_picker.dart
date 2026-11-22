import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../spacing.dart';
import '../theme/forge_palette.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';
import 'forge_dialog.dart';
import 'numbers.dart';

/// Picks a number from [min] to [max] in steps of [step] by dragging a
/// wheel or a ruler. Its [label] names it for screen readers; the screen
/// shows its own title.
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
    this.grouped = true,
  }) : unit = null,
       parts = null,
       onValueTap = null,
       marker = null,
       _format = null,
       _loop = false;

  /// The value large with its [unit] small beside it, above a ruler of thin
  /// ticks with whole-number labels, under a fixed accent pointer; dragging
  /// left picks larger values. With [parts] in place of [unit], the value
  /// is written as numbers each followed by its small unit ("5 ft 11 in")
  /// while the ruler keeps counting [value]. With [onValueTap] the value is
  /// underlined and a tap on it calls [onValueTap] (the app opens a field to
  /// type the value). A [marker] pins a short accent-soft tag ("Now 70 kg")
  /// to a value on the ruler, such as the one the user starts from.
  const NumberPicker.ruler({
    super.key,
    required this.label,
    this.unit,
    this.parts,
    required this.min,
    required this.max,
    required this.step,
    required this.value,
    required this.onChanged,
    this.grouped = true,
    this.onValueTap,
    this.marker,
  }) : assert(
         (unit == null) != (parts == null),
         'Give the ruler a unit or parts.',
       ),
       _format = null,
       _loop = false;

  /// A bare wheel of [count] rows written by [format], for [ForgeTimeWheel]:
  /// [label] goes to screen readers only; with [loop], the last row is
  /// followed by the first.
  NumberPicker._column({
    required this.label,
    required int count,
    required int index,
    required String Function(int index) this._format,
    required ValueChanged<int> onIndex,
    this._loop = false,
  }) : min = 0,
       max = count - 1.0,
       step = 1,
       value = index.toDouble(),
       onChanged = ((value) => onIndex(value.round())),
       unit = null,
       parts = null,
       onValueTap = null,
       marker = null,
       grouped = false;

  /// What screen readers call the picker; it is not drawn.
  final String label;
  final String? unit;

  /// Writes a value as (number, unit) pairs, such as `[('5', 'ft'), ('11',
  /// 'in')]`.
  final List<(String, String)> Function(double value)? parts;
  final double min;
  final double max;
  final double step;
  final double value;
  final ValueChanged<double> onChanged;

  /// Groups the thousands ("1,000"); false for a value such as a year.
  final bool grouped;
  final VoidCallback? onValueTap;

  /// A value tagged on the ruler; screen readers hear the [label] as a hint.
  final ({double value, String label})? marker;
  final String Function(int index)? _format;
  final bool _loop;

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

  bool get _ruler => widget.unit != null || widget.parts != null;

  // The epsilon keeps a last step that lands on max from rounding away.
  int get _count =>
      ((widget.max - widget.min) / widget.step + 1e-9).floor() + 1;

  int _indexOf(double value) =>
      ((value - widget.min) / widget.step).round().clamp(0, _count - 1);

  double _valueAt(int index) => stepValue(widget.min, widget.step, index);

  /// [index] brought into the picker's range: round it on a looping wheel,
  /// at the nearest end otherwise.
  int _wrap(int index) =>
      widget._loop ? index % _count : index.clamp(0, _count - 1);

  String _text(int index) {
    final at = _wrap(index);
    if (widget.parts case final parts?) {
      return [for (final (n, unit) in parts(_valueAt(at))) '$n $unit']
          .join(' ');
    }
    return widget._format?.call(at) ??
        formatNumber(
          _valueAt(at),
          decimalsOf(widget.step),
          grouped: widget.grouped,
        );
  }

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
    final index = _wrap(_position.value.round());
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
    final next = _position.value + pixels / _pixelsPerStep;
    _position.value = widget._loop ? next : next.clamp(0, _count - 1);
  }

  /// Comes to rest on a step, a little further along a fling.
  void _settle(double velocity) {
    final projected = _pixelsPerStep <= 0
        ? _position.value
        : _position.value + velocity / _pixelsPerStep * 0.2;
    final rest = projected.round();
    _position.animateTo(
      (widget._loop ? rest : rest.clamp(0, _count - 1)).toDouble(),
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
        onIncrease: () => _jump(_wrap(_index + 1), report: true),
        onDecrease: () => _jump(_wrap(_index - 1), report: true),
        onTap: widget.onValueTap,
        hint: widget.marker?.label,
        child: child,
      ),
      child: ExcludeSemantics(child: picker),
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
            int row(int i) => widget._loop ? i : i.clamp(0, _count - 1);
            return Stack(
              alignment: Alignment.center,
              children: [
                for (
                  var i = row((at - 4).ceil());
                  i <= row((at + 4).floor());
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
    final number = text.headlineSmall!.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: -0.56,
    );
    final small = text.bodyMedium!.copyWith(color: colors.inkMuted);
    final parts = widget.parts;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Gap.sm,
      children: [
        Center(
          child: AnimatedBuilder(
            animation: _position,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              spacing: Gap.xs,
              children: [
                for (final (n, unit)
                    in parts?.call(_valueAt(_index)) ??
                        [(_text(_index), widget.unit!)]) ...[
                  _tappableValue(
                    colors,
                    widget.onValueTap,
                    Text(n, style: number),
                  ),
                  Text(unit, style: small),
                ],
              ],
            ),
          ),
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
                      marker: widget.marker,
                      markerFill: colors.accentSoft,
                      markerStyle: text.labelSmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onAccentSoft,
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

/// [value] underlined in line, calling [onTap] when tapped; [value] as it
/// is without [onTap].
Widget _tappableValue(ForgePalette colors, VoidCallback? onTap, Widget value) {
  if (onTap == null) return value;
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: value,
    ),
  );
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
    required this.marker,
    required this.markerFill,
    required this.markerStyle,
  }) : super(repaint: position);

  final Animation<double> position;
  final double min;
  final double max;
  final double step;
  final Color major;
  final Color minor;
  final Color pointer;
  final TextStyle labelStyle;
  final ({double value, String label})? marker;
  final Color markerFill;
  final TextStyle markerStyle;

  static const _tickBottom = 14.0;
  static const _markerHeight = 20.0;
  static const _markerPadding = 6.0;

  /// The marker tag's gap to its value's tick.
  static const _markerGap = 6.0;
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
    if (marker case final marker?) {
      // The tag ends just before its value's tick, or starts just after it
      // where the ruler has no room on the left.
      final x = centre + (marker.value - value) * unit;
      final label = TextPainter(
        text: TextSpan(text: marker.label, style: markerStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final width = label.width + 2 * _markerPadding;
      final left = x - _markerGap - width >= 0
          ? x - _markerGap - width
          : x + _markerGap;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, 0, width, _markerHeight),
          const Radius.circular(6),
        ),
        Paint()..color = markerFill,
      );
      label.paint(
        canvas,
        Offset(left + _markerPadding, (_markerHeight - label.height) / 2),
      );
      label.dispose();
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
      old.labelStyle != labelStyle ||
      old.marker != marker ||
      old.markerFill != markerFill ||
      old.markerStyle != markerStyle;
}

/// Shows a [ForgeTimeWheel] over a scrim; a tap outside closes it.
Future<void> showForgeTimeWheel({
  required BuildContext context,
  required TimeOfDay initial,
  required ValueChanged<TimeOfDay> onChanged,
}) => showDialog<void>(
  context: context,
  builder: (context) => ForgeTimeWheel(initial: initial, onChanged: onChanged),
);

/// A centred dialog with no title and no buttons: wheels for the hours, the
/// minutes and AM/PM, as [NumberPicker.wheel] draws them, the centre row on
/// a band. Hours and minutes go round. Where the device uses 24-hour time
/// ([MediaQuery.alwaysUse24HourFormatOf]), the hours run 0 to 23 and AM/PM
/// goes. [onChanged] reports each step a wheel moves to.
class ForgeTimeWheel extends StatefulWidget {
  const ForgeTimeWheel({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final TimeOfDay initial;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  State<ForgeTimeWheel> createState() => _ForgeTimeWheelState();
}

class _ForgeTimeWheelState extends State<ForgeTimeWheel> {
  late TimeOfDay _time = widget.initial;

  static const _columnWidth = 64.0;

  void _set({int? hour, int? minute}) {
    setState(
      () => _time = TimeOfDay(
        hour: hour ?? _time.hour,
        minute: minute ?? _time.minute,
      ),
    );
    widget.onChanged(_time);
  }

  @override
  Widget build(BuildContext context) {
    final words = MaterialLocalizations.of(context);
    final h24 = MediaQuery.alwaysUse24HourFormatOf(context);
    final pm = _time.period == DayPeriod.pm;
    final hours = h24
        ? NumberPicker._column(
            label: words.timePickerHourLabel,
            count: 24,
            index: _time.hour,
            format: (i) => words.formatHour(
              TimeOfDay(hour: i, minute: 0),
              alwaysUse24HourFormat: true,
            ),
            onIndex: (i) => _set(hour: i),
            loop: true,
          )
        // Rows 1 to 12, at indexes 0 to 11.
        : NumberPicker._column(
            label: words.timePickerHourLabel,
            count: 12,
            index: _time.hourOfPeriod == 0 ? 11 : _time.hourOfPeriod - 1,
            format: (i) => words.formatHour(TimeOfDay(hour: i + 1, minute: 0)),
            onIndex: (i) => _set(hour: (i + 1) % 12 + (pm ? 12 : 0)),
            loop: true,
          );
    final minutes = NumberPicker._column(
      label: words.timePickerMinuteLabel,
      count: 60,
      index: _time.minute,
      format: (i) => words.formatMinute(TimeOfDay(hour: 0, minute: i)),
      onIndex: (i) => _set(minute: i),
      loop: true,
    );
    final period = NumberPicker._column(
      label: '',
      count: 2,
      index: pm ? 1 : 0,
      format: (i) => i == 0
          ? words.anteMeridiemAbbreviation
          : words.postMeridiemAbbreviation,
      onIndex: (i) => _set(hour: _time.hour % 12 + (i == 1 ? 12 : 0)),
    );
    return _WheelDialog(
      label: words.timePickerDialHelpText,
      wheels: [
        for (final wheel in [hours, minutes, if (!h24) period])
          SizedBox(width: _columnWidth, child: wheel),
      ],
    );
  }
}

/// Shows a [ForgeDurationWheel] over a scrim; a tap outside closes it.
Future<void> showForgeDurationWheel({
  required BuildContext context,
  required ForgeDurationWheel wheel,
}) => showDialog<void>(context: context, builder: (_) => wheel);

/// The time wheel's dialog for a length of time, from zero to [max].
/// [onChanged] reports each step a wheel moves to.
class ForgeDurationWheel extends StatefulWidget {
  /// An hours wheel and a minutes wheel in 1-minute steps, each followed
  /// by its unit ([hourUnit], [minuteUnit]). Minutes go round; at [max]'s
  /// whole hours they stay at 0.
  const ForgeDurationWheel.hoursMinutes({
    super.key,
    required this.label,
    required this.initial,
    required this.max,
    required String this.hourUnit,
    required String this.minuteUnit,
    required this.onChanged,
  }) : step = const Duration(minutes: 1),
       secondUnit = null;

  /// Hours, minutes and seconds wheels, seconds in 1-second steps, each
  /// followed by its unit; [secondUnit] also names the seconds wheel for
  /// screen readers. Minutes and seconds go round; past [max] the value
  /// stays at [max].
  const ForgeDurationWheel.hoursMinutesSeconds({
    super.key,
    required this.label,
    required this.initial,
    required this.max,
    required String this.hourUnit,
    required String this.minuteUnit,
    required String this.secondUnit,
    required this.onChanged,
  }) : step = const Duration(seconds: 1);

  /// One wheel of minutes:seconds ("1:30") in steps of [step].
  const ForgeDurationWheel.minutesSeconds({
    super.key,
    required this.label,
    required this.initial,
    required this.max,
    required this.step,
    required this.onChanged,
  }) : hourUnit = null,
       minuteUnit = null,
       secondUnit = null;

  /// What screen readers call the dialog ("Duration").
  final String label;
  final Duration initial;
  final Duration max;
  final Duration step;
  final String? hourUnit;
  final String? minuteUnit;
  final String? secondUnit;
  final ValueChanged<Duration> onChanged;

  @override
  State<ForgeDurationWheel> createState() => _ForgeDurationWheelState();
}

class _ForgeDurationWheelState extends State<ForgeDurationWheel> {
  late Duration _value = widget.initial;

  static const _columnWidth = 64.0;

  /// The width of [row] as a wheel's centre row draws it.
  static double _rowWidth(BuildContext context, String row) {
    final painter = TextPainter(
      text: TextSpan(
        text: row,
        style: ForgeStyle.of(context).data.copyWith(
          fontSize: _NumberPickerState._wheelSizes.first,
          height: 1,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width.ceilToDouble();
    painter.dispose();
    return width;
  }

  void _set(Duration value) {
    setState(() => _value = value > widget.max ? widget.max : value);
    widget.onChanged(_value);
  }

  @override
  Widget build(BuildContext context) {
    final words = MaterialLocalizations.of(context);
    final minuteUnit = widget.minuteUnit;
    if (minuteUnit == null) {
      final step = widget.step.inMilliseconds;
      String format(Duration at) =>
          '${at.inMinutes}:${'${at.inSeconds % 60}'.padLeft(2, '0')}';
      // Wide enough for the longest row, max.
      final width = _rowWidth(context, format(widget.max));
      return _WheelDialog(
        label: widget.label,
        wheels: [
          SizedBox(
            width: width > _columnWidth ? width : _columnWidth,
            child: NumberPicker._column(
              label: widget.label,
              count: widget.max.inMilliseconds ~/ step + 1,
              index: _value.inMilliseconds ~/ step,
              format: (i) => format(widget.step * i),
              onIndex: (i) => _set(widget.step * i),
            ),
          ),
        ],
      );
    }
    final hours = _value.inHours;
    final minutes = _value.inMinutes % 60;
    final seconds = _value.inSeconds % 60;
    final secondUnit = widget.secondUnit;
    final style = Theme.of(context).textTheme.bodyMedium!
        .copyWith(color: ForgeStyle.of(context).colors.inkMuted);
    Widget unit(String text) =>
        ExcludeSemantics(child: Text(text, style: style));
    // Three wheels and their units fit the dialog only as wide as their
    // rows.
    final columnWidth = secondUnit == null
        ? _columnWidth
        : _rowWidth(context, '${widget.max.inHours}'.padLeft(2, '0'));
    Widget wheel(NumberPicker picker) =>
        SizedBox(width: columnWidth, child: picker);
    Duration at({int? h, int? m, int? s}) => Duration(
      hours: h ?? hours,
      minutes: m ?? minutes,
      seconds: s ?? seconds,
    );
    return _WheelDialog(
      label: widget.label,
      wheels: [
        wheel(
          NumberPicker._column(
            label: words.timePickerHourLabel,
            count: widget.max.inHours + 1,
            index: hours,
            format: (i) => '$i',
            onIndex: (i) => _set(at(h: i)),
          ),
        ),
        unit(widget.hourUnit!),
        wheel(
          NumberPicker._column(
            label: words.timePickerMinuteLabel,
            count: 60,
            index: minutes,
            format: (i) => '$i'.padLeft(2, '0'),
            onIndex: (i) => _set(at(m: i)),
            loop: true,
          ),
        ),
        unit(minuteUnit),
        if (secondUnit != null) ...[
          wheel(
            NumberPicker._column(
              label: secondUnit,
              count: 60,
              index: seconds,
              format: (i) => '$i'.padLeft(2, '0'),
              onIndex: (i) => _set(at(s: i)),
              loop: true,
            ),
          ),
          unit(secondUnit),
        ],
      ],
    );
  }
}

/// A centred dialog with no title and no buttons: [wheels] side by side,
/// their centre rows on one band.
class _WheelDialog extends StatelessWidget {
  const _WheelDialog({required this.label, required this.wheels});

  final String label;
  final List<Widget> wheels;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(Gap.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ForgeDialog.maxWidth),
        child: Semantics(
          namesRoute: true,
          scopesRoute: true,
          explicitChildNodes: true,
          label: label,
          child: Padding(
            padding: const EdgeInsets.all(Gap.md),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: ForgeTheme.tapMin,
                  decoration: BoxDecoration(
                    color: style.colors.surfaceSunken,
                    borderRadius: BorderRadius.circular(style.radii.md),
                  ),
                ),
                // Large text shrinks the wheels to fit rather than
                // overflow.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: Gap.sm,
                    children: wheels,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
