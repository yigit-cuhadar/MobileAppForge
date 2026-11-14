import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _page(Widget child) =>
    ListView(padding: const EdgeInsets.all(Gap.md), children: [child]);

/// Stands in for the Forge Premium tag until it is swapped in.
Widget _premium() => const Chip(
  avatar: ForgeIcon(ForgeIcons.lock, size: 12),
  label: Text('Premium'),
  visualDensity: VisualDensity.compact,
);

@widgetbook.UseCase(name: 'Plain', type: ListRow)
Widget plainRows(BuildContext context) => _page(
  ListRowCard(
    children: [
      ListRow(
        title: 'Units',
        value: context.knobs.string(label: 'Value', initialValue: '[VALUE]'),
        end: ListRowEnd.chevron,
        onTap: () {},
      ),
      ListRow(
        title: 'Appearance',
        value: 'System',
        end: ListRowEnd.chevron,
        onTap: () {},
      ),
      ListRow(title: 'Notifications', end: ListRowEnd.chevron, onTap: () {}),
      ListRow(title: 'Privacy policy', end: ListRowEnd.external, onTap: () {}),
      ListRow(title: 'Delete account', destructive: true, onTap: () {}),
    ],
  ),
);

@widgetbook.UseCase(name: 'Leading date box', type: ListRow)
Widget dateBoxRows(BuildContext context) => _page(
  ListRowCard(
    children: [
      ListRow(
        title: 'Item title',
        detail: 'Today · [DETAIL]',
        leading: const ListRowDateBox(weekday: 'Fri', day: '13', today: true),
        trailing: FilledButton(onPressed: () {}, child: const Text('Start')),
      ),
      ListRow(
        title: 'Item title',
        detail: '[DETAIL]',
        leading: const ListRowDateBox(weekday: 'Thu', day: '12'),
        end: ListRowEnd.chevron,
        onTap: () {},
      ),
      ListRow(
        title: 'Item title',
        error: 'Missed',
        leading: const ListRowDateBox(weekday: 'Wed', day: '11'),
        trailing: ElevatedButton(
          onPressed: () {},
          child: const Text('Do it now'),
        ),
      ),
    ],
  ),
);

@widgetbook.UseCase(name: 'Info hint', type: ListRow)
Widget infoHintRow(BuildContext context) => _page(
  ListRowCard(
    children: [
      ListRow(
        title: 'Field',
        onInfo: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) => const Padding(
            padding: EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.lg),
            child: Text('One line that explains the field.'),
          ),
        ),
        trailing: const SizedBox(width: 84, child: TextField()),
      ),
    ],
  ),
);

@widgetbook.UseCase(name: 'Checkbox', type: ListRow)
Widget checkboxRows(BuildContext context) => _page(const _Checkboxes());

class _Checkboxes extends StatefulWidget {
  const _Checkboxes();

  @override
  State<_Checkboxes> createState() => _CheckboxesState();
}

class _CheckboxesState extends State<_Checkboxes> {
  final _checked = [true, false, true];

  @override
  Widget build(BuildContext context) => ListRowCard(
    children: [
      for (final (i, on) in _checked.indexed)
        ListRow(
          title: 'Item title',
          detail: '[DETAIL]',
          checked: on,
          onTap: () => setState(() => _checked[i] = !on),
        ),
    ],
  );
}

@widgetbook.UseCase(name: 'Required, missing', type: ListRow)
Widget missingRow(BuildContext context) => _page(
  ListRowCard(
    children: [
      ListRow(
        title: 'Field one',
        value: '[VALUE]',
        end: ListRowEnd.chevron,
        onTap: () {},
      ),
      ListRow(
        title: 'Field two',
        error: 'Required to save',
        missing: true,
        end: ListRowEnd.chevron,
        onTap: () {},
      ),
    ],
  ),
);

@widgetbook.UseCase(name: 'Loading', type: ListRow)
Widget loadingRows(BuildContext context) => _page(
  const ListRowCard(
    children: [
      ListRow.loading(),
      ListRow.loading(index: 1),
      ListRow.loading(index: 2),
    ],
  ),
);

@widgetbook.UseCase(name: 'Drag handle', type: ListRow)
Widget dragHandleRows(BuildContext context) => const _Reorder();

class _Reorder extends StatefulWidget {
  const _Reorder();

  @override
  State<_Reorder> createState() => _ReorderState();
}

class _ReorderState extends State<_Reorder> {
  final _items = ['Item one', 'Item two', 'Item three'];

  @override
  Widget build(BuildContext context) => _page(
    ListRowCard(
      onReorder: (from, to) =>
          setState(() => _items.insert(to, _items.removeAt(from))),
      children: [
        for (final (i, title) in _items.indexed)
          ListRow(
            key: ValueKey(title),
            title: title,
            detail: '[DETAIL]',
            leading: ListRowDragHandle(index: i),
            end: ListRowEnd.chevron,
            onTap: () {},
          ),
      ],
    ),
  );
}

@widgetbook.UseCase(name: 'Locked', type: ListRow)
Widget lockedRows(BuildContext context) => _page(
  ListRowCard(
    children: [
      ListRow(
        title: 'Item title',
        detail: '[DETAIL]',
        end: ListRowEnd.chevron,
        onTap: () {},
      ),
      ListRow(
        title: 'Item title',
        detail: '[DETAIL]',
        locked: true,
        trailing: _premium(),
        end: ListRowEnd.chevron,
        onTap: () {},
      ),
    ],
  ),
);

@widgetbook.UseCase(name: 'Unlocking, then Retry', type: ListRow)
Widget unlockingRows(BuildContext context) => _page(
  ListRowCard(
    children: [
      const ListRow(title: 'Item title', detail: 'Unlocking…', busy: true),
      ListRow(
        title: 'Item title',
        error: "Couldn't unlock. Check your connection.",
        trailing: OutlinedButton(onPressed: () {}, child: const Text('Retry')),
      ),
    ],
  ),
);
