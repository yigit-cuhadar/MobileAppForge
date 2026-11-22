import 'dart:ui' show SemanticsRole;

import 'package:material_ui/material_ui.dart';

import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import 'card_frame.dart';
import 'forge_button.dart';
import 'forge_icon_button.dart';
import 'forge_tag.dart';
import 'radio_mark.dart';

/// One answer of a [ChoiceGrid].
class ChoiceOption {
  const ChoiceOption({
    required this.label,
    this.hint,
    this.tag,
    this.enabled = true,
    this.onInfo,
    this.infoLabel,
    this.picture,
  }) : assert(
         (onInfo == null) == (infoLabel == null),
         'Give the info button a label and an action together.',
       );

  final String label;

  /// Without a hint the row shows its label alone, vertically centred.
  final String? hint;

  /// A tag right after the label, such as the option the app recommends.
  final ForgeTag? tag;

  /// A disabled row fades to 40%, takes no taps and reads as disabled.
  final bool enabled;

  /// Shows a muted info button at the row's end; the app opens what the
  /// option holds. A tap elsewhere on the row still picks it.
  final VoidCallback? onInfo;

  /// What screen readers call the info button ("Details of [OPTION]").
  final String? infoLabel;

  /// What the option looks like, on top of its [ChoiceGrid.pictures] tile:
  /// an image, a live view, any widget. The tile sets its size; screen
  /// readers hear the label instead.
  final Widget? picture;
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
       form = null,
       _pictures = false;

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
       skipLabel = null,
       _pictures = false;

  /// The options alone as tiles, two to a row: each option's
  /// [ChoiceOption.picture] at 9:16 on top, the radio, label and hint under
  /// it. A tap anywhere on a tile picks it; the chosen tile sits on
  /// accent-soft. Every option needs a picture; tiles show no tag or info
  /// button.
  const ChoiceGrid.pictures({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  }) : title = null,
       detail = null,
       onSkip = null,
       skipLabel = null,
       form = null,
       _pictures = true;

  final String? title;
  final String? detail;
  final List<ChoiceOption> options;

  /// The chosen option's index, or null.
  final int? selected;
  final ValueChanged<int> onSelected;
  final VoidCallback? onSkip;
  final String? skipLabel;

  /// The list form's rows; null on the card and the tiles.
  final ChoiceListForm? form;

  final bool _pictures;

  Widget _tiles() {
    assert(
      options.every(
        (o) => o.picture != null && o.tag == null && o.onInfo == null,
      ),
      'Picture tiles need a picture and show no tag or info button.',
    );
    Widget tile(int i) => _ChoiceTile(
      option: options[i],
      selected: i == selected,
      onTap: options[i].enabled ? () => onSelected(i) : null,
    );
    return Semantics(
      container: true,
      role: SemanticsRole.radioGroup,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Gap.sm,
        children: [
          for (var i = 0; i < options.length; i += 2)
            // Tiles of a row share the taller one's height.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Gap.sm,
                children: [
                  Expanded(child: tile(i)),
                  Expanded(
                    child: i + 1 < options.length
                        ? tile(i + 1)
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pictures) return _tiles();
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
              onTap: options[i].enabled ? () => onSelected(i) : null,
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

/// One radio of the group: its semantics, focus, Enter and tap, faded when
/// disabled ([onTap] null). [builder] draws it, ringed while [focused].
class _Choice extends StatefulWidget {
  const _Choice({
    required this.selected,
    required this.onTap,
    required this.builder,
  });

  final bool selected;
  final VoidCallback? onTap;
  final Widget Function(bool focused) builder;

  @override
  State<_Choice> createState() => _ChoiceState();
}

class _ChoiceState extends State<_Choice> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: widget.selected,
      enabled: onTap != null,
      child: FocusableActionDetector(
        enabled: onTap != null,
        onShowFocusHighlight: (focused) => setState(() => _focused = focused),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => onTap?.call(),
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? 0.4 : 1,
            child: widget.builder(_focused),
          ),
        ),
      ),
    );
  }
}

