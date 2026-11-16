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

@widgetbook.UseCase(name: 'Wheel', type: NumberPicker)
Widget numberPickerWheel(BuildContext context) => _card(
  _Live(
    value: 1995,
    builder: (value, onChanged) => NumberPicker.wheel(
      label: 'Birth year',
      min: 1900,
      max: 2020,
      step: 1,
      value: value,
      onChanged: onChanged,
      grouped: false,
    ),
  ),
);

@widgetbook.UseCase(name: 'Ruler', type: NumberPicker)
Widget numberPickerRuler(BuildContext context) => _card(
  _Live(
    value: 83,
    builder: (value, onChanged) => NumberPicker.ruler(
      label: 'Amount',
      unit: '[UNIT]',
      min: 30,
      max: 200,
      step: 0.1,
      value: value,
      onChanged: onChanged,
    ),
  ),
);

@widgetbook.UseCase(name: 'Ruler, value tappable', type: NumberPicker)
Widget numberPickerRulerTappable(BuildContext context) => _card(
  _Live(
    value: 180,
    builder: (value, onChanged) => NumberPicker.ruler(
      label: 'Amount',
      unit: '[UNIT]',
      min: 100,
      max: 250,
      step: 1,
      value: value,
      onChanged: onChanged,
      onValueTap: () {},
    ),
  ),
);

@widgetbook.UseCase(name: 'Ruler in parts', type: NumberPicker)
Widget numberPickerRulerParts(BuildContext context) => _card(
  _Live(
    value: 71,
    builder: (value, onChanged) => NumberPicker.ruler(
      label: 'Amount',
      parts: (value) => [
        ('${value ~/ 12}', '[UNIT]'),
        ('${(value % 12).round()}', '[UNIT]'),
      ],
      min: 48,
      max: 96,
      step: 1,
      value: value,
      onChanged: onChanged,
      onValueTap: () {},
    ),
  ),
);

/// The time wheel over the scrim, as [showForgeTimeWheel] shows it.
Widget _timeWheel(BuildContext context, {required bool h24}) => ColoredBox(
  color: Theme.of(context).colorScheme.scrim,
  child: MediaQuery(
    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: h24),
    child: ForgeTimeWheel(
      initial: const TimeOfDay(hour: 18, minute: 0),
      onChanged: (_) {},
    ),
  ),
);

@widgetbook.UseCase(name: 'Time wheel · 12-hour', type: ForgeTimeWheel)
Widget timeWheel12(BuildContext context) => _timeWheel(context, h24: false);

@widgetbook.UseCase(name: 'Time wheel · 24-hour', type: ForgeTimeWheel)
Widget timeWheel24(BuildContext context) => _timeWheel(context, h24: true);

@widgetbook.UseCase(name: 'Time wheel · device setting', type: ForgeTimeWheel)
Widget timeWheelDevice(BuildContext context) => Center(
  child: ForgeButton(
    label: 'Open',
    onPressed: () => showForgeTimeWheel(
      context: context,
      initial: const TimeOfDay(hour: 7, minute: 30),
      onChanged: (_) {},
    ),
  ),
);

/// [wheel] over the scrim, as [showForgeDurationWheel] shows it.
Widget _durationWheel(BuildContext context, ForgeDurationWheel wheel) =>
    ColoredBox(color: Theme.of(context).colorScheme.scrim, child: wheel);

@widgetbook.UseCase(
  name: 'Duration wheel · hours and minutes',
  type: ForgeDurationWheel,
)
Widget durationHoursMinutes(BuildContext context) => _durationWheel(
  context,
  ForgeDurationWheel.hoursMinutes(
    label: 'Duration',
    initial: const Duration(minutes: 50),
    max: const Duration(hours: 24),
    hourUnit: 'h',
    minuteUnit: 'min',
    onChanged: (_) {},
  ),
);

@widgetbook.UseCase(
  name: 'Duration wheel · minutes and seconds',
  type: ForgeDurationWheel,
)
Widget durationMinutesSeconds(BuildContext context) => _durationWheel(
  context,
  ForgeDurationWheel.minutesSeconds(
    label: 'Rest',
    initial: const Duration(minutes: 1, seconds: 30),
    max: const Duration(minutes: 10),
    step: const Duration(seconds: 15),
    onChanged: (_) {},
  ),
);

@widgetbook.UseCase(
  name: 'Duration wheel · hours, minutes and seconds',
  type: ForgeDurationWheel,
)
Widget durationHoursMinutesSeconds(BuildContext context) => _durationWheel(
  context,
  ForgeDurationWheel.hoursMinutesSeconds(
    label: 'Duration',
    initial: const Duration(minutes: 28, seconds: 40),
    max: const Duration(hours: 24),
    hourUnit: 'h',
    minuteUnit: 'min',
    secondUnit: 's',
    onChanged: (_) {},
  ),
);

class _Live extends StatefulWidget {
  const _Live({required this.value, required this.builder});

  final double value;
  final Widget Function(double value, ValueChanged<double> onChanged) builder;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late double _value = widget.value;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (value) => setState(() => _value = value));
}
