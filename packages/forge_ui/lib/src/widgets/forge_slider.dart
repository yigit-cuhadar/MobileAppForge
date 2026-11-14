import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';
import 'numbers.dart';

/// Picks a value from [min] to [max] by dragging: the [label] with the
/// value and [unit] in mono on the right, a thin track filled in accent up
/// to a round thumb, and the range's ends under it. Tapping the track moves
/// the thumb there; while dragged the thumb grows and a bubble above it
/// shows the value. With a [step] the thumb snaps and a mark sits at each
/// step. Null [onChanged] disables the slider.
class ForgeSlider extends StatelessWidget {
  const ForgeSlider({
    super.key,
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    this.step,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String unit;
  final double min;
  final double max;
  final double? step;
  final double value;
  final ValueChanged<double>? onChanged;

  int get _decimals => step == null ? 0 : decimalsOf(step!);

  String _text(double v) => formatNumber(v, _decimals);

  double get _fraction =>
      max <= min ? 0 : ((value - min) / (max - min)).clamp(0.0, 1.0);

  /// The value at [fraction] of the track, on a step when there are steps.
  double _valueAt(double fraction) {
    final raw = min + fraction * (max - min);
    if (step == null) return raw;
    final last = ((max - min) / step! + 1e-9).floor();
    return stepValue(min, step!, ((raw - min) / step!).round().clamp(0, last));
  }

  void _move(double fraction) {
    final next = _valueAt(fraction);
    if (next == value) return;
    if (step != null) HapticFeedback.selectionClick();
    onChanged!(next);
  }

  double _nudged(int direction) =>
      (value + direction * (step ?? (max - min) / 20)).clamp(min, max);

  void _nudge(int direction) {
    final next = _nudged(direction);
    if (next != value) onChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final mono = style.data.copyWith(fontSize: 14, height: 20 / 14);
    final ends = style.data.copyWith(fontSize: 11, color: colors.inkMuted);
    final enabled = onChanged != null;
    final valueText = '${_text(value)} $unit';
    final steps = step == null
        ? null
        // One value only: its one mark sits under the thumb at the start.
        : max <= min
        ? const [0.0]
        : [
            for (var i = 0; i <= ((max - min) / step! + 1e-9).floor(); i++)
              i * step! / (max - min),
          ];
    return Semantics(
      slider: true,
      enabled: enabled,
      label: label,
      value: valueText,
      increasedValue: '${_text(_nudged(1))} $unit',
      decreasedValue: '${_text(_nudged(-1))} $unit',
      onIncrease: enabled ? () => _nudge(1) : null,
      onDecrease: enabled ? () => _nudge(-1) : null,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: SliderArea(
            onChanged: enabled ? _move : null,
            builder: (context, dragging) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Gap.xs,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  spacing: Gap.sm,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: text.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(valueText, style: mono),
                  ],
                ),
                SliderTrack(
                  fraction: _fraction,
                  dragging: dragging,
                  steps: steps,
                  bubble: valueText,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_text(min), style: ends),
                    Text(_text(max), style: ends),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Takes taps and horizontal drags across its width and reports where they
/// fall as a share of that width, from 0 to 1. Null [onChanged] disables
/// it.
class SliderArea extends StatefulWidget {
  const SliderArea({super.key, required this.onChanged, required this.builder});

  final ValueChanged<double>? onChanged;
  final Widget Function(BuildContext context, bool dragging) builder;

  @override
  State<SliderArea> createState() => _SliderAreaState();
}

class _SliderAreaState extends State<SliderArea> {
  bool _dragging = false;

  void _drag(bool dragging) {
    if (dragging != _dragging) setState(() => _dragging = dragging);
  }

  @override
  Widget build(BuildContext context) {
    final onChanged = widget.onChanged;
    return LayoutBuilder(
      builder: (context, constraints) {
        void move(Offset at) => onChanged!(
          constraints.maxWidth <= 0
              ? 0
              : (at.dx / constraints.maxWidth).clamp(0.0, 1.0),
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onChanged == null ? null : (d) => move(d.localPosition),
          onHorizontalDragStart: onChanged == null
              ? null
              : (d) {
                  _drag(true);
                  move(d.localPosition);
                },
          onHorizontalDragUpdate: onChanged == null
              ? null
              : (d) => move(d.localPosition),
          onHorizontalDragEnd: onChanged == null ? null : (_) => _drag(false),
          onHorizontalDragCancel: onChanged == null ? null : () => _drag(false),
          child: widget.builder(context, _dragging && onChanged != null),
        );
      },
    );
  }
}

/// The slider's 28px track: sunken, filled in accent up to the thumb at
/// [fraction]. While [dragging] the thumb grows and a dark [bubble] above it
/// shows the value. [steps] are the shares of the width that carry a mark.
class SliderTrack extends StatelessWidget {
  const SliderTrack({
    super.key,
    required this.fraction,
    required this.dragging,
    this.steps,
    this.bubble,
  });

  final double fraction;
  final bool dragging;
  final List<double>? steps;
  final String? bubble;

  static const double height = 28;

  /// The thumb, for finding it in tests.
  static const thumbKey = ValueKey('SliderTrack.thumb');

  static const _bar = 4.0;
  static const _thumb = 20.0;
  static const _thumbDragged = 28.0;
  static const _bubbleHeight = 26.0;

  /// From the track's bottom edge to the bubble's.
  static const _bubbleLift = 26.0;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    const top = (height - _bar) / 2;
    final thumb = dragging ? _thumbDragged : _thumb;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final x = constraints.maxWidth * fraction;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: top,
                height: _bar,
                child: _pill(colors.surfaceSunken),
              ),
              Positioned(
                left: 0,
                width: x,
                top: top,
                height: _bar,
                child: _pill(colors.accent),
              ),
              for (final at in steps ?? const <double>[])
                Positioned(
                  left: constraints.maxWidth * at - _bar / 2,
                  top: top,
                  width: _bar,
                  height: _bar,
                  child: _pill(
                    at <= fraction + 1e-9
                        ? colors.onAccent.withValues(alpha: 0.7)
                        : colors.lineStrong,
                  ),
                ),
              Positioned(
                key: thumbKey,
                left: x - thumb / 2,
                top: height / 2 - thumb / 2,
                width: thumb,
                height: thumb,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(
                      dragging ? thumb / 2 : style.radii.sm,
                    ),
                    border: Border.all(color: colors.accent, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow
                            .withValues(alpha: 0.18),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
              if (dragging && bubble != null)
                Positioned(
                  left: x,
                  top: top + _bar - _bubbleLift - _bubbleHeight,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, 0),
                    child: Container(
                      height: _bubbleHeight,
                      padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.ink,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bubble!,
                        style: style.data.copyWith(color: colors.surface),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static Widget _pill(Color color) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(_bar / 2),
    ),
  );
}
