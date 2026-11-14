import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';

/// The bar fixed at a page's bottom, padded to the device's bottom inset;
/// content scrolls under it. Its buttons are the 48px bottom-of-page size.
class ForgeBottomActionBar extends StatelessWidget {
  /// One full-width action.
  const ForgeBottomActionBar({super.key, required Widget this.primary})
    : secondary = null,
      _layout = _Layout.one,
      count = null,
      none = false;

  /// The secondary action left, the primary twice as wide right of it.
  const ForgeBottomActionBar.sideBySide({
    super.key,
    required Widget this.secondary,
    required Widget this.primary,
  }) : _layout = _Layout.sideBySide,
       count = null,
       none = false;

  /// The primary action on top, the secondary under it.
  const ForgeBottomActionBar.stacked({
    super.key,
    required Widget this.primary,
    required Widget this.secondary,
  }) : _layout = _Layout.stacked,
       count = null,
       none = false;

  /// A picker's count on the left ("3 chosen") and one action right. With
  /// [none] the count reads in ink-muted ("None chosen"); the app turns the
  /// action off.
  const ForgeBottomActionBar.count({
    super.key,
    required String this.count,
    required Widget action,
    this.none = false,
  }) : primary = action,
       secondary = null,
       _layout = _Layout.count;

  final Widget? primary;
  final Widget? secondary;
  final String? count;
  final bool none;
  final _Layout _layout;

  /// The action's narrowest width beside a count.
  static const double _countActionWidth = 120;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final primary = this.primary!;
    final content = switch (_layout) {
      _Layout.one => SizedBox(width: double.infinity, child: primary),
      _Layout.sideBySide => Row(
        spacing: Gap.sm,
        children: [
          Expanded(child: secondary!),
          Expanded(flex: 2, child: primary),
        ],
      ),
      _Layout.stacked => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Gap.sm,
        children: [primary, secondary!],
      ),
      _Layout.count => Row(
        spacing: Gap.md,
        children: [
          Expanded(
            child: Text(
              count!,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: none ? FontWeight.w400 : FontWeight.w600,
                color: none ? colors.inkMuted : colors.ink,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: _countActionWidth),
            child: primary,
          ),
        ],
      ),
    };
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: const EdgeInsets.all(Gap.md), child: content),
      ),
    );
  }
}

enum _Layout { one, sideBySide, stacked, count }
