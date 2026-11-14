import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: RulerPicker)
Widget rulerPicker(BuildContext context) => const _Ruler();

class _Ruler extends StatefulWidget {
  const _Ruler();

  @override
  State<_Ruler> createState() => _RulerState();
}

class _RulerState extends State<_Ruler> {
  double _value = 72.5;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(_value.toStringAsFixed(1), style: ForgeStyle.of(context).dataLg),
      const SizedBox(height: Gap.md),
      RulerPicker(
        min: 30,
        max: 200,
        step: 0.5,
        value: _value,
        onChanged: (value) => setState(() => _value = value),
      ),
    ],
  );
}
