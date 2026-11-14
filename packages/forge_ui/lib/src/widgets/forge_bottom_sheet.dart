import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';

/// Shows a [ForgeBottomSheet] over a scrim; a swipe down or a tap on the
/// scrim closes it.
Future<T?> showForgeBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: builder,
);

/// A sheet: grabber, title on the left with one optional text action right
/// of it, the content, and the sheet's main action at the bottom. A choice
/// sheet has no main action: a tap on a row chooses and closes it.
class ForgeBottomSheet extends StatelessWidget {
  const ForgeBottomSheet({
    super.key,
    required this.title,
    this.headerAction,
    required this.child,
    this.action,
  });

  final String title;

  /// A text action such as "Clear all".
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
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                if (headerAction case final headerAction?)
                  Transform.translate(
                    // Aligns the action's label with the content's edge.
                    offset: const Offset(Gap.sm, 0),
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
