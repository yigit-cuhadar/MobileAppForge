import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: ForgeTextField)
Widget textField(BuildContext context) => Padding(
  padding: const EdgeInsets.all(Gap.md),
  child: ForgeTextField(
    label: context.knobs.string(label: 'Label', initialValue: 'Email'),
    obscure: context.knobs.boolean(label: 'Obscure'),
  ),
);
