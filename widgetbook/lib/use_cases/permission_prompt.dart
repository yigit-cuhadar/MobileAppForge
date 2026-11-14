import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _page(Widget child) =>
    ListView(padding: const EdgeInsets.all(Gap.md), children: [child]);

@widgetbook.UseCase(name: 'Ask · in a card', type: PermissionPrompt)
Widget askInCard(BuildContext context) => _page(
  PermissionPrompt.ask(
    icon: ForgeIcons.favorite,
    title: context.knobs.string(
      label: 'Title',
      initialValue: 'See your [DATA] here',
    ),
    message: context.knobs.string(
      label: 'Message',
      initialValue:
          '[APP NAME] reads [DATA] from [SYSTEM APP]. Nothing else is read.',
    ),
    allowLabel: 'Allow access',
    onAllow: () {},
  ),
);

@widgetbook.UseCase(name: 'Ask · full page', type: PermissionPrompt)
Widget askFullPage(BuildContext context) => PermissionPrompt.ask(
  icon: ForgeIcons.notifications,
  title: 'Turn on reminders?',
  message: 'One reminder at the time you choose.',
  allowLabel: 'Turn on reminders',
  onAllow: () {},
  skipLabel: 'Not now',
  onSkip: () {},
  page: true,
);

@widgetbook.UseCase(name: 'Refused', type: PermissionPrompt)
Widget refusedPrompt(BuildContext context) {
  final canAskAgain = context.knobs.boolean(
    label: 'System can ask again',
    initialValue: true,
  );
  return _page(
    PermissionPrompt.refused(
      title: 'Access is off',
      message: "[APP NAME] can't read [DATA]. Turn access on in Settings.",
      settingsLabel: 'Open settings',
      onOpenSettings: () {},
      askAgainLabel: canAskAgain ? 'Ask again' : null,
      onAskAgain: canAskAgain ? () {} : null,
    ),
  );
}

@widgetbook.UseCase(name: 'Failed', type: PermissionPrompt)
Widget failedPrompt(BuildContext context) => _page(
  PermissionPrompt.failed(
    title: "Couldn't ask for access",
    message: 'Something went wrong. Try again in a moment.',
    retryLabel: 'Retry',
    onRetry: () {},
  ),
);

@widgetbook.UseCase(name: 'System app missing', type: PermissionPrompt)
Widget missingAppPrompt(BuildContext context) => _page(
  PermissionPrompt.missing(
    title: '[SYSTEM APP] is needed',
    message:
        '[APP NAME] reads [DATA] through [SYSTEM APP]. Install it, then come '
        'back.',
    getLabel: 'Get [SYSTEM APP]',
    onGet: () {},
    notNowLabel: 'Not now',
    onNotNow: () {},
  ),
);
