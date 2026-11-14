import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import 'card_frame.dart';
import 'forge_button.dart';

/// Asks for a permission and says why, centred: an icon in a circle, a
/// title, one sentence, the main button and an optional text button under
/// it. In a card (the default) it replaces a page's content while the
/// permission is missing; with [page] it is an onboarding step and its main
/// button is the 48px bottom-of-page one.
class PermissionPrompt extends StatelessWidget {
  /// Asks for access; [icon] names what it is for.
  const PermissionPrompt.ask({
    super.key,
    required ForgeIconData this.icon,
    required this.title,
    required this.message,
    required String allowLabel,
    required VoidCallback onAllow,
    this.skipLabel,
    this.onSkip,
    this.page = false,
  }) : _state = _State.ask,
       actionLabel = allowLabel,
       onAction = onAllow;

  /// The user said no: the main button opens the system settings. Give
  /// [askAgainLabel] only where the system can ask a second time.
  const PermissionPrompt.refused({
    super.key,
    required this.title,
    required this.message,
    required String settingsLabel,
    required VoidCallback onOpenSettings,
    String? askAgainLabel,
    VoidCallback? onAskAgain,
    this.page = false,
  }) : _state = _State.refused,
       icon = null,
       actionLabel = settingsLabel,
       onAction = onOpenSettings,
       skipLabel = askAgainLabel,
       onSkip = onAskAgain;

  /// Asking failed: the icon in danger and an outline Retry.
  const PermissionPrompt.failed({
    super.key,
    required this.title,
    required this.message,
    required String retryLabel,
    required VoidCallback onRetry,
    this.page = false,
  }) : _state = _State.failed,
       icon = null,
       actionLabel = retryLabel,
       onAction = onRetry,
       skipLabel = null,
       onSkip = null;

  /// The system app that holds the data is not installed: the main button
  /// opens its store page and ends with open-in-new.
  const PermissionPrompt.missing({
    super.key,
    required this.title,
    required this.message,
    required String getLabel,
    required VoidCallback onGet,
    required String notNowLabel,
    required VoidCallback onNotNow,
    this.page = false,
  }) : _state = _State.missing,
       icon = null,
       actionLabel = getLabel,
       onAction = onGet,
       skipLabel = notNowLabel,
       onSkip = onNotNow;

  final ForgeIconData? icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  /// The text button under the main one.
  final String? skipLabel;
  final VoidCallback? onSkip;
  final bool page;
  final _State _state;

  static const double _circle = 64;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final text = Theme.of(context).textTheme;
    final (icon, iconColor) = switch (_state) {
      _State.ask => (this.icon!, colors.ink),
      _State.refused => (ForgeIcons.block, colors.inkMuted),
      _State.failed => (ForgeIcons.error, colors.danger),
      _State.missing => (ForgeIcons.getApp, colors.ink),
    };
    final skipLabel = this.skipLabel;
    final buttons = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Gap.sm,
      children: [
        ForgeButton(
          label: actionLabel,
          onPressed: onAction,
          variant: _state == _State.failed
              ? ForgeButtonVariant.outline
              : ForgeButtonVariant.primary,
          size: page ? ForgeButtonSize.large : ForgeButtonSize.regular,
          trailingIcon: _state == _State.missing ? ForgeIcons.openInNew : null,
        ),
        if (skipLabel != null)
          ForgeButton(
            label: skipLabel,
            onPressed: onSkip,
            variant: ForgeButtonVariant.text,
          ),
      ],
    );
    final children = [
      Container(
        width: _circle,
        height: _circle,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.surfaceSunken,
        ),
        child: ForgeIcon(icon, size: 32, color: iconColor),
      ),
      Text(
        title,
        textAlign: TextAlign.center,
        style: page
            ? text.titleLarge!.copyWith(fontSize: 24, height: 28 / 24)
            : text.titleLarge,
      ),
      Text(
        message,
        textAlign: TextAlign.center,
        style: page
            ? text.bodyMedium!.copyWith(color: colors.inkMuted)
            : text.bodySmall,
      ),
    ];

    if (page) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: Gap.md,
            children: [
              ...children,
              Padding(
                padding: const EdgeInsets.only(top: Gap.lg),
                child: buttons,
              ),
            ],
          ),
        ),
      );
    }
    return CardFrame(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.md,
          vertical: Gap.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: Gap.sm,
          children: [...children, buttons],
        ),
      ),
    );
  }
}

enum _State { ask, refused, failed, missing }
