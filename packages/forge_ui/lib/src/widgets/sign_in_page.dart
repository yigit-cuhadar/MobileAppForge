import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_preset.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';
import 'busy_ring.dart';
import 'forge_button.dart';
import 'forge_dialog.dart';
import 'forge_text_field.dart';
import 'pressable.dart';

/// A sign-in provider's button: the provider's own [mark] (drawn by the
/// caller, 18px), its [label] and what a tap starts.
class SignInProvider {
  const SignInProvider({
    required this.mark,
    required this.label,
    required this.onPressed,
  });

  final Widget mark;
  final String label;
  final VoidCallback onPressed;
}

/// A sign-in option that can be running on [SignInPage].
enum SignInOption { apple, google, guest }

/// The sign-in page: a featured block with the app's [mark], [name] and
/// [tagline]; under it Apple and Google as 48px buttons, [useEmailLabel]
/// (the email form is [SignInEmailPage]), a guest link and the [terms].
/// While an option is [running] it shows a spinner and every other option
/// is off.
class SignInPage extends StatelessWidget {
  const SignInPage({
    super.key,
    required this.mark,
    required this.name,
    required this.tagline,
    this.apple,
    this.google,
    required this.useEmailLabel,
    required this.onUseEmail,
    required this.guestLabel,
    required this.onGuest,
    required this.terms,
    required this.signingInLabel,
    this.running,
  });

  /// Drawn in featured on a 52px on-featured tile.
  final Widget mark;
  final String name;
  final String tagline;
  final SignInProvider? apple;
  final SignInProvider? google;
  final String useEmailLabel;
  final VoidCallback onUseEmail;
  final String guestLabel;
  final VoidCallback onGuest;
  final String terms;

  /// The running provider button's label.
  final String signingInLabel;
  final SignInOption? running;

  static const double _tile = 52;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final idle = running == null;

