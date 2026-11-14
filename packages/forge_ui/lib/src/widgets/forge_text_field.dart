import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_preset.dart';
import '../theme/forge_style.dart';
import 'pressable.dart';

/// An outlined text field: the [label] above a 44px box. It takes a 2px
/// accent outline while typing, a 2px danger outline with the message under
/// it when [validator] fails, and a sunken fill when disabled. [multiline]
/// is the note form: the same box, at least 84px, growing with its text.
class ForgeTextField extends StatefulWidget {
  const ForgeTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscure = false,
    this.multiline = false,
    this.enabled = true,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final bool multiline;
  final bool enabled;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

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
        final error = field.errorText;
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
              TextField(
                controller: _controller,
                enabled: widget.enabled,
                keyboardType: widget.keyboardType,
                obscureText: widget.obscure,
                maxLines: widget.multiline ? null : 1,
                textAlignVertical: widget.multiline
                    ? TextAlignVertical.top
                    : null,
                textInputAction: widget.textInputAction,
                autofillHints: widget.autofillHints,
                onSubmitted: widget.onSubmitted,
                style: text.bodyMedium!.copyWith(color: p.ink),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  fillColor: widget.enabled ? p.surface : p.surfaceSunken,
                  contentPadding: widget.multiline
                      ? const EdgeInsets.all(Gap.md)
                      : null,
                  constraints: widget.multiline
                      ? const BoxConstraints(minHeight: 84)
                      : null,
                  enabledBorder: error == null ? null : outline(p.danger, 2),
                  focusedBorder: error == null ? null : outline(p.danger, 2),
                ),
              ),
              if (error != null) ...[
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
class ForgeNumberField extends StatefulWidget {
  const ForgeNumberField({
    super.key,
    required this.label,
    required this.unit,
    required this.onChanged,
    this.controller,
  });

  final String label;
  final String unit;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  /// The drawn box.
  static const Size size = Size(96, 36);

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
    final value = style.data.copyWith(fontSize: 14, color: p.ink);
    final typing = _focus.hasFocus;
    return Pressable(
      onTap: _focus.requestFocus,
      height: ForgeNumberField.size.height,
      width: ForgeNumberField.size.width,
      builder: (context, _) => Container(
        width: ForgeNumberField.size.width,
        height: ForgeNumberField.size.height,
        padding: EdgeInsets.symmetric(horizontal: Gap.sm - (typing ? 1 : 0)),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.all(
            Radius.circular(ForgeRadii.button),
          ),
          border: typing
              ? Border.all(color: p.accent, width: 2)
              : Border.all(color: p.lineStrong),
        ),
        child: Row(
          spacing: Gap.xs,
          children: [
            Expanded(
              child: Semantics(
                label: widget.label,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  onChanged: widget.onChanged,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.end,
                  style: value,
                  decoration: InputDecoration.collapsed(
                    hintText: '—',
                    hintStyle: value.copyWith(color: p.inkSubtle),
                  ),
                ),
              ),
            ),
            Text(
              widget.unit,
              style: Theme.of(context).textTheme.labelMedium!
                  .copyWith(color: p.inkMuted, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}
