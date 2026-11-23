import 'package:material_ui/material_ui.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_palette.dart';
import '../theme/forge_style.dart';
import 'card_frame.dart';
import 'forge_button.dart';
import 'forge_dialog.dart';

/// Asks for a permission and says why, centred: an icon in a circle, a
/// title, one sentence, the main button and an optional text button under
/// it; when the device lacks what is asked for, one secondary button. An
/// ask may end in a muted [note] under its buttons. In a card (the
/// default) it replaces a page's content while the
/// permission is missing; with [page] it is an onboarding step and its main
/// button is the 48px bottom-of-page one. [PermissionPrompt.consent] asks
/// for consent with two equal buttons, and [PermissionPrompt.dialog] asks
/// at the moment an action needs the permission.
class PermissionPrompt extends StatelessWidget {
  /// Asks for access; [icon] names what it is for. Set [asking] while
  /// the system's prompt is awaited.
  const PermissionPrompt.ask({
    super.key,
    required ForgeIconData this.icon,
    required this.title,
    required this.message,
    required String allowLabel,
    required VoidCallback onAllow,
    this.skipLabel,
    this.onSkip,
    this.note,
    this.page = false,
    this.asking = false,
  }) : _state = _State.ask,
       actionLabel = allowLabel,
       onAction = onAllow;

  /// Asks for consent, such as to share usage data: [allowLabel] and
  /// [declineLabel] are equal secondary buttons, Allow on top, so neither
  /// answer is pushed.
  const PermissionPrompt.consent({
    super.key,
    required ForgeIconData this.icon,
    required this.title,
    required this.message,
    required String allowLabel,
    required VoidCallback onAllow,
    required String declineLabel,
    required VoidCallback onDecline,
    this.page = false,
  }) : _state = _State.consent,
       asking = false,
       note = null,
       actionLabel = allowLabel,
       onAction = onAllow,
       skipLabel = declineLabel,
       onSkip = onDecline;

  /// A dialog over the page, shown with [showForgeDialog] when an action
  /// needs the permission: [icon] muted in a 44px circle, the title, one
  /// sentence, a full-width [allowLabel] and a text [notNowLabel] under it.
  /// The app closes the dialog in [onAllow] and [onNotNow].
  const PermissionPrompt.dialog({
    super.key,
    required ForgeIconData this.icon,
    required this.title,
    required this.message,
    required String allowLabel,
    required VoidCallback onAllow,
    required String notNowLabel,
    required VoidCallback onNotNow,
  }) : _state = _State.dialog,
       asking = false,
       note = null,
       page = false,
       actionLabel = allowLabel,
       onAction = onAllow,
       skipLabel = notNowLabel,
       onSkip = onNotNow;

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
       asking = false,
       note = null,
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
       asking = false,
       note = null,
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
       asking = false,
       note = null,
       icon = null,
       actionLabel = getLabel,
       onAction = onGet,
       skipLabel = notNowLabel,
       onSkip = onNotNow;

  /// The device lacks what the permission is for (no camera, say): [icon]
  /// muted, no way to ask, and a secondary button to go on without it
  /// unless the page around it already offers one.
  const PermissionPrompt.unavailable({
    super.key,
    required ForgeIconData this.icon,
    required this.title,
    required this.message,
    String? skipLabel,
    VoidCallback? onSkip,
    this.page = false,
  }) : assert((skipLabel == null) == (onSkip == null)),
       _state = _State.unavailable,
       asking = false,
       note = null,
       actionLabel = skipLabel,
       onAction = onSkip,
       skipLabel = null,
       onSkip = null;

  final ForgeIconData? icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// The text button under the main one.
  final String? skipLabel;
  final VoidCallback? onSkip;

  /// A muted line under the buttons, such as where to turn access back on.
  final String? note;
  final bool page;

  /// The system's own prompt is on its way: the main button spins and
  /// neither button takes a tap, so a slow prompt is not asked for twice.
  final bool asking;
  final _State _state;

  static const double _circle = 64;
  static const double _dialogCircle = 44;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final text = Theme.of(context).textTheme;
    if (_state == _State.dialog) return _dialog(colors, text);
    final (icon, iconColor) = switch (_state) {
      _State.ask || _State.consent || _State.dialog => (this.icon!, colors.ink),
      _State.refused => (ForgeIcons.block, colors.inkMuted),
      _State.failed => (ForgeIcons.error, colors.danger),
      _State.missing => (ForgeIcons.getApp, colors.ink),
      _State.unavailable => (this.icon!, colors.inkMuted),
    };
    final skipLabel = this.skipLabel;
    final buttons = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Gap.sm,
      children: [
        if (actionLabel case final actionLabel?)
          ForgeButton(
            label: actionLabel,
            onPressed: onAction,
            loading: asking,
            variant: switch (_state) {
              _State.failed => ForgeButtonVariant.outline,
              _State.unavailable ||
              _State.consent => ForgeButtonVariant.secondary,
              _ => ForgeButtonVariant.primary,
            },
            size: page ? ForgeButtonSize.large : ForgeButtonSize.regular,
            trailingIcon: _state == _State.missing
                ? ForgeIcons.openInNew
                : null,
          ),
        if (skipLabel != null)
          _state == _State.consent
              ? ForgeButton(
                  label: skipLabel,
                  onPressed: onSkip,
                  variant: ForgeButtonVariant.secondary,
                  size: page ? ForgeButtonSize.large : ForgeButtonSize.regular,
                )
              : ForgeButton(
                  label: skipLabel,
                  onPressed: asking ? null : onSkip,
                  variant: ForgeButtonVariant.text,
                ),
        if (note case final note?)
          Text(
            note,
            textAlign: TextAlign.center,
            style: text.labelMedium!.copyWith(
              color: colors.inkMuted,
              fontWeight: FontWeight.w400,
            ),
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
      // The text centred in the room above the buttons, which sit at the
      // page's foot; on a short page everything scrolls together.
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Gap.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: Gap.md,
                          children: children,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(Gap.md),
                    child: buttons,
                  ),
                ],
              ),
            ),
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

  Widget _dialog(ForgePalette colors, TextTheme text) => Dialog(
    insetPadding: const EdgeInsets.all(Gap.md),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: ForgeDialog.maxWidth),
      child: Semantics(
        namesRoute: true,
        scopesRoute: true,
        explicitChildNodes: true,
        label: title,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Gap.sm,
            children: [
              Center(
                child: Container(
                  width: _dialogCircle,
                  height: _dialogCircle,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surfaceSunken,
                  ),
                  child: ForgeIcon(icon!, size: 22, color: colors.inkMuted),
                ),
              ),
              Text(title, textAlign: TextAlign.center, style: text.titleLarge),
              Text(message, textAlign: TextAlign.center, style: text.bodySmall),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: ForgeButton(label: actionLabel!, onPressed: onAction),
              ),
              ForgeButton(
                label: skipLabel!,
                onPressed: onSkip,
                variant: ForgeButtonVariant.text,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

enum _State { ask, consent, dialog, refused, failed, missing, unavailable }