    final block = Container(
      margin: const EdgeInsets.all(Gap.sm),
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: colors.featured,
        borderRadius: BorderRadius.circular(style.radii.lg),
        border: Border.all(
          color: colors.featuredBorder,
          width: ForgeStyle.featuredBorder,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.sm,
        children: [
          Container(
            width: _tile,
            height: _tile,
            margin: const EdgeInsets.only(bottom: Gap.sm),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.onFeatured,
              borderRadius: BorderRadius.circular(style.radii.md),
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: colors.featured),
              child: DefaultTextStyle.merge(
                style: text.titleLarge!.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.featured,
                ),
                child: mark,
              ),
            ),
          ),
          Text(
            name,
            style: text.headlineMedium!.copyWith(
              fontSize: 28,
              height: 32 / 28,
              letterSpacing: -0.56,
              color: colors.onFeatured,
            ),
          ),
          Text(
            tagline,
            style: text.bodyLarge!.copyWith(
              color: colors.onFeatured.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );

    Widget provider(SignInProvider provider, SignInOption option) =>
        _ProviderButton(
          provider: provider,
          filled: option == SignInOption.apple,
          running: running == option,
          enabled: idle,
          runningLabel: signingInLabel,
        );

    final options = Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Gap.sm,
        children: [
          if (apple case final apple?) provider(apple, SignInOption.apple),
          if (google case final google?) provider(google, SignInOption.google),
          ForgeButton(
            label: useEmailLabel,
            onPressed: idle ? onUseEmail : null,
            variant: ForgeButtonVariant.secondary,
          ),
          Center(
            child: ForgeButton(
              label: guestLabel,
              onPressed: idle || running == SignInOption.guest ? onGuest : null,
              loading: running == SignInOption.guest,
              variant: ForgeButtonVariant.text,
            ),
          ),
          Text(
            terms,
            textAlign: TextAlign.center,
            style: text.labelSmall!.copyWith(
              height: 15 / 11,
              fontWeight: FontWeight.w400,
              color: colors.inkMuted,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: block),
                  options,
                ],
              ),
            ),
          ],
        ),
      ),
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
    final ink = filled ? colors.surface : colors.ink;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Pressable(
        onTap: enabled ? provider.onPressed : null,
        height: ForgeTheme.buttonHeightLg,
        builder: (context, _) => Opacity(
          opacity: running
              ? 0.85
              : enabled
              ? 1
              : 0.4,
          child: Container(
            height: ForgeTheme.buttonHeightLg,
            padding: const EdgeInsets.symmetric(horizontal: Gap.md),
            decoration: BoxDecoration(
              color: filled ? colors.ink : colors.surface,
              borderRadius: const BorderRadius.all(
                Radius.circular(ForgeRadii.button),
              ),
              border: filled ? null : Border.all(color: colors.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: Gap.sm,
              children: [
                if (running)
                  Opacity(
                    opacity: 0.8,
                    child: BusyRing(
                      size: 16,
                      stroke: 2,
                      sweep: 0.75,
                      color: ink,
                    ),
                  )
                else
                  SizedBox.square(
                    dimension: _mark,
                    child: FittedBox(child: provider.mark),
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
      ),
    );
  }
}

/// The email form behind "Use email instead": a back link, the [title],
/// Email, Password and Sign in. [emailError] and [passwordError] show in
/// danger under their fields; the caller checks the values and the result
/// of [onSignIn], and passes [busy] while it runs.
class SignInEmailPage extends StatefulWidget {
  const SignInEmailPage({
    super.key,
    required this.backLabel,
    required this.onBack,
    required this.title,
    required this.emailLabel,
    required this.passwordLabel,
    required this.signInLabel,
    required this.onSignIn,
    this.emailError,
    this.passwordError,
    this.busy = false,
  });

  final String backLabel;
  final VoidCallback onBack;
  final String title;
  final String emailLabel;
  final String passwordLabel;
  final String signInLabel;
  final void Function(String email, String password) onSignIn;
  final String? emailError;
  final String? passwordError;
  final bool busy;

  @override
  State<SignInEmailPage> createState() => _SignInEmailPageState();
}

class _SignInEmailPageState extends State<SignInEmailPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.emailError != null || widget.passwordError != null) {
      _showErrors();
    }
  }

  @override
  void didUpdateWidget(SignInEmailPage old) {
    super.didUpdateWidget(old);
    if (old.emailError != widget.emailError ||
        old.passwordError != widget.passwordError) {
      _showErrors();
    }
  }

  // The fields show their errors through validation, run once they are
  // built with the new ones.
  void _showErrors() => WidgetsBinding.instance.addPostFrameCallback(
    (_) => _form.currentState?.validate(),
  );

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!widget.busy) widget.onSignIn(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: ForgeStyle.of(context).colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.lg),
          child: Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Gap.md,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _BackLink(
                      label: widget.backLabel,
                      onTap: widget.busy ? null : widget.onBack,
                    ),
                  ),
                  Text(widget.title, style: text.titleLarge),
                  ForgeTextField(
                    label: widget.emailLabel,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (_) => widget.emailError,
                  ),
                  ForgeTextField(
                    label: widget.passwordLabel,
                    controller: _password,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: (_) => widget.passwordError,
                    onSubmitted: (_) => _submit(),
                  ),
                  ForgeButton(
                    label: widget.signInLabel,
                    onPressed: _submit,
                    loading: widget.busy,
                    size: ForgeButtonSize.large,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final ink = onTap == null ? colors.lineStrong : colors.ink;
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: ForgeTheme.tapMin),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: Gap.xs,
            children: [
              ForgeIcon(ForgeIcons.chevronLeft, size: 18, color: ink),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge!
                    .copyWith(color: ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks before signing in to an account that already has data: the
/// device's guest data would be replaced. Completes with true when the
/// user confirms.
Future<bool> confirmReplaceGuestData(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) async =>
    await showForgeDialog<bool>(
      context: context,
      builder: (context) => ForgeDialog(
        title: title,
        message: message,
        action: ForgeButton(
          label: confirmLabel,
          onPressed: () => Navigator.pop(context, true),
          variant: ForgeButtonVariant.danger,
        ),
        cancel: ForgeButton(
          label: cancelLabel,
          onPressed: () => Navigator.pop(context, false),
          variant: ForgeButtonVariant.secondary,
        ),
      ),
    ) ??
    false;
