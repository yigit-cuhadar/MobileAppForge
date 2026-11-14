import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import 'numbers.dart';
import 'pressable.dart';

/// A sunken 50px pill with round minus and plus buttons at its ends and the
/// value in mono with its [unit] small under it.
///
/// The buttons move the value by [step], kept within [min] and [max]; at a
/// bound its button fades and stops. Tapping the value types it: a 2px
/// accent ring while typing, and every edit is reported, null while the
/// box holds no number, out of range values as typed. The app checks them
/// and passes [errorText], shown under a 2px danger ring. With no value the
/// pill shows the [hint] faded, or a dash. [enabled] false fades it all.
class StepperField extends StatefulWidget {
  const StepperField({
    super.key,
    required this.value,
    required this.unit,
    required this.step,
    required this.onChanged,
    this.min,
    this.max,
    this.hint,
    this.errorText,
    this.enabled = true,
  });

  final double? value;
  final String unit;
  final double step;
  final ValueChanged<double?> onChanged;
  final double? min;
  final double? max;
  final double? hint;
  final String? errorText;
  final bool enabled;

  static const double height = 50;
  static const double buttonSize = 36;

  @override
  State<StepperField> createState() => _StepperFieldState();
}

class _StepperFieldState extends State<StepperField> {
  final _focus = FocusNode();
  final _controller = TextEditingController();

  bool _typing = false;

  String _text(double v) => v.toStringAsFixed(decimalsOf(widget.step));

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _typing) setState(() => _typing = false);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _startTyping() {
    final value = widget.value;
    _controller.value = TextEditingValue(
      text: value == null ? '' : _text(value),
      selection: TextSelection(
        baseOffset: 0,
        extentOffset: value == null ? 0 : _text(value).length,
      ),
    );
    setState(() => _typing = true);
  }

  void _typed(String text) =>
      widget.onChanged(double.tryParse(text.trim().replaceAll(',', '.')));

  bool get _atMin {
    final v = widget.value;
    return v != null && widget.min != null && v <= widget.min!;
  }

  bool get _atMax {
    final v = widget.value;
    return v != null && widget.max != null && v >= widget.max!;
  }

  /// One step by [direction]; an empty field starts from its hint.
  double _next(int direction) {
    final from = widget.value ?? widget.hint ?? widget.min ?? 0;
    var next = double.parse(
      (from + direction * widget.step).toStringAsFixed(10),
    );
    if (widget.min != null && next < widget.min!) next = widget.min!;
    if (widget.max != null && next > widget.max!) next = widget.max!;
    return next;
  }

  void _move(int direction) {
    _focus.unfocus();
    widget.onChanged(_next(direction));
  }

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final enabled = widget.enabled;
    final error = widget.errorText;
    final value = widget.value;
    final valueStyle = style.data.copyWith(
      fontSize: 18,
      height: 22 / 18,
      fontWeight: FontWeight.w500,
      color: colors.ink,
    );
    final ring = error != null
        ? colors.danger
        : _typing
        ? colors.accent
        : null;

    Widget button(ForgeIconData icon, int direction, bool atBound) {
      final active = enabled && !atBound;
      return Pressable(
        onTap: active ? () => _move(direction) : null,
        height: StepperField.buttonSize,
        width: StepperField.buttonSize,
        builder: (context, _) => Opacity(
          opacity: atBound ? 0.4 : 1,
          child: Container(
            width: StepperField.buttonSize,
            height: StepperField.buttonSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
            ),
            child: ForgeIcon(icon, size: 18, weight: 2.2, color: colors.ink),
          ),
        ),
      );
    }

    final shown = _typing
        ? SizedBox(
            width: double.infinity,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              onChanged: _typed,
              onTapOutside: (_) => _focus.unfocus(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: valueStyle,
              decoration: const InputDecoration.collapsed(hintText: null),
              cursorWidth: 2,
            ),
          )
        : Text(
            value == null
                ? (widget.hint == null ? '—' : _text(widget.hint!))
                : _text(value),
            style: value == null
                ? valueStyle.copyWith(color: colors.inkSubtle)
                : valueStyle,
          );

    final pill = Container(
      height: StepperField.height,
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(StepperField.height / 2),
      ),
      foregroundDecoration: ring == null
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(StepperField.height / 2),
              border: Border.all(color: ring, width: 2),
            ),
      child: Row(
        children: [
          ExcludeSemantics(child: button(ForgeIcons.remove, -1, _atMin)),
          Expanded(
            child: Semantics(
              textField: true,
              enabled: enabled,
              value: value == null ? null : '${_text(value)} ${widget.unit}',
              increasedValue: value == null
                  ? null
                  : '${_text(_next(1))} ${widget.unit}',
              decreasedValue: value == null
                  ? null
                  : '${_text(_next(-1))} ${widget.unit}',
              onIncrease: enabled && !_atMax ? () => _move(1) : null,
              onDecrease: enabled && !_atMin ? () => _move(-1) : null,
              onTap: enabled && !_typing ? _startTyping : null,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: enabled && !_typing ? _startTyping : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    shown,
                    Text(
                      widget.unit,
                      style: text.labelSmall!.copyWith(
                        fontSize: 10,
                        height: 12 / 10,
                        fontWeight: FontWeight.w400,
                        color: colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ExcludeSemantics(child: button(ForgeIcons.add, 1, _atMax)),
        ],
      ),
    );

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Gap.sm,
        children: [
          pill,
          if (error != null)
            Text(
              error,
              style: text.labelMedium!.copyWith(
                fontWeight: FontWeight.w400,
                color: colors.danger,
              ),
            ),
        ],
      ),
    );
  }
}
