import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_palette.dart';
import '../theme/forge_preset.dart';
import '../theme/forge_style.dart';
import 'pressable.dart';

/// An outlined 36px chip: an action, or a filter that is [selected] (with a
/// check unless [showCheck] is false, or a [count] badge in its place). A
/// [locked] chip shows a lock before the label and stays tappable:
/// [onPressed] then opens the paywall. The chip takes taps across a 44px
/// band; [ForgeChip.series] is the small form for a chart's series. A
/// chip with [onOptions] opens its item's options.
class ForgeChip extends StatelessWidget {
  const ForgeChip({
    super.key,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.showCheck = true,
    this.count,
    this.locked = false,
    this.leading,
    this.onOptions,
    this.optionsLabel,
  }) : assert(
         (onOptions == null) == (optionsLabel == null),
         'Name the options for screen readers.',
       ),
       sample = null,
       removeHint = null,
       _menu = false;

  /// An unset filter that opens a menu or sheet of its values: the filter's
  /// name with a ▾ after it.
  const ForgeChip.menu({
    super.key,
    required this.label,
    required this.onPressed,
  }) : selected = false,
       showCheck = false,
       count = null,
       locked = false,
       leading = null,
       onOptions = null,
       optionsLabel = null,
       sample = null,
       removeHint = null,
       _menu = true;

  /// A small 28px chip for a chart series: the series' [sample] (a short
  /// line in its colour, or an icon) before the label, no check.
  const ForgeChip.series({
    super.key,
    required this.label,
    required Widget this.sample,
    required this.onPressed,
    this.selected = false,
  }) : count = null,
       locked = false,
       showCheck = false,
       leading = null,
       onOptions = null,
       optionsLabel = null,
       removeHint = null,
       _menu = false;

  /// An active filter above a list: the chosen look with a close icon on
  /// the right; tapping it calls [onRemoved]. Screen readers announce
  /// [removeHint] ("Removes the filter").
  const ForgeChip.removable({
    super.key,
    required this.label,
    required VoidCallback onRemoved,
    required String this.removeHint,
  }) : onPressed = onRemoved,
       selected = true,
       showCheck = false,
       count = null,
       locked = false,
       leading = null,
       onOptions = null,
       optionsLabel = null,
       sample = null,
       _menu = false;

  final String label;
  final VoidCallback onPressed;
  final bool selected;

  /// False for a selected chip marked by its fill and border alone.
  final bool showCheck;
  final int? count;
  final bool locked;

  /// An icon before the label, 14px in the label's ink unless it sets its
  /// own (an add icon, a danger alert).
  final Widget? leading;

  /// Opens the item's options (a menu): a long press, and while [selected]
  /// a tap on the chip or on the ⋯ it then shows at its end.
  final VoidCallback? onOptions;

  /// What screen readers call the options ("Item options").
  final String? optionsLabel;

  bool get _options => selected && onOptions != null;
  final Widget? sample;
  final String? removeHint;
  final bool _menu;

  bool get _removable => removeHint != null;

  static const double height = 36;
  static const double seriesHeight = 28;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final p = style.colors;
    final text = Theme.of(context).textTheme;
    final sample = this.sample;
    if (sample != null) {
      final ink = selected ? p.onAccentSoft : p.inkMuted;
      return _frame(
        p,
        height: seriesHeight,
        padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
        child: IconTheme.merge(
          data: IconThemeData(color: ink),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: Gap.sm,
            children: [
              sample,
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium!.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final ink = selected ? p.onAccentSoft : p.ink;
    return _frame(
      p,
      height: height,
      padding: EdgeInsets.only(
        left: Gap.md,
        right: _removable || _menu || _options ? Gap.sm : Gap.md,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: _menu ? Gap.xs : Gap.sm,
        children: [
          if (locked) ForgeIcon(ForgeIcons.lock, size: 14, color: ink),
          if (leading case final leading?)
            IconTheme.merge(
              data: IconThemeData(size: 14, color: ink),
              child: leading,
            ),
          if (selected && showCheck && count == null)
            ForgeIcon(ForgeIcons.check, size: 14, weight: 3, color: ink),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall!.copyWith(
                color: ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (count != null)
            Container(
              constraints: const BoxConstraints(minWidth: 18),
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.accent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '$count',
                style: style.data.copyWith(
                  fontSize: 11,
                  height: 1,
                  color: p.onAccent,
                ),
              ),
            ),
          if (_removable) ForgeIcon(ForgeIcons.close, size: 14, color: ink),
          if (_menu) ForgeIcon(ForgeIcons.expandMore, size: 16, color: ink),
          if (_options)
            Semantics(
              container: true,
              button: true,
              label: optionsLabel,
              onTap: onOptions,
              child: ForgeIcon(ForgeIcons.moreHoriz, size: 16, color: ink),
            ),
        ],
      ),
    );
  }

  Widget _frame(
    ForgePalette p, {
    required double height,
    required EdgeInsets padding,
    required Widget child,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      hint: removeHint,
      customSemanticsActions: onOptions == null
          ? null
          : {CustomSemanticsAction(label: optionsLabel!): onOptions!},
      child: Pressable(
        onTap: _options ? onOptions : onPressed,
        onLongPress: onOptions,
        height: height,
        builder: (context, _) => Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: selected ? p.accentSoft : p.surface,
            borderRadius: const BorderRadius.all(
              Radius.circular(ForgeRadii.button),
            ),
            border: selected
                ? Border.all(color: p.accent, width: 1.5)
                : Border.all(color: p.lineStrong),
          ),
          child: child,
        ),
      ),
    );
  }
}
