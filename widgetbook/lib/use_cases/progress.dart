import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
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

@widgetbook.UseCase(name: 'Bar', type: Progress)
Widget progressBar(BuildContext context) {
  final value = context.knobs.double.slider(
    label: 'Value',
    initialValue: 31,
    max: 60,
  );
  const goal = 50.0;
  return _card(
    Progress.bar(
      value: value,
      goal: goal,
      figure: value.round().toString(),
      caption: value >= goal
          ? 'Goal reached'
          : '${(goal - value).round()} to go',
    ),
  );
}

@widgetbook.UseCase(name: 'Bar · goal reached', type: Progress)
Widget progressBarReached(BuildContext context) => _card(
  const Progress.bar(
    value: 50,
    goal: 50,
    figure: '[VALUE]',
    caption: 'Goal reached',
  ),
);

@widgetbook.UseCase(name: 'Ring', type: Progress)
Widget progressRing(BuildContext context) {
  final value = context.knobs.double.slider(
    label: 'Value',
    initialValue: 31,
    max: 60,
  );
  return _card(
    Center(
      child: Progress.ring(
        value: value,
        goal: 50,
        figure: value.round().toString(),
        caption: value >= 50 ? 'Goal reached' : 'of 50',
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'Ring · goal reached', type: Progress)
Widget progressRingReached(BuildContext context) => _card(
  const Center(
    child: Progress.ring(
      value: 50,
      goal: 50,
      figure: '[VALUE]',
      caption: 'Goal reached',
    ),
  ),
);
