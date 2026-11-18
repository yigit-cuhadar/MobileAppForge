import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Over a card', type: SectionLabel)
Widget sectionLabel(BuildContext context) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    SectionLabel(
      context.knobs.string(label: 'Text', initialValue: 'Section title'),
    ),
    ListRowCard(
      children: [
        ListRow(title: 'Item title', value: '[VALUE]', onTap: () {}),
        ListRow(title: 'Item title', value: '[VALUE]', onTap: () {}),
      ],
    ),
    const SectionLabel('Section title'),
    ListRowCard(
      children: [ListRow(title: 'Item title', onTap: () {})],
    ),
  ],
);
