import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';

/// Shows a [ForgeBottomSheet] over a scrim on the root navigator, so it
/// covers a shell's tab bar; a swipe down or a tap on the scrim closes it.
/// Widgets inside it do not see providers placed below the root navigator.
Future<T?> showForgeBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  useRootNavigator: true,
  builder: builder,
);

/// A sheet: grabber, title on the left with an optional muted [subtitle]
/// 2px under it and one optional text action right of them, the content, and the sheet's main action at the bottom. A choice
/// sheet has no main action: a tap on a row chooses and closes it.
class ForgeBottomSheet extends StatelessWidget {
  const ForgeBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.headerAction,
    required this.child,
    this.action,
  });

  final String title;
  final String? subtitle;

  /// A text action such as "Clear all", or a danger one such as "Remove"
  /// ([ForgeButtonVariant.dangerText]).
  final Widget? headerAction;
  final Widget child;

  /// The sheet's main action, full width.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Gap.md,
        Gap.sm,
        Gap.md,
        Gap.lg + media.viewInsets.bottom + media.padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Gap.md,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.lineStrong.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: ForgeTheme.tapMin),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (subtitle case final subtitle?)
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (headerAction case final headerAction?)
                  Transform.translate(
                    // Aligns the action's label with the content's edge.
                    offset: Offset(
                      Directionality.of(context) == TextDirection.rtl
                          ? -Gap.sm
                          : Gap.sm,
                      0,
                    ),
                    child: headerAction,
                  ),
              ],
            ),
          ),
          Flexible(child: child),
          ?action,
        ],
      ),
    );
  }
}
