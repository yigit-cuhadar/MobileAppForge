import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _card(Widget child) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(Gap.md), child: child),
    ),
  ],
);

class _Live extends StatefulWidget {
  const _Live({required this.value, this.step, this.enabled = true});

  final double value;
  final double? step;
  final bool enabled;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late double _value = widget.value;

  @override
  Widget build(BuildContext context) => ForgeSlider(
    label: 'Label',
    unit: '[UNIT]',
    min: 0,
    max: 60,
    step: widget.step,
    value: _value,
    onChanged: widget.enabled
        ? (value) => setState(() => _value = value)
        : null,
  );
}

@widgetbook.UseCase(name: 'Normal', type: ForgeSlider)
Widget sliderNormal(BuildContext context) => _card(const _Live(value: 36));

@widgetbook.UseCase(name: 'At the minimum', type: ForgeSlider)
Widget sliderMin(BuildContext context) => _card(const _Live(value: 0));

@widgetbook.UseCase(name: 'At the maximum', type: ForgeSlider)
Widget sliderMax(BuildContext context) => _card(const _Live(value: 60));

@widgetbook.UseCase(name: 'Steps', type: ForgeSlider)
Widget sliderSteps(BuildContext context) =>
    _card(const _Live(value: 30, step: 10));

@widgetbook.UseCase(name: 'Disabled', type: ForgeSlider)
Widget sliderDisabled(BuildContext context) =>
    _card(const _Live(value: 24, enabled: false));
