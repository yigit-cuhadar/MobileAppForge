import 'package:material_ui/material_ui.dart';
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
    retryLabel: 'Retry',
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

@widgetbook.UseCase(name: 'Plain', type: SectionCard)
Widget plainSectionCard(BuildContext context) => _page(
  Column(
    spacing: Gap.sm,
    children: [
      const SectionCard.plain(
        title: 'Section title',
        child: Text('One line of content about this section.'),
      ),
      const SectionCard.plain(
        title: 'Section title',
        icon: ForgeIcons.lightbulb,
        child: Text('One line of content about this section.'),
      ),
      const SectionCard.plain(
        title: 'Section title',
        icon: ForgeIcons.warning,
        warning: true,
        child: Text('One line of caution about this section.'),
      ),
      SectionCard.plain(
        title: 'Section title',
        actionLabel: context.knobs.string(
          label: 'Action',
          initialValue: 'Edit',
        ),
        onAction: () {},
        child: const Text('[VALUE]'),
      ),
    ],
  ),
);

@widgetbook.UseCase(name: 'Plain, no content', type: SectionCard)
Widget plainEmptySectionCard(BuildContext context) => _page(
  SectionCard.plain(
    title: 'Section title',
    actionLabel: context.knobs.string(label: 'Action', initialValue: 'Add'),
    onAction: () {},
  ),
);

@widgetbook.UseCase(name: 'Plain, with a note', type: SectionCard)
Widget plainNoteSectionCard(BuildContext context) => _page(
  SectionCard.plain(
    title: 'Section title',
    note: context.knobs.string(
      label: 'Note',
      initialValue: '[DETAIL] of [DETAIL] · [VALUE]',
    ),
    child: const Text('[CONTENT]'),
  ),
);
