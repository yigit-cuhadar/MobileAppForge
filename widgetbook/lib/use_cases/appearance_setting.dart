import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// As in the app's settings: the first row of a settings card.
@widgetbook.UseCase(name: 'In settings', type: AppearanceSetting)
Widget appearanceSetting(BuildContext context) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    ListRowCard(
      children: [
        AppearanceSetting(
          label: 'Appearance',
          lightLabel: 'Light',
          darkLabel: 'Dark',
          systemLabel: 'System',
          value: context.knobs.object.segmented(
            label: 'Value',
            options: const [ThemeMode.light, ThemeMode.dark, ThemeMode.system],
            initialOption: ThemeMode.system,
            labelBuilder: (mode) => mode.name,
          ),
          onChanged: (_) {},
        ),
        ListRow(
          title: 'Week starts on',
          value: 'Monday',
          end: ListRowEnd.chevron,
          onTap: () {},
        ),
      ],
    ),
  ],
);
