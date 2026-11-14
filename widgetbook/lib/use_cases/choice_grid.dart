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
  );
}