/// The 2px accent ring of a focused choice, drawn outside its edge.
Border _focusRing(ForgeStyle style) =>
    Border.all(color: style.colors.accent, width: 2, strokeAlign: 3);

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.option,
    required this.form,
    required this.selected,
    required this.onTap,
  });

  final ChoiceOption option;
  final ChoiceListForm? form;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(style.radii.md);
    final labelText = Text(
      option.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: text.titleMedium!.copyWith(
        color: selected ? colors.onAccentSoft : colors.ink,
      ),
    );
    final tag = option.tag;
    final label = tag == null
        ? labelText
        // The tag moves under the label when they do not fit side by side.
        : Wrap(
            spacing: Gap.sm,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [labelText, tag],
          );
    final hintText = option.hint;
    Widget hint(String hint, TextStyle role) => Text(
      hint,
      maxLines: form == ChoiceListForm.stacked ? null : 1,
      overflow: form == ChoiceListForm.stacked ? null : TextOverflow.ellipsis,
      style: role.copyWith(fontWeight: FontWeight.w400, color: colors.inkMuted),
    );
    final info = option.onInfo;
    final start = switch (form) {
      null => Gap.md,
      ChoiceListForm.inline => 10.0,
      ChoiceListForm.stacked => 14.0,
    };
    return _Choice(
      selected: selected,
      onTap: onTap,
      builder: (focused) => Container(
        height: switch (form) {
          null => 56,
          ChoiceListForm.inline => 44,
          ChoiceListForm.stacked => null,
        },
        constraints: form == ChoiceListForm.stacked
            ? const BoxConstraints(minHeight: 60)
            : null,
        padding: EdgeInsetsDirectional.only(
          start: start,
          end: info == null ? start : Gap.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.accentSoft : colors.surface,
          borderRadius: radius,
          border: focused ? _focusRing(style) : null,
        ),
        child: Row(
          spacing: form == null ? Gap.md : 12,
          children: [
            RadioMark(selected: selected),
            Expanded(
              child: switch ((hintText, form)) {
                (null, _) => label,
                (final hintText?, ChoiceListForm.stacked) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 2,
                  children: [label, hint(hintText, text.labelMedium!)],
                ),
                (final hintText?, _) => Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  spacing: form == null ? Gap.sm : 12,
                  children: [
                    Flexible(child: label),
                    Flexible(child: hint(hintText, text.bodySmall!)),
                  ],
                ),
              },
            ),
            if (info != null)
              ForgeIconButton(
                icon: ForgeIcons.info,
                label: option.infoLabel!,
                onPressed: info,
              ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ChoiceOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(style.radii.lg);
    final hint = option.hint;
    return _Choice(
      selected: selected,
      onTap: onTap,
      builder: (focused) => Container(
        decoration: BoxDecoration(
          color: selected ? colors.accentSoft : colors.surface,
          borderRadius: radius,
        ),
        // Over the picture, so it cannot cover the edge.
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: focused
              ? _focusRing(style)
              : style.cardBorder == 0
              ? null
              : Border.all(color: colors.line, width: style.cardBorder),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 9 / 16,
                child: Padding(
                  padding: const EdgeInsets.only(top: Gap.md),
                  child: ExcludeSemantics(child: option.picture),
                ),
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: Gap.sm,
                  ),
                  child: Row(
                    spacing: 12,
                    children: [
                      RadioMark(selected: selected),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          spacing: 2,
                          children: [
                            Text(
                              option.label,
                              style: text.titleMedium!.copyWith(
                                color: selected
                                    ? colors.onAccentSoft
                                    : colors.ink,
                              ),
                            ),
                            if (hint != null)
                              Text(
                                hint,
                                style: text.labelMedium!.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: colors.inkMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
