import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: ChoiceGrid)
Widget choiceGrid(BuildContext context) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    _Live(skip: context.knobs.boolean(label: 'Skip', initialValue: true)),
  ],
);

class _Live extends StatefulWidget {
  const _Live({required this.skip});

  final bool skip;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  int? _selected = 2;

  @override
  Widget build(BuildContext context) => ChoiceGrid(
    title: 'Question title',
    detail: '[CONTEXT]',
    options: const [
      ChoiceOption(label: 'Option one', hint: '[HINT]'),
      ChoiceOption(label: 'Option two', hint: '[HINT]'),
      ChoiceOption(label: 'Option three', hint: '[HINT]'),
      ChoiceOption(label: 'Option four', hint: '[HINT]'),
      ChoiceOption(label: 'Option five', hint: '[HINT]'),
    ],
    selected: _selected,
    onSelected: (index) => setState(() => _selected = index),
    onSkip: widget.skip ? () => setState(() => _selected = null) : null,
    skipLabel: widget.skip ? 'Skip' : null,
  );
}

const _hinted = [
  ChoiceOption(label: 'Option one', hint: '[HINT]'),
  ChoiceOption(label: 'Option two', hint: '[HINT]'),
  ChoiceOption(label: 'Option three', hint: '[HINT]'),
  ChoiceOption(label: 'Option four', hint: '[HINT]'),
];

class _LiveList extends StatefulWidget {
  const _LiveList({required this.form, this.options = _hinted});

  final ChoiceListForm form;
  final List<ChoiceOption> options;

  @override
  State<_LiveList> createState() => _LiveListState();
}

class _LiveListState extends State<_LiveList> {
  int? _selected = 1;

  @override
  Widget build(BuildContext context) => ChoiceGrid.list(
    form: widget.form,
    options: widget.options,
    selected: _selected,
    onSelected: (index) => setState(() => _selected = index),
  );
}

@widgetbook.UseCase(name: 'List, inline hints', type: ChoiceGrid)
Widget choiceListInline(BuildContext context) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: const [
    Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(Gap.md),
        child: _LiveList(form: ChoiceListForm.inline),
      ),
    ),
  ],
);

@widgetbook.UseCase(name: 'List, stacked hints', type: ChoiceGrid)
Widget choiceListStacked(BuildContext context) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: const [_LiveList(form: ChoiceListForm.stacked)],
);

ChoiceListForm _formKnob(BuildContext context) => context.knobs.object.dropdown(
  label: 'Form',
  options: ChoiceListForm.values,
  labelBuilder: (form) => form.name,
);

@widgetbook.UseCase(name: 'List, labels only', type: ChoiceGrid)
Widget choiceListLabelsOnly(BuildContext context) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    _LiveList(
      form: _formKnob(context),
      options: const [
        ChoiceOption(label: 'Option one'),
        ChoiceOption(label: 'Option two', hint: '[HINT]'),
        ChoiceOption(label: 'Option three'),
      ],
    ),
  ],
);

@widgetbook.UseCase(name: 'List, disabled row', type: ChoiceGrid)
Widget choiceListDisabled(BuildContext context) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    _LiveList(
      form: _formKnob(context),
      options: const [
        ChoiceOption(label: 'Option one', hint: '[HINT]'),
        ChoiceOption(label: 'Option two', hint: '[HINT]'),
        ChoiceOption(label: 'Option three', hint: '[HINT]', enabled: false),
      ],
    ),
  ],
);

@widgetbook.UseCase(name: 'List, info buttons', type: ChoiceGrid)
Widget choiceListInfo(BuildContext context) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    _LiveList(
      form: _formKnob(context),
      options: [
        for (final label in ['Option one', 'Option two', 'Option three'])
          ChoiceOption(
            label: label,
            onInfo: () {},
            infoLabel: 'Details of $label',
          ),
      ],
    ),
  ],
);

@widgetbook.UseCase(name: 'List, tagged row', type: ChoiceGrid)
Widget choiceListTagged(BuildContext context) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    _LiveList(
      form: _formKnob(context),
      options: const [
        ChoiceOption(label: 'Option one'),
        ChoiceOption(
          label: 'Option two',
          tag: ForgeTag('[TAG]', kind: ForgeTagKind.record),
        ),
        ChoiceOption(label: 'Option three'),
      ],
    ),
  ],
);

/// A neutral stand-in for the app's picture: a grey figure.
class _Figure extends StatelessWidget {
  const _Figure();

  @override
  Widget build(BuildContext context) => FittedBox(
    child: ForgeIcon(
      ForgeIcons.person,
      color: ForgeStyle.of(context).colors.inkSubtle,
    ),
  );
}

class _LiveTiles extends StatefulWidget {
  const _LiveTiles({super.key, required this.selected, required this.options});

  final int? selected;
  final List<ChoiceOption> options;

  @override
  State<_LiveTiles> createState() => _LiveTilesState();
}

class _LiveTilesState extends State<_LiveTiles> {
  late int? _selected = widget.selected;

  @override
  Widget build(BuildContext context) => ChoiceGrid.pictures(
    options: widget.options,
    selected: _selected,
    onSelected: (index) => setState(() => _selected = index),
  );
}

@widgetbook.UseCase(name: 'Picture tiles', type: ChoiceGrid)
Widget choicePictureTiles(BuildContext context) {
  final selected = context.knobs.boolean(label: 'Selected', initialValue: true);
  return ListView(
    padding: const EdgeInsets.all(Gap.md),
    children: [
      _LiveTiles(
        // A new key starts the tiles over when the knob changes.
        key: ValueKey(selected),
        selected: selected ? 1 : null,
        options: const [
          ChoiceOption(label: 'Option one', picture: _Figure()),
          ChoiceOption(label: 'Option two', picture: _Figure()),
        ],
      ),
    ],
  );
}

@widgetbook.UseCase(name: 'Picture tiles, hints and disabled', type: ChoiceGrid)
Widget choicePictureTilesDisabled(BuildContext context) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: const [
    _LiveTiles(
      selected: 0,
      options: [
        ChoiceOption(label: 'Option one', hint: '[HINT]', picture: _Figure()),
        ChoiceOption(label: 'Option two', hint: '[HINT]', picture: _Figure()),
        ChoiceOption(
          label: 'Option three',
          hint: '[HINT]',
          picture: _Figure(),
          enabled: false,
        ),
      ],
    ),
  ],
);
