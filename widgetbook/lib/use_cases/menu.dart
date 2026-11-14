import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

List<ForgeMenuItem> _items(List<String> labels, {bool destructive = false}) => [
  for (final label in labels)
    ForgeMenuItem(
      label: label,
      destructive: destructive && label == labels.last,
      onTap: () {},
    ),
];

Widget _centred(Widget child) => Center(child: child);

@widgetbook.UseCase(name: 'With destructive action', type: ForgeMenu)
Widget destructiveMenu(BuildContext context) => _centred(
  ForgeMenu(
    items: _items(['Open', 'Edit', 'Duplicate', 'Delete'], destructive: true),
  ),
);

@widgetbook.UseCase(name: 'Without destructive action', type: ForgeMenu)
Widget plainMenu(BuildContext context) => _centred(
  ForgeMenu(items: _items(['Replace', 'Details', 'Note', 'Option · value'])),
);

@widgetbook.UseCase(name: 'Selected row', type: ForgeMenu)
Widget selectedMenu(BuildContext context) => _centred(
  ForgeMenu(
    items: [
      ForgeMenuItem(label: 'Replace with similar', onTap: () {}),
      ForgeMenuItem(label: 'Keep', selected: true, onTap: () {}),
      ForgeMenuItem(label: 'Edit values', onTap: () {}),
      ForgeMenuItem(label: 'Remove', destructive: true, onTap: () {}),
    ],
  ),
);

@widgetbook.UseCase(name: 'Opened from more button', type: ForgeMenu)
Widget openedMenu(BuildContext context) => Padding(
  padding: const EdgeInsets.all(Gap.md),
  child: Align(
    alignment: Alignment.topRight,
    child: Builder(
      builder: (context) => IconButton(
        tooltip: 'More options',
        onPressed: () => showForgeMenu(
          context: context,
          items: _items([
            'Open',
            'Edit',
            'Duplicate',
            'Delete',
          ], destructive: true),
        ),
        icon: const ForgeIcon(ForgeIcons.moreHoriz, size: 20),
      ),
    ),
  ),
);

const _facts = [
  ('Fact one', '[VALUE]'),
  ('Fact two', '2 × [VALUE]'),
  ('Fact three', '[VALUE]'),
];

@widgetbook.UseCase(name: 'Info', type: ForgeInfoCard)
Widget infoCard(BuildContext context) =>
    _centred(const ForgeInfoCard(title: '[VALUE] on [DETAIL]', facts: _facts));

@widgetbook.UseCase(name: 'Opened from a value', type: ForgeInfoCard)
Widget openedInfoCard(BuildContext context) => Padding(
  padding: const EdgeInsets.all(Gap.md),
  child: Align(
    alignment: Alignment.topRight,
    child: Builder(
      builder: (context) => ForgeButton(
        label: '[VALUE]',
        onPressed: () => showForgeInfo(
          context: context,
          title: '[VALUE] on [DETAIL]',
          facts: _facts,
        ),
        variant: ForgeButtonVariant.text,
      ),
    ),
  ),
);
