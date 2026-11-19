import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import 'numbers.dart';
import 'pressable.dart';
import 'skeleton.dart';
import 'bare_decoration.dart';

/// A sunken 50px pill with round minus and plus buttons at its ends and the
/// value in mono with its [unit] small under it, with the fewest decimals
/// that show it exactly: "60" and "62.5" on a 2.5 step, "82.5" on a 5 step.
///
/// The buttons move the value by [step], kept within [min] and [max]; at a
/// bound its button fades and stops. Tapping the value types it: a 2px
/// accent ring while typing, and every edit is reported, null while the
/// box holds no number, out of range values as typed. The app checks them
/// and passes [errorText], shown under a 2px danger ring. With no value the
/// pill shows the [hint] faded, or a dash. [enabled] false fades it all.
///
/// When one message covers a row of fields, each wrong field is [invalid]
/// (the ring alone) and the app places a [StepperFieldError] under the row.
///
/// A row of fields types one after another: with a [focusNode] the app can
/// start typing in a field ([FocusNode.requestFocus]), and a tap on another
/// field's value moves the typing there at once, keeping the keyboard up.
/// With a [doneLabel], a bar above the keyboard holds [nextLabel] at its
/// start, calling [onNext] (the app focuses the next field; without it Next
/// is greyed), and [doneLabel] at its end, which closes the keyboard.
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
    this.grouped = true,
    this.signed = false,
    this.invalid = false,
    this.compact = false,
    this.focusNode,
    this.nextLabel,
    this.onNext,
    this.doneLabel,
  }) : assert(
         nextLabel == null || doneLabel != null,
         'Next sits on the keyboard bar, which needs a Done label.',
       ),
       assert(onNext == null || nextLabel != null);

  final double? value;
  final String unit;
  final double step;
  final ValueChanged<double?> onChanged;
  final double? min;
  final double? max;
  final double? hint;
  final String? errorText;
  final bool enabled;

  /// Groups the thousands ("1,000"); false for a value such as a year.
  final bool grouped;

  /// Marks a value above zero with "+", as for a load added to the body.
  final bool signed;

  /// The danger ring with no message under the field.
  final bool invalid;

  /// The 40px form with 30px buttons, for a row under the main fields.
  final bool compact;

  /// Typing in the field holds this node's focus.
  final FocusNode? focusNode;
  final String? nextLabel;
  final VoidCallback? onNext;
  final String? doneLabel;

  /// The keyboard bar's height.
  static const double barHeight = 44;

  static const double height = 50;
  static const double buttonSize = 36;
  static const double compactHeight = 40;
  static const double compactButtonSize = 30;

  /// The field while its value loads: a shimmering full-width pill.
  static Widget loading({Key? key}) =>
      SkeletonBar(key: key, widthFactor: 1, height: height);

  @override
  State<StepperField> createState() => _StepperFieldState();
}

class _StepperFieldState extends State<StepperField> {
  FocusNode? _ownFocus;
  final _controller = TextEditingController();
  final _bar = OverlayPortalController();

  bool _typing = false;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  String _text(double v) {
    final text = formatNumber(v, decimalsOf(v), grouped: widget.grouped);
    return widget.signed && v > 0 ? '+$text' : text;
  }

  /// The value as the box is typed in: no grouping, no sign.
  String _typedText(double v) => v.toStringAsFixed(decimalsOf(v));

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(StepperField old) {
    super.didUpdateWidget(old);
    if (old.focusNode == widget.focusNode) return;
    (old.focusNode ?? _ownFocus)?.removeListener(_focusChanged);
    if (widget.focusNode != null) {
      _ownFocus?.dispose();
      _ownFocus = null;
    }
    _focus.addListener(_focusChanged);
  }

