import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _page(Widget child) =>
    ListView(padding: const EdgeInsets.all(Gap.md), children: [child]);

@widgetbook.UseCase(name: 'Permission off', type: NoticeBanner)
Widget permissionOffNotice(BuildContext context) => _page(
  NoticeBanner(
    icon: ForgeIcons.notificationsOff,
    title: 'Notifications are off',
    message: "Reminders can't reach you until you turn them on.",
    action: ForgeButton(
      label: 'Open settings',
      onPressed: () {},
      variant: ForgeButtonVariant.secondary,
    ),
  ),
);

@widgetbook.UseCase(name: 'Premium ended', type: NoticeBanner)
Widget premiumEndedNotice(BuildContext context) => _page(
  NoticeBanner(
    icon: ForgeIcons.lock,
    title: 'Premium has ended',
    message:
        '[ITEM] came from Premium. It carries on once you get Premium again.',
    action: ForgeButton(
      label: 'See Premium',
      onPressed: () {},
      variant: ForgeButtonVariant.secondary,
    ),
  ),
);

@widgetbook.UseCase(name: 'Tip', type: TipBanner)
Widget tip(BuildContext context) => _page(
  TipBanner(
    message: context.knobs.string(
      label: 'Message',
      initialValue:
          'A one-time hint that explains something new. You can change it '
          'in Settings.',
    ),
    dismissLabel: 'Got it',
    onDismiss: () {},
  ),
);

@widgetbook.UseCase(name: 'Action', type: TipBanner)
Widget actionTip(BuildContext context) => _page(const _ActionTip());

class _ActionTip extends StatefulWidget {
  const _ActionTip();

  @override
  State<_ActionTip> createState() => _ActionTipState();
}

class _ActionTipState extends State<_ActionTip> {
  var _shown = true;

  @override
  Widget build(BuildContext context) => _shown
      ? TipBanner.action(
          icon: ForgeIcons.straighten,
          title: 'Reminder title',
          detail: 'One line of detail',
          action: ForgeButton(label: 'Start', onPressed: () {}),
          onDismiss: () => setState(() => _shown = false),
        )
      : ForgeButton(
          label: 'Show again',
          onPressed: () => setState(() => _shown = true),
          variant: ForgeButtonVariant.text,
        );
}
