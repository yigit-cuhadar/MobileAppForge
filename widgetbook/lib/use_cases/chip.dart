import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Action', type: ForgeChip)
Widget action(BuildContext context) => Center(
  child: ForgeChip(
    label: context.knobs.string(label: 'Label', initialValue: 'Action one'),
    onPressed: () {},
  ),
);

@widgetbook.UseCase(name: 'Filters', type: ForgeChip)
Widget filters(BuildContext context) => const _Filters();

class _Filters extends StatefulWidget {
  const _Filters();

  @override
  State<_Filters> createState() => _FiltersState();
}

class _FiltersState extends State<_Filters> {
  final _chosen = {'Filter A', 'Filter B'};

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Gap.md),
      child: Wrap(
        spacing: Gap.sm,
        children: [
          for (final label in ['Filter A', 'Filter B', 'Filter C', 'Filter D'])
            ForgeChip(
              label: label,
              selected: _chosen.contains(label),
              onPressed: () => setState(
                () => _chosen.contains(label)
                    ? _chosen.remove(label)
                    : _chosen.add(label),
              ),
            ),
        ],
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'With count', type: ForgeChip)
Widget withCount(BuildContext context) => Center(
  child: ForgeChip(
    label: 'Group',
    selected: true,
    count: context.knobs.int.slider(
      label: 'Count',
      initialValue: 2,
      min: 1,
      max: 20,
    ),
    onPressed: () {},
  ),
);

@widgetbook.UseCase(name: 'Locked', type: ForgeChip)
Widget locked(BuildContext context) => Center(
  child: ForgeChip(label: 'Locked action', locked: true, onPressed: () {}),
);

@widgetbook.UseCase(name: 'Removable', type: ForgeChip)
Widget removable(BuildContext context) => const _Removable();

class _Removable extends StatefulWidget {
  const _Removable();

  @override
  State<_Removable> createState() => _RemovableState();
}

class _RemovableState extends State<_Removable> {
  final _active = ['Filter A', 'Filter B'];

  @override
  Widget build(BuildContext context) => Center(
    child: Wrap(
      spacing: Gap.sm,
      children: [
        for (final label in _active)
          ForgeChip.removable(
            label: label,
            onRemoved: () => setState(() => _active.remove(label)),
          ),
      ],
    ),
  );
}

@widgetbook.UseCase(name: 'Series', type: ForgeChip)
Widget series(BuildContext context) => const _Series();

class _Series extends StatefulWidget {
  const _Series();

  @override
  State<_Series> createState() => _SeriesState();
}

class _SeriesState extends State<_Series> {
  bool _adding = false;

  @override
  Widget build(BuildContext context) => Center(
    child: Wrap(
      spacing: Gap.sm,
      children: [
        for (final (label, look) in const [
          ('Series A', SeriesLook.accent),
          ('Series B', SeriesLook.info),
          ('Series C', SeriesLook.success),
        ])
          ForgeChip.series(
            label: label,
            sample: SeriesSample(look),
            selected: true,
            onPressed: () {},
          ),
        ForgeChip.series(
          label: 'Add',
          sample: const ForgeIcon(ForgeIcons.add, size: 14),
          selected: _adding,
          onPressed: () => setState(() => _adding = !_adding),
        ),
      ],
    ),
  );
}
