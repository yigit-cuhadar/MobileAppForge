import 'package:material_ui/material_ui.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _values = [
  'Item one',
  'Item two',
  'Item three',
  'Item four',
  'Item five',
  'Item six',
];

/// The sheet as [showForgeCheckSheet] shows it, with a button to open it.
Widget _shown(BuildContext context, {String? subtitle}) {
  Widget sheet() => ForgeCheckSheet<String>(
    title: 'Section title',
    subtitle: subtitle,
    values: _values,
    selected: const {'Item one', 'Item four'},
    labelOf: (value) => value,
    saveLabel: 'Save',
  );
  return ColoredBox(
    color: Theme.of(context).colorScheme.scrim,
    child: Column(
      children: [
        Expanded(
          child: Center(
            child: ForgeButton(
              label: 'Open',
              onPressed: () => showForgeBottomSheet<Set<String>>(
                context: context,
                builder: (_) => sheet(),
              ),
            ),
          ),
        ),
        BottomSheet(
          onClosing: () {},
          enableDrag: false,
          builder: (_) => sheet(),
        ),
      ],
    ),
  );
}

@widgetbook.UseCase(name: 'Default', type: ForgeCheckSheet)
Widget checkSheet(BuildContext context) => _shown(context);

@widgetbook.UseCase(name: 'Subtitle', type: ForgeCheckSheet)
Widget checkSheetSubtitle(BuildContext context) =>
    _shown(context, subtitle: 'One line about the list.');
