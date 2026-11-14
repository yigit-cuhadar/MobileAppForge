import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _steps(BuildContext context, {required int count, required int on}) {
  final current = context.knobs.int.slider(
    label: 'Current',
    initialValue: on,
    min: 1,
    max: count,
  );
  return Padding(
    padding: const EdgeInsets.all(Gap.lg),
    child: Align(
      alignment: Alignment.topCenter,
      child: StepProgress(
        count: count,
        current: current,
        caption: context.knobs.boolean(label: 'Caption', initialValue: true)
            ? 'Step $current of $count · [STEP NAME]'
            : null,
      ),
    ),
  );
}

@widgetbook.UseCase(name: '3 steps', type: StepProgress)
Widget stepProgressThree(BuildContext context) =>
    _steps(context, count: 3, on: 2);

@widgetbook.UseCase(name: '9 steps', type: StepProgress)
Widget stepProgressNine(BuildContext context) =>
    _steps(context, count: 9, on: 4);
