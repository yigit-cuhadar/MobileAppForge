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
            removeHint: 'Removes the filter',
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

@widgetbook.UseCase(name: 'Menu (unset filter)', type: ForgeChip)
Widget menu(BuildContext context) => Center(
  child: Wrap(
    spacing: Gap.sm,
    children: [
      ForgeChip.menu(label: 'Filter A', onPressed: () {}),
      ForgeChip.menu(label: 'Filter B', onPressed: () {}),
      ForgeChip.removable(
        label: '[VALUE]',
        onRemoved: () {},
        removeHint: 'Removes the filter',
      ),
    ],
  ),
);

@widgetbook.UseCase(name: 'Leading icon', type: ForgeChip)
Widget leadingIcon(BuildContext context) => Center(
  child: Wrap(
    spacing: Gap.sm,
    children: [
      ForgeChip(
        label: 'Item',
        selected: true,
        showCheck: false,
        leading: ForgeIcon(
          ForgeIcons.error,
          color: ForgeStyle.of(context).colors.danger,
        ),
        onPressed: () {},
      ),
      ForgeChip(
        label: 'Add',
        leading: const ForgeIcon(ForgeIcons.add),
        onPressed: () {},
      ),
    ],
  ),
);

@widgetbook.UseCase(
  name: 'Selected without check, with options',
  type: ForgeChip,
)
Widget selectedNoCheck(BuildContext context) => const _SelectedNoCheck();

class _SelectedNoCheck extends StatefulWidget {
  const _SelectedNoCheck();

  @override
  State<_SelectedNoCheck> createState() => _SelectedNoCheckState();
}

class _SelectedNoCheckState extends State<_SelectedNoCheck> {
  var _chosen = 'Item A';
  var _held = '';

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: Gap.md,
      children: [
        Wrap(
          spacing: Gap.sm,
          children: [
            for (final label in ['Item A', 'Item B', 'Item C'])
              ForgeChip(
                label: label,
                selected: _chosen == label,
                showCheck: false,
                onPressed: () => setState(() => _chosen = label),
                onOptions: () => setState(() => _held = label),
                optionsLabel: 'Item options',
              ),
          ],
        ),
        Text(_held.isEmpty ? 'No options opened' : 'Options of $_held'),
      ],
    ),
  );
}

@widgetbook.UseCase(name: 'Add', type: ForgeChip)
Widget add(BuildContext context) => Center(
  child: Wrap(
    spacing: Gap.sm,
    children: [
      ForgeChip(label: 'Item A', onPressed: () {}),
      ForgeChip(label: 'Item B', onPressed: () {}),
      ForgeChip.add(
        label: context.knobs.string(label: 'Label', initialValue: 'Item'),
        onPressed: () {},
      ),
    ],
  ),
);
