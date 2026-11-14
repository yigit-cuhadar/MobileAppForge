import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// [sheet] as shown by [showForgeBottomSheet], with a button to open it.
Widget _shown(BuildContext context, ForgeBottomSheet sheet) => ColoredBox(
  color: Theme.of(context).colorScheme.scrim,
  child: Column(
    children: [
      Expanded(
        child: Center(
          child: FilledButton(
            onPressed: () => showForgeBottomSheet<void>(
              context: context,
              builder: (_) => sheet,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
      BottomSheet(onClosing: () {}, enableDrag: false, builder: (_) => sheet),
    ],
  ),
);

Widget _options(List<String> labels) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [for (final label in labels) ListTile(title: Text(label))],
);

@widgetbook.UseCase(name: 'Choose one', type: ForgeBottomSheet)
Widget chooseOneSheet(BuildContext context) => _shown(
  context,
  ForgeBottomSheet(
    title: context.knobs.string(label: 'Title', initialValue: 'Choose one'),
    action: FilledButton(onPressed: () {}, child: const Text('Save')),
    child: _options([
      'Option one',
      'Option two (default)',
      'Option three',
      'Option four',
    ]),
  ),
);

@widgetbook.UseCase(name: 'Header action', type: ForgeBottomSheet)
Widget headerActionSheet(BuildContext context) => _shown(
  context,
  ForgeBottomSheet(
    title: 'Filters',
    headerAction: TextButton(onPressed: () {}, child: const Text('Clear all')),
    action: FilledButton(onPressed: () {}, child: const Text('Show results')),
    child: _options(['Option one', 'Option two', 'Option three']),
  ),
);

@widgetbook.UseCase(name: 'Without action', type: ForgeBottomSheet)
Widget choiceSheet(BuildContext context) => _shown(
  context,
  ForgeBottomSheet(
    title: 'Choose one',
    child: _options(['Option one', 'Option two', 'Option three']),
  ),
);