  @override
  void dispose() {
    _focus.removeListener(_focusChanged);
    _ownFocus?.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Typing follows the focus, whoever moves it: a tap, the app or Next.
  void _focusChanged() {
    final typing = _focus.hasFocus;
    if (typing == _typing) return;
    final value = widget.value;
    _controller.value = !typing || value == null
        ? TextEditingValue.empty
        : TextEditingValue(
            text: _typedText(value),
            selection: TextSelection(
              baseOffset: 0,
              extentOffset: _typedText(value).length,
            ),
          );
    setState(() => _typing = typing);
    if (typing && widget.doneLabel != null) {
      _bar.show();
    } else if (_bar.isShowing) {
      _bar.hide();
    }
  }

  void _startTyping() => _focus.requestFocus();

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
    final height = widget.compact
        ? StepperField.compactHeight
        : StepperField.height;
    final buttonSize = widget.compact
        ? StepperField.compactButtonSize
        : StepperField.buttonSize;
    final ring = error != null || widget.invalid
        ? colors.danger
        : _typing
        ? colors.accent
        : null;

    Widget button(ForgeIconData icon, int direction, bool atBound) {
      final active = enabled && !atBound;
      return Pressable(
        onTap: active ? () => _move(direction) : null,
        // In the compact pill the band can only grow to the pill.
        height: widget.compact ? StepperField.compactHeight : buttonSize,
        width: buttonSize,
        builder: (context, _) => Opacity(
          opacity: atBound ? 0.4 : 1,
          child: Container(
            width: buttonSize,
            height: buttonSize,
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

    // The box stays built so that focus can reach it from outside; it
    // shows only while typing, in place of the value.
    final shown = Stack(
      alignment: Alignment.center,
      children: [
        if (!_typing)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value == null
                  ? (widget.hint == null ? '—' : _text(widget.hint!))
                  : _text(value),
              maxLines: 1,
              style: value == null
                  ? valueStyle.copyWith(color: colors.inkSubtle)
                  : valueStyle,
            ),
          ),
        Opacity(
          opacity: _typing ? 1 : 0,
          child: IgnorePointer(
            ignoring: !_typing,
            child: ExcludeSemantics(
              excluding: !_typing,
              child: SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  enabled: enabled,
                  onChanged: _typed,
                  onTapOutside: (_) => _focus.unfocus(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: valueStyle,
                  decoration: bareDecoration(),
                  cursorWidth: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    // Larger text grows the pill past its height.
    final pill = Container(
      constraints: BoxConstraints(minHeight: height),
      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 5 : Gap.sm),
      decoration: ShapeDecoration(
        color: colors.surfaceSunken,
        shape: const StadiumBorder(),
      ),
      // Always set: adding it when the typing starts would rebuild the box
      // under it and close the keyboard the tap just opened.
      foregroundDecoration: ShapeDecoration(
        shape: StadiumBorder(
          side: ring == null
              ? BorderSide.none
              : BorderSide(color: ring, width: 2),
        ),
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
              // A tap here while another field types is no tap outside it:
              // the typing moves here without the keyboard closing.
              child: TextFieldTapRegion(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: enabled && !_typing ? _startTyping : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        shown,
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.unit,
                            maxLines: 1,
                            style: text.labelSmall!.copyWith(
                              fontSize: 10,
                              height: 12 / 10,
                              fontWeight: FontWeight.w400,
                              color: colors.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ExcludeSemantics(child: button(ForgeIcons.add, 1, _atMax)),
        ],
      ),
    );

    final field = Opacity(
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
    if (widget.doneLabel == null) return field;
    // The root overlay covers the whole view, so the bar can sit on the
    // keyboard however the routes and tabs in between are laid out.
    return OverlayPortal(
      overlayLocation: OverlayChildLocation.rootOverlay,
      controller: _bar,
      overlayChildBuilder: _keyboardBar,
      child: field,
    );
  }

  /// The Next / Done bar, sitting on the keyboard.
  Widget _keyboardBar(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final label = Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16);
    Widget action(String text, VoidCallback? onTap, FontWeight weight) =>
        Semantics(
          button: true,
          enabled: onTap != null,
          child: Pressable(
            onTap: onTap,
            height: StepperField.barHeight,
            builder: (context, pressed) => Opacity(
              opacity: pressed ? 0.6 : 1,
              child: Text(
                text,
                style: label.copyWith(
                  fontWeight: weight,
                  color: onTap == null ? colors.lineStrong : colors.accent,
                ),
              ),
            ),
          ),
        );
    return _OnKeyboard(
      // Part of the field: its taps do not end the typing.
      child: TextFieldTapRegion(
        child: Container(
          constraints: const BoxConstraints(minHeight: StepperField.barHeight),
          padding: const EdgeInsets.symmetric(horizontal: Gap.md),
          decoration: BoxDecoration(
            color: colors.surfaceBar,
            border: Border(top: BorderSide(color: colors.line)),
          ),
          child: Row(
            children: [
              if (widget.nextLabel case final next?)
                Flexible(child: action(next, widget.onNext, FontWeight.w500)),
              const Spacer(),
              Flexible(
                child: action(
                  widget.doneLabel!,
                  _focus.unfocus,
                  FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Places [child] across the bottom of the overlay, right on top of the
/// keyboard. The keyboard's height comes from the view: a Scaffold takes
/// it out of the MediaQuery its body (and so the field) sees.
class _OnKeyboard extends StatefulWidget {
  const _OnKeyboard({required this.child});

  final Widget child;

  @override
  State<_OnKeyboard> createState() => _OnKeyboardState();
}

class _OnKeyboardState extends State<_OnKeyboard> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: view.viewInsets.bottom / view.devicePixelRatio,
      child: widget.child,
    );
  }
}

/// The message for a row of [StepperField]s, placed by the app under the
/// row; the wrong fields there are [StepperField.invalid].
class StepperFieldError extends StatelessWidget {
  const StepperFieldError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall!
          .copyWith(color: ForgeStyle.of(context).colors.danger),
    ),
  );
}
