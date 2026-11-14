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
    action: ElevatedButton(
      onPressed: () {},
      child: const Text('Open settings'),
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
    action: ElevatedButton(onPressed: () {}, child: const Text('See Premium')),
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
          action: FilledButton(onPressed: () {}, child: const Text('Start')),
          onDismiss: () => setState(() => _shown = false),
        )
      : TextButton(
          onPressed: () => setState(() => _shown = true),
          child: const Text('Show again'),
        );
}
