import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';
import 'forge_bottom_sheet.dart';
import 'forge_button.dart';
import 'sign_in_page.dart';
import 'sign_in_provider_buttons.dart';

/// The sheet that asks a guest to keep their data in an account: the
/// [title], a muted [message], Apple and Google as on [SignInPage],
/// [useEmailLabel] as a secondary button and [notNowLabel] as a text
/// button. While a provider is [running] it shows a spinner and every
/// other option is off. Show it with `showForgeBottomSheet`.
class LinkAccountSheet extends StatelessWidget {
  const LinkAccountSheet({
    super.key,
    required this.title,
    required this.message,
    this.apple,
    this.google,
    required this.useEmailLabel,
    required this.onUseEmail,
    required this.notNowLabel,
    required this.onNotNow,
    required this.signingInLabel,
    this.running,
  });

  final String title;
  final String message;
  final SignInProvider? apple;
  final SignInProvider? google;
  final String useEmailLabel;
  final VoidCallback onUseEmail;
  final String notNowLabel;
  final VoidCallback onNotNow;

  /// The running provider button's label.
  final String signingInLabel;
  final SignInOption? running;

  @override
  Widget build(BuildContext context) {
    final idle = running == null;
    return ForgeBottomSheet(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Gap.sm,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.sm),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(color: ForgeStyle.of(context).colors.inkMuted),
            ),
          ),
          if (apple != null || google != null)
            SignInProviderButtons(
              apple: apple,
              google: google,
              signingInLabel: signingInLabel,
              running: running,
            ),
          ForgeButton(
            label: useEmailLabel,
            onPressed: idle ? onUseEmail : null,
            variant: ForgeButtonVariant.secondary,
          ),
          ForgeButton(
            label: notNowLabel,
            onPressed: idle ? onNotNow : null,
            variant: ForgeButtonVariant.text,
          ),
        ],
      ),
    );
  }
}
