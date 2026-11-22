import 'package:material_ui/material_ui.dart';

import '../spacing.dart';
import '../theme/forge_preset.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';
import 'busy_ring.dart';
import 'pressable.dart';
import 'sign_in_page.dart';

/// Apple and Google as 48px buttons, 8px apart, for [SignInPage] and
/// `LinkAccountSheet`. While an option is [running] its button shows a
/// spinner and [signingInLabel], and the other is off.
class SignInProviderButtons extends StatelessWidget {
  const SignInProviderButtons({
    super.key,
    this.apple,
    this.google,
    required this.signingInLabel,
    this.running,
  });

  final SignInProvider? apple;
  final SignInProvider? google;
  final String signingInLabel;
  final SignInOption? running;

  @override
  Widget build(BuildContext context) {
    Widget button(SignInProvider provider, SignInOption option) =>
        _ProviderButton(
          provider: provider,
          filled: option == SignInOption.apple,
          running: running == option,
          enabled: running == null,
          runningLabel: signingInLabel,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Gap.sm,
      children: [
        if (apple case final apple?) button(apple, SignInOption.apple),
        if (google case final google?) button(google, SignInOption.google),
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.provider,
    required this.filled,
    required this.running,
    required this.enabled,
    required this.runningLabel,
  });

  final SignInProvider provider;

  /// Ink-filled (Apple); otherwise surface in a line outline (Google).
  final bool filled;
  final bool running;
  final bool enabled;
  final String runningLabel;

  static const double _mark = 18;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    // Off while another option runs: the Button card's disabled look, a
    // sunken fill and a line-strong label.
    final off = !enabled && !running;
    final ink = off
        ? colors.lineStrong
        : filled
        ? colors.surface
        : colors.ink;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Pressable(
        onTap: enabled ? provider.onPressed : null,
        height: ForgeTheme.buttonHeightLg,
        builder: (context, _) => Container(
          height: ForgeTheme.buttonHeightLg,
          padding: const EdgeInsets.symmetric(horizontal: Gap.md),
          decoration: BoxDecoration(
            color: off
                ? colors.surfaceSunken
                : filled
                ? colors.ink
                : colors.surface,
            borderRadius: const BorderRadius.all(
              Radius.circular(ForgeRadii.button),
            ),
            border: off || filled ? null : Border.all(color: colors.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: Gap.sm,
            children: [
              if (running)
                BusyRing(size: 16, stroke: 2, sweep: 0.75, color: ink)
              else
                SizedBox.square(
                  dimension: _mark,
                  // A one-colour mark (Apple's) takes the label's colour.
                  child: IconTheme.merge(
                    data: IconThemeData(color: ink),
                    child: FittedBox(child: provider.mark),
                  ),
                ),
              Flexible(
                child: Text(
                  running ? runningLabel : provider.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style.buttonLg.copyWith(color: ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
