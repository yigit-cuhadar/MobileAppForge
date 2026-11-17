import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../spacing.dart';
import '../theme/forge_preset.dart';
import '../theme/forge_style.dart';
import 'pressable.dart';
import 'bare_decoration.dart';

/// An outlined text field: the [label] above a 44px box. It takes a 2px
/// accent outline while typing, a 2px danger outline with the message under
/// it when [validator] fails or the caller sets [errorText], and a sunken
/// fill when disabled. [multiline]
/// is the note form: the same box, wrapping and growing up to three lines,
/// then scrolling inside. [maxLength] stops input at that many characters,
/// with no counter. [autofocus] raises the keyboard as the field appears
/// (a dialog's field). [unit] sits muted after the value, inside the box.
class ForgeTextField extends StatefulWidget {
  const ForgeTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.obscure = false,
    this.multiline = false,
    this.maxLength,
    this.enabled = true,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.unit,
  }) : value = null,
       onTap = null;

  /// The field's look with its [value] (or the [hint]), never editable:
  /// [onTap] opens what picks the value (a wheel).
  const ForgeTextField.tapOnly({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    required VoidCallback this.onTap,
  }) : controller = null,
       validator = null,
       errorText = null,
       keyboardType = null,
       inputFormatters = null,
       obscure = false,
       multiline = false,
       maxLength = null,
       enabled = true,
       textInputAction = null,
       autofillHints = null,
       onChanged = null,
       onSubmitted = null,
       autofocus = false,
       unit = null;

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;

  /// An error the caller keeps up to date as the user types; it wins over
  /// [validator]'s. An empty one marks the field without a line under it,
  /// for fields sharing one message.
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscure;
  final bool multiline;
  final int? maxLength;
  final bool enabled;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final String? unit;
  final String? value;
  final VoidCallback? onTap;

  @override
  State<ForgeTextField> createState() => _ForgeTextFieldState();
}

