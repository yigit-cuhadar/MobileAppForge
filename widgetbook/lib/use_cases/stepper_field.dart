import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _panel(List<Widget> fields) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Gap.sm,
          children: [for (final field in fields) Expanded(child: field)],
        ),
      ),
    ),
  ],
);

/// A field that keeps what the user steps or types, and checks it against
/// [min] and [max] with the app's messages.
class _Live extends StatefulWidget {
  const _Live({
    required this.value,
    required this.unit,
    required this.step,
    this.min,
    this.max,
    this.hint,
    this.enabled = true,
    this.signed = false,
    this.compact = false,
  });

  final double? value;
  final String unit;
  final double step;
  final double? min;
  final double? max;
  final double? hint;
  final bool enabled;
  final bool signed;
  final bool compact;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late double? _value = widget.value;
  bool _touched = false;

  String? get _error {
    final value = _value;
    if (value == null) return _touched ? 'Enter a value' : null;
    if ((widget.min != null && value < widget.min!) ||
        (widget.max != null && value > widget.max!)) {
      return 'Enter ${widget.min ?? ''}–${widget.max ?? ''}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => StepperField(
    value: _value,
    unit: widget.unit,
    step: widget.step,
    min: widget.min,
    max: widget.max,
    hint: widget.hint,
    enabled: widget.enabled,
    signed: widget.signed,
    compact: widget.compact,
    errorText: _error,
    onChanged: (value) => setState(() {
      _value = value;
      _touched = true;
    }),
  );
}

@widgetbook.UseCase(name: 'Empty with a hint', type: StepperField)
Widget stepperFieldHint(BuildContext context) =>
    _panel(const [_Live(value: null, unit: '[UNIT]', step: 2.5, hint: 62.5)]);

@widgetbook.UseCase(name: 'Filled', type: StepperField)
Widget stepperFieldFilled(BuildContext context) =>
    _panel(const [_Live(value: 60, unit: '[UNIT]', step: 1)]);

@widgetbook.UseCase(name: 'Error', type: StepperField)
Widget stepperFieldError(BuildContext context) => _panel([
  StepperField(
    value: null,
    unit: '[UNIT]',
    step: 1,
    errorText: 'Enter a value',
    onChanged: (_) {},
  ),
]);

@widgetbook.UseCase(name: 'Lower bound', type: StepperField)
Widget stepperFieldLowerBound(BuildContext context) =>
    _panel(const [_Live(value: 0, unit: 'count', step: 1, min: 0)]);

@widgetbook.UseCase(name: 'Upper bound', type: StepperField)
Widget stepperFieldUpperBound(BuildContext context) => _panel(const [
  _Live(value: 50000, unit: 'count', step: 1000, min: 1000, max: 50000),
]);

@widgetbook.UseCase(name: 'Out of range', type: StepperField)
Widget stepperFieldOutOfRange(BuildContext context) => _panel([
  StepperField(
    value: 60000,
    unit: 'count',
    step: 1000,
    min: 1000,
    max: 50000,
    errorText: 'Enter 1,000–50,000',
    onChanged: (_) {},
  ),
]);

@widgetbook.UseCase(name: 'Decimal step', type: StepperField)
Widget stepperFieldDecimal(BuildContext context) =>
    _panel(const [_Live(value: 82.5, unit: '[UNIT]', step: 2.5)]);

@widgetbook.UseCase(name: 'Two in a panel', type: StepperField)
Widget stepperFieldPair(BuildContext context) => _panel(const [
  _Live(value: 82.5, unit: '[UNIT]', step: 2.5, min: 0),
  _Live(value: 8, unit: 'count', step: 1, min: 0),
]);

@widgetbook.UseCase(name: 'Disabled', type: StepperField)
Widget stepperFieldDisabled(BuildContext context) =>
    _panel(const [_Live(value: 8, unit: 'count', step: 1, enabled: false)]);

@widgetbook.UseCase(name: 'Signed', type: StepperField)
Widget stepperFieldSigned(BuildContext context) => _panel(const [
  _Live(value: 10, unit: '[UNIT] added', step: 2.5, min: 0, signed: true),
  _Live(value: 6, unit: 'count', step: 1, min: 0),
]);

@widgetbook.UseCase(name: 'Compact rows', type: StepperField)
Widget stepperFieldCompact(BuildContext context) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          spacing: 12,
          children: [
            for (final (label, value, count) in [
              ('Row 1', 60.0, 8.0),
              ('Row 2', 40.0, 10.0),
            ])
              Row(
                spacing: Gap.sm,
                children: [
                  SizedBox(width: 46, child: Text(label)),
                  Expanded(
                    child: _Live(
                      value: value,
                      unit: '[UNIT]',
                      step: 2.5,
                      min: 0,
                      compact: true,
                    ),
                  ),
                  Expanded(
                    child: _Live(
                      value: count,
                      unit: 'count',
                      step: 1,
                      min: 0,
                      compact: true,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  ],
);

@widgetbook.UseCase(name: 'Error under a row', type: StepperField)
Widget stepperFieldRowError(BuildContext context) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: StepperField(
                    value: null,
                    unit: '[UNIT]',
                    step: 2.5,
                    invalid: true,
                    onChanged: (_) {},
                  ),
                ),
                Expanded(
                  child: StepperField(
                    value: 8,
                    unit: 'count',
                    step: 1,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
            StepperFieldError(
              context.knobs.string(
                label: 'Message',
                initialValue: 'Enter a value',
              ),
            ),
          ],
        ),
      ),
    ),
  ],
);
