import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';
import 'card_frame.dart';
import 'forge_button.dart';

/// One answer of a [ChoiceGrid].
class ChoiceOption {
  const ChoiceOption({required this.label, required this.hint});

  final String label;
  final String hint;
}

/// A question on a card: the [title], its [detail], and a single column of
/// [options], each a 56px row with a radio, the label and its hint. The
/// [selected] row sits on accent-soft; keyboard focus is a 2px accent ring.
/// With [onSkip] the header carries a Skip text button.
class ChoiceGrid extends StatelessWidget {
  const ChoiceGrid({
    super.key,
    required this.title,
    required this.detail,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.onSkip,
    this.skipLabel = 'Skip',
  });

  final String title;
  final String detail;
  final List<ChoiceOption> options;

  /// The chosen option's index, or null.
  final int? selected;
  final ValueChanged<int> onSelected;
  final VoidCallback? onSkip;
  final String skipLabel;

  @override
  Widget build(BuildContext context) {
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
                        detail,
                        style: text.labelMedium!.copyWith(
                          fontWeight: FontWeight.w400,
                          color: style.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onSkip != null)
                  ForgeButton(
                    label: skipLabel,
                    onPressed: onSkip,
                    variant: ForgeButtonVariant.text,
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Gap.xs,
              children: [
                for (var i = 0; i < options.length; i++)
                  _ChoiceRow(
                    option: options[i],
                    selected: i == selected,
                    onTap: () => onSelected(i),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatefulWidget {
  const _ChoiceRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ChoiceOption option;
  final bool selected;
  final VoidCallback onTap;

  static const double height = 56;
  static const double radio = 20;
  static const double dot = 10;

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
            height: _ChoiceRow.height,
            padding: const EdgeInsets.symmetric(horizontal: Gap.md),
            decoration: BoxDecoration(
              color: selected ? colors.accentSoft : colors.surface,
              borderRadius: radius,
              border: _focused
                  ? Border.all(color: colors.accent, width: 2, strokeAlign: 3)
                  : null,
            ),
            child: Row(
              spacing: Gap.md,
              children: [
                Container(
                  width: _ChoiceRow.radio,
                  height: _ChoiceRow.radio,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(style.radii.sm),
                    border: Border.all(
                      color: selected ? colors.accent : colors.lineStrong,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Container(
                          width: _ChoiceRow.dot,
                          height: _ChoiceRow.dot,
                          decoration: BoxDecoration(
                            color: colors.accent,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    spacing: Gap.sm,
                    children: [
                      Flexible(
                        child: Text(
                          widget.option.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium!.copyWith(
                            color: selected ? colors.onAccentSoft : colors.ink,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          widget.option.hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall!.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                      ),
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