class _ForgeTextFieldState extends State<ForgeTextField> {
  TextEditingController? _own;

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ForgeStyle.of(context).colors;
    final text = Theme.of(context).textTheme;
    OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(ForgeRadii.button)),
      borderSide: BorderSide(color: color, width: width),
    );

    return _TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      validator: widget.validator == null
          ? null
          : (_) => widget.validator!(_controller.text),
      builder: (field) {
        final error = widget.errorText ?? field.errorText;
        final input = text.bodyMedium!.copyWith(color: p.ink);
        final decoration = InputDecoration(
          hintText: widget.hint,
          fillColor: widget.enabled ? p.surface : p.surfaceSunken,
          counterText: '',
          suffixText: widget.unit,
          suffixStyle: input.copyWith(color: p.inkMuted),
          enabledBorder: error == null ? null : outline(p.danger, 2),
          focusedBorder: error == null ? null : outline(p.danger, 2),
        );
        return MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: text.labelMedium!.copyWith(
                  color: error == null ? p.inkMuted : p.danger,
                ),
              ),
              const SizedBox(height: Gap.sm),
              if (widget.onTap case final onTap?)
                Semantics(
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: InputDecorator(
                      decoration: decoration,
                      isEmpty: widget.value == null,
                      child: Text(
                        widget.value ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: input,
                      ),
                    ),
                  ),
                )
              else
                TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  obscureText: widget.obscure,
                  maxLines: widget.multiline ? 3 : 1,
                  minLines: 1,
                  maxLength: widget.maxLength,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: input,
                  decoration: decoration,
                ),
              if (error != null && error.isNotEmpty) ...[
                const SizedBox(height: Gap.sm),
                Text(
                  error,
                  style: text.labelMedium!.copyWith(
                    color: p.danger,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// A [FormField] whose [Form.reset] clears the text, as [TextFormField]
/// does.
class _TextFormField extends FormField<String> {
  const _TextFormField({
    required this.controller,
    super.enabled,
    super.validator,
    required super.builder,
  });

  final TextEditingController controller;

  @override
  FormFieldState<String> createState() => _TextFormFieldState();
}

class _TextFormFieldState extends FormFieldState<String> {
  @override
  void reset() {
    (widget as _TextFormField).controller.clear();
    super.reset();
  }
}

/// A compact number box at the end of a list row: the value in mono,
/// right-aligned, with its [unit] small inside. The row's title is its
/// [label], read out by screen readers. It takes taps across a 44px band.
///
/// A row of a left and right pair holds two boxes, each with its [side]
/// ("Left", "Right") small at its start.
class ForgeNumberField extends StatefulWidget {
  const ForgeNumberField({
    super.key,
    required this.label,
    required String this.unit,
    required this.onChanged,
    this.controller,
    this.side,
  }) : boxSize = size,
       invalid = false,
       _tall = false;

  /// A 34px box [width] wide with no unit and the value right-aligned, for
  /// values edited inside a row (a set's weight and reps). An [invalid]
  /// value gets a danger border, also while typing; the row says what is
  /// wrong.
  ForgeNumberField.compact({
    super.key,
    required this.label,
    required double width,
    required this.onChanged,
    this.controller,
    this.invalid = false,
  }) : unit = null,
       side = null,
       boxSize = Size(width, compactHeight),
       _tall = false;

  /// [ForgeNumberField.compact] 40px tall with the value at its start in
  /// 15px, for a row made of its own fields (a custom warm-up set).
  ForgeNumberField.tall({
    super.key,
    required this.label,
    required double width,
    required this.onChanged,
    this.controller,
    this.invalid = false,
  }) : unit = null,
       side = null,
       boxSize = Size(width, tallHeight),
       _tall = true;

  final String label;
  final String? unit;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final String? side;

  /// The drawn box of this field.
  final Size boxSize;
  final bool invalid;
  final bool _tall;

  /// The drawn box of the form with a unit.
  static const Size size = Size(96, 36);
  static const double compactHeight = 34;
  static const double tallHeight = 40;

  @override
  State<ForgeNumberField> createState() => _ForgeNumberFieldState();
}

class _ForgeNumberFieldState extends State<ForgeNumberField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final p = style.colors;
    final tall = widget._tall;
    final value = style.data.copyWith(fontSize: tall ? 15 : 14, color: p.ink);
    final text = Theme.of(context).textTheme;
    final side = widget.side;
    final border = widget.invalid
        ? Border.all(color: p.danger, width: 1.5)
        : _focus.hasFocus
        ? Border.all(color: p.accent, width: 2)
        : Border.all(color: p.lineStrong);
    return Pressable(
      onTap: _focus.requestFocus,
      height: widget.boxSize.height,
      width: widget.boxSize.width,
      builder: (context, _) => Container(
        width: widget.boxSize.width,
        height: widget.boxSize.height,
        // The value keeps its place as the border thickens.
        padding: EdgeInsets.symmetric(
          horizontal: (tall ? 10 : Gap.sm) - (border.top.width - 1),
        ),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.all(
            Radius.circular(ForgeRadii.button),
          ),
          border: border,
        ),
        child: Row(
          spacing: Gap.xs,
          children: [
            if (side != null)
              ExcludeSemantics(
                child: Text(
                  side,
                  style: text.labelSmall!.copyWith(
                    color: p.inkMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            Expanded(
              child: Semantics(
                label: side == null ? widget.label : '${widget.label}, $side',
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  onChanged: widget.onChanged,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: tall ? TextAlign.start : TextAlign.end,
                  style: value,
                  decoration: bareDecoration(
                    hintText: '—',
                    hintStyle: value.copyWith(color: p.inkSubtle),
                  ),
                ),
              ),
            ),
            if (widget.unit case final unit?)
              Text(
                unit,
                style: text.labelMedium!.copyWith(
                  color: p.inkMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
