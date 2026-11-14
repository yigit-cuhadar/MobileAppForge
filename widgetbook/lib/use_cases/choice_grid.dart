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

class _LiveList extends StatefulWidget {
  const _LiveList({required this.form});

  final ChoiceListForm form;

  @override
  State<_LiveList> createState() => _LiveListState();
}

class _LiveListState extends State<_LiveList> {
  int? _selected = 1;

  @override
  Widget build(BuildContext context) => ChoiceGrid.list(
    form: widget.form,
    options: const [
      ChoiceOption(label: 'Option one', hint: '[HINT]'),
      ChoiceOption(label: 'Option two', hint: '[HINT]'),
      ChoiceOption(label: 'Option three', hint: '[HINT]'),
      ChoiceOption(label: 'Option four', hint: '[HINT]'),
    ],
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
