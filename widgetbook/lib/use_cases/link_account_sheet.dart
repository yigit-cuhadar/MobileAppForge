import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// A placeholder provider mark; forge_auth passes the real ones.
class _ProviderMark extends StatelessWidget {
  const _ProviderMark({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? colors.surface : null,
        border: filled
            ? null
            : Border.all(color: colors.lineStrong, width: 1.5),
      ),
    );
  }
}

LinkAccountSheet _sheet(BuildContext context, {SignInOption? running}) =>
    LinkAccountSheet(
      title: context.knobs.string(label: 'Title', initialValue: 'Item title'),
      message: context.knobs.string(
        label: 'Message',
        initialValue:
            'Create an account to back up and use [APP NAME] on every '
            'device. Your data stays as it is.',
      ),
      apple: SignInProvider(
        mark: const _ProviderMark(filled: true),
        label: 'Continue with Apple',
        onPressed: () {},
      ),
      google: SignInProvider(
        mark: const _ProviderMark(filled: false),
        label: 'Continue with Google',
        onPressed: () {},
      ),
      useEmailLabel: 'Use email instead',
      onUseEmail: () {},
      notNowLabel: 'Not now',
      onNotNow: () {},
      signingInLabel: 'Signing in…',
      running: running,
    );

/// [sheet] on the scrim at the bottom, with [over] laid on top.
Widget _shown(BuildContext context, Widget sheet, {Widget? over}) => Stack(
  children: [
    ColoredBox(
      color: Theme.of(context).colorScheme.scrim,
      child: Column(
        children: [
          const Spacer(),
          BottomSheet(
            onClosing: () {},
            enableDrag: false,
            builder: (_) => sheet,
          ),
        ],
      ),
    ),
    ?over,
  ],
);

@widgetbook.UseCase(name: 'Options', type: LinkAccountSheet)
Widget linkAccountOptions(BuildContext context) =>
    _shown(context, _sheet(context));

@widgetbook.UseCase(name: 'Signing in', type: LinkAccountSheet)
Widget linkAccountSigningIn(BuildContext context) => _shown(
  context,
  _sheet(
    context,
    running: context.knobs.object.segmented<SignInOption>(
      label: 'Running',
      options: [SignInOption.apple, SignInOption.google],
      labelBuilder: (option) => option.name,
    ),
  ),
);

/// A failed sign-in: the error snackbar over the sheet, with no action.
@widgetbook.UseCase(name: 'Error', type: LinkAccountSheet)
Widget linkAccountError(BuildContext context) => _shown(
  context,
  _sheet(context),
  over: const Positioned(
    left: Gap.md,
    right: Gap.md,
    bottom: Gap.md,
    child: SafeArea(
      child: ForgeSnackbar(
        message: "Couldn't sign in. Try again.",
        error: true,
      ),
    ),
  ),
);

/// The account already exists: `confirmReplaceGuestData`'s dialog over
/// the sheet.
@widgetbook.UseCase(name: 'Existing account', type: LinkAccountSheet)
Widget linkAccountExisting(BuildContext context) => _shown(
  context,
  _sheet(context),
  over: ColoredBox(
    color: Theme.of(context).colorScheme.scrim,
    child: ForgeDialog(
      title: 'Use existing account?',
      message: "This device's guest data will be replaced by the account's.",
      action: ForgeButton(
        label: 'Use existing account',
        onPressed: () {},
        variant: ForgeButtonVariant.danger,
      ),
      cancel: ForgeButton(
        label: 'Cancel',
        onPressed: () {},
        variant: ForgeButtonVariant.secondary,
      ),
    ),
  ),
);
