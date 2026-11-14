import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Selected weight', type: ForgeIcon)
Widget forgeIcon(BuildContext context) {
  final selected = context.knobs.boolean(label: 'Selected tab');
  return Center(
    child: Wrap(
      spacing: Gap.md,
      runSpacing: Gap.md,
      children: [
        for (final icon in const [
          ForgeIcons.today,
          ForgeIcons.description,
          ForgeIcons.fitnessCenter,
          ForgeIcons.barChart,
          ForgeIcons.person,
        ])
          ForgeIcon(icon, weight: selected ? ForgeIcon.selectedWeight : null),
      ],
    ),
  );
}
