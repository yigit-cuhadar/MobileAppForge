import 'dart:async';

import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_preset.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';

/// Shows a [ForgeSnackbar] for 4 s, with an action too: at the bottom of
/// the nearest Scaffold, or over the sheet or dialog that [context] is in.
/// Its action hides it before [onAction] runs.
void showForgeSnackbar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  bool error = false,
}) {
  ForgeSnackbar snackbar(VoidCallback hide) => ForgeSnackbar(
    message: message,
    actionLabel: actionLabel,
    onAction: onAction == null
        ? null
        : () {
            hide();
            onAction();
          },
    error: error,
  );
  // A Scaffold's snackbar would draw under a sheet or dialog.
  if (ModalRoute.of(context) is PopupRoute) {
    _OverSheet.show(context, snackbar(_OverSheet.hide));
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.md),
      content: snackbar(messenger.hideCurrentSnackBar),
    ),
  );
}

/// The one snackbar shown over a sheet or dialog, placed as a Scaffold's:
/// 16px from the sides and above the bottom inset and the keyboard.
abstract final class _OverSheet {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(BuildContext context, ForgeSnackbar snackbar) {
    hide();
    final entry = OverlayEntry(
      builder: (context) {
        final media = MediaQuery.of(context);
        return Positioned(
          left: Gap.md,
          right: Gap.md,
          bottom: Gap.md + media.viewInsets.bottom + media.padding.bottom,
          child: Material(
            type: MaterialType.transparency,
            child: Semantics(liveRegion: true, child: snackbar),
          ),
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    _entry = entry;
    _timer = Timer(const Duration(seconds: 4), hide);
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry
      ?..remove()
      ..dispose();
    _entry = null;
  }
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
