import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';
import 'card_frame.dart';
import 'forge_button.dart';
import 'radio_mark.dart';

/// One answer of a [ChoiceGrid].
class ChoiceOption {
  const ChoiceOption({required this.label, required this.hint});

  final String label;
  final String hint;
}

/// How the rows of a [ChoiceGrid.list] are drawn.
enum ChoiceListForm {
  /// 44px rows, the hint beside the label as a one-line meaning.
  inline,

  /// Rows at least 60px tall, the hint on a second line.
  stacked,
}

/// A question on a card: the [title], its [detail], and a single column of
/// [options], each a 56px row with a radio, the label and its hint. The
/// [selected] row sits on accent-soft; keyboard focus is a 2px accent ring.
/// With [onSkip] the header carries a [skipLabel] text button. The options
/// read as a radio group.
class ChoiceGrid extends StatelessWidget {
  const ChoiceGrid({
    super.key,
    required this.title,
    required this.detail,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.onSkip,
    this.skipLabel,
  }) : assert(
         (onSkip == null) == (skipLabel == null),
         'Give Skip a label and an action together.',
       ),
       form = null;

  /// The options alone, with no card or header, for a panel or page that
  /// asks the question itself.
  const ChoiceGrid.list({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required ChoiceListForm this.form,
  }) : title = null,
       detail = null,
       onSkip = null,
       skipLabel = null;

  final String? title;
  final String? detail;
  final List<ChoiceOption> options;

  /// The chosen option's index, or null.
  final int? selected;
  final ValueChanged<int> onSelected;
  final VoidCallback? onSkip;
  final String? skipLabel;

  /// The list form's rows; null on the card.
  final ChoiceListForm? form;

  @override
  Widget build(BuildContext context) {
    final rows = Semantics(
      container: true,
      role: SemanticsRole.radioGroup,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: switch (form) {
          null => Gap.xs,
          ChoiceListForm.inline => 2,
          ChoiceListForm.stacked => 6,
        },
        children: [
          for (var i = 0; i < options.length; i++)
            _ChoiceRow(
              option: options[i],
              form: form,
              selected: i == selected,
              onTap: () => onSelected(i),
            ),
        ],
      ),
    );
    final title = this.title;
    if (title == null) return rows;
    final style = ForgeStyle.of(context);
    final text = Theme.of(context).textTheme;
    return CardFrame(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Gap.md,
          children: [
            Row(
              spacing: Gap.sm,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(title, style: text.titleMedium),
                      Text(
                        detail!,
                        style: text.labelMedium!.copyWith(
                          fontWeight: FontWeight.w400,
                          color: style.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (skipLabel case final skipLabel?)
                  ForgeButton(
                    label: skipLabel,
                    onPressed: onSkip,
                    variant: ForgeButtonVariant.text,
                  ),
              ],
            ),
            rows,
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatefulWidget {
  const _ChoiceRow({
    required this.option,
    required this.form,
    required this.selected,
    required this.onTap,
  });

  final ChoiceOption option;
  final ChoiceListForm? form;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ChoiceRow> createState() => _ChoiceRowState();
}

class _ChoiceRowState extends State<_ChoiceRow> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final selected = widget.selected;
    final radius = BorderRadius.circular(style.radii.md);
    final label = Text(
      widget.option.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: text.titleMedium!.copyWith(
        color: selected ? colors.onAccentSoft : colors.ink,
      ),
    );
    Widget hint(TextStyle role) => Text(
      widget.option.hint,
      maxLines: widget.form == ChoiceListForm.stacked ? null : 1,
      overflow: widget.form == ChoiceListForm.stacked
          ? null
          : TextOverflow.ellipsis,
      style: role.copyWith(fontWeight: FontWeight.w400, color: colors.inkMuted),
    );
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: FocusableActionDetector(
        onShowFocusHighlight: (focused) => setState(() => _focused = focused),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => widget.onTap(),
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            height: switch (widget.form) {
              null => 56,
              ChoiceListForm.inline => 44,
              ChoiceListForm.stacked => null,
            },
            constraints: widget.form == ChoiceListForm.stacked
                ? const BoxConstraints(minHeight: 60)
                : null,
            padding: EdgeInsets.symmetric(
              horizontal: switch (widget.form) {
                null => Gap.md,
                ChoiceListForm.inline => 10,
                ChoiceListForm.stacked => 14,
              },
            ),
            decoration: BoxDecoration(
              color: selected ? colors.accentSoft : colors.surface,
              borderRadius: radius,
              border: _focused
                  ? Border.all(color: colors.accent, width: 2, strokeAlign: 3)
                  : null,
            ),
            child: Row(
              spacing: widget.form == null ? Gap.md : 12,
              children: [
                RadioMark(selected: selected),
                Expanded(
                  child: widget.form == ChoiceListForm.stacked
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          spacing: 2,
                          children: [label, hint(text.labelMedium!)],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          spacing: widget.form == null ? Gap.sm : 12,
                          children: [
                            Flexible(child: label),
                            Flexible(child: hint(text.bodySmall!)),
                          ],
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
