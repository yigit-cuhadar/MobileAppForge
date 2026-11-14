import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Primary', type: ForgeButton)
Widget primaryButton(BuildContext context) => Center(
  child: ForgeButton(
    label: context.knobs.string(label: 'Label', initialValue: 'Start'),
    loading: context.knobs.boolean(label: 'Loading'),
    onPressed: context.knobs.boolean(label: 'Enabled', initialValue: true)
        ? () {}
        : null,
  ),
);
