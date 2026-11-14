import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_preset.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';

/// Shows a [ForgeSnackbar] at the bottom of the nearest Scaffold for 4 s,
/// with an action too. Its action hides it before [onAction] runs.
void showForgeSnackbar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  bool error = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.md),
      content: ForgeSnackbar(
        message: message,
        actionLabel: actionLabel,
        onAction: onAction == null
            ? null
            : () {
                messenger.hideCurrentSnackBar();
                onAction();
              },
        error: error,
      ),
    ),
  );
}

/// The inverse strip: a message, an optional action ("Undo", "Retry") and,
/// for an error, a danger-tinted icon.
class ForgeSnackbar extends StatelessWidget {
  const ForgeSnackbar({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.error = false,
  }) : assert((actionLabel == null) == (onAction == null));

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final theme = Theme.of(context);
    final actionLabel = this.actionLabel;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.xs, Gap.sm, Gap.xs),
      decoration: BoxDecoration(
        color: colors.ink,
        borderRadius: BorderRadius.circular(ForgeRadii.button),
      ),
      child: Row(
        spacing: Gap.sm,
        children: [
          if (error)
            ForgeIcon(
              ForgeIcons.error,
              size: 18,
              color: Color.lerp(colors.ground, colors.danger, 0.55),
            ),
          Expanded(
            child: Text(message, style: theme.snackBarTheme.contentTextStyle),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: colors.ground,
                minimumSize: const Size(48, ForgeTheme.buttonHeight),
              ),
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}
