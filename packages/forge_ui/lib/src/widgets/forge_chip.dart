import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_palette.dart';
import '../theme/forge_preset.dart';
import '../theme/forge_style.dart';
import 'pressable.dart';

/// An outlined 36px chip: an action, or a filter that is [selected] (with a
/// check, or a [count] badge in its place). A [locked] chip shows a lock
/// before the label and stays tappable: [onPressed] then opens the paywall.
/// The chip takes taps across a 44px band; [ForgeChip.series] is the
/// small form for a chart's series.
class ForgeChip extends StatelessWidget {
  const ForgeChip({
    super.key,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.count,
    this.locked = false,
  }) : sample = null,
       _removable = false;

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
       _removable = false;

  /// An active filter above a list: the chosen look with a close icon on
  /// the right; tapping it calls [onRemoved].
  const ForgeChip.removable({
    super.key,
    required this.label,
    required VoidCallback onRemoved,
  }) : onPressed = onRemoved,
       selected = true,
       count = null,
       locked = false,
       sample = null,
       _removable = true;

  final String label;
  final VoidCallback onPressed;
  final bool selected;
  final int? count;
  final bool locked;
  final Widget? sample;
  final bool _removable;

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
              Text(
                label,
                maxLines: 1,
                style: text.labelMedium!.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w600,
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
        right: _removable ? Gap.sm : Gap.md,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: Gap.sm,
        children: [
          if (locked) ForgeIcon(ForgeIcons.lock, size: 14, color: ink),
          if (selected && count == null && !_removable)
            ForgeIcon(ForgeIcons.check, size: 14, weight: 3, color: ink),
          Text(
            label,
            maxLines: 1,
            style: text.bodySmall!.copyWith(
              color: ink,
              fontWeight: FontWeight.w500,
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
      child: Pressable(
        onTap: onPressed,
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
