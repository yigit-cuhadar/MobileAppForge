import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _page(Widget child) =>
    ListView(padding: const EdgeInsets.all(Gap.md), children: [child]);

@widgetbook.UseCase(name: 'Filled', type: SectionCard)
Widget filledSectionCard(BuildContext context) => _page(
  SectionCard(
    title: context.knobs.string(label: 'Title', initialValue: 'Section title'),
    detail: context.knobs.string(label: 'Detail', initialValue: '[DETAIL]'),
    onTap: () {},
    child: const Column(
      spacing: Gap.sm,
      children: [
        BandBar.compact(
          label: 'Item one',
          valueLabel: '14',
          value: 0.56,
          low: 0.4,
          high: 0.8,
        ),
        BandBar.compact(
          label: 'Item two',
          valueLabel: '8',
          value: 0.32,
          low: 0.4,
          high: 0.8,
        ),
      ],
    ),
  ),
);

@widgetbook.UseCase(name: 'Loading', type: SectionCard)
Widget loadingSectionCard(BuildContext context) =>
    _page(SectionCard.loading(title: 'Section title', onTap: () {}));

@widgetbook.UseCase(name: 'Error', type: SectionCard)
Widget errorSectionCard(BuildContext context) => _page(
  SectionCard.error(
    title: 'Section title',
    onTap: () {},
    message: "Couldn't load this section",
    onRetry: () {},
  ),
);

@widgetbook.UseCase(name: 'Empty', type: SectionCard)
Widget emptySectionCard(BuildContext context) => _page(
  SectionCard.empty(
    title: 'Section title',
    onTap: () {},
    message: 'Nothing here this week yet',
  ),
);

@widgetbook.UseCase(name: 'Locked', type: SectionCard)
Widget lockedSectionCard(BuildContext context) => _page(
  SectionCard.locked(
    title: 'Section title',
    onTap: () {},
    tag: const ForgeTag('Premium', kind: ForgeTagKind.premium),
    message: '[PREMIUM FEATURE ONE] with Premium.',
  ),
);
