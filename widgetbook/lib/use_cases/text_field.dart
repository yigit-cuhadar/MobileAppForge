import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _padded(Widget child) =>
    Padding(padding: const EdgeInsets.all(Gap.md), child: child);

@widgetbook.UseCase(name: 'Empty', type: ForgeTextField)
Widget empty(BuildContext context) => _padded(
  ForgeTextField(
    label: context.knobs.string(label: 'Label', initialValue: 'Name'),
    hint: context.knobs.string(label: 'Hint', initialValue: 'e.g. [EXAMPLE]'),
  ),
);

@widgetbook.UseCase(name: 'Filled', type: ForgeTextField)
Widget filled(BuildContext context) => _padded(
  ForgeTextField(
    label: 'Name',
    controller: TextEditingController(text: 'Item name'),
  ),
);

@widgetbook.UseCase(name: 'Error', type: ForgeTextField)
Widget error(BuildContext context) => _padded(const _Error());

class _Error extends StatefulWidget {
  const _Error();

  @override
  State<_Error> createState() => _ErrorState();
}

class _ErrorState extends State<_Error> {
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _form.currentState?.validate(),
    );
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: ForgeTextField(
      label: 'Name',
      validator: (v) => v!.isEmpty ? 'Enter a name.' : null,
    ),
  );
}

@widgetbook.UseCase(name: 'Disabled', type: ForgeTextField)
Widget disabled(BuildContext context) => _padded(
  const ForgeTextField(label: 'Email', hint: 'you@example.com', enabled: false),
);

@widgetbook.UseCase(name: 'Note', type: ForgeTextField)
Widget note(BuildContext context) => _padded(
  ForgeTextField(
    label: 'Note',
    multiline: true,
    controller: TextEditingController(
      text: 'A longer note that wraps to a second and third line.',
    ),
  ),
);

@widgetbook.UseCase(name: 'Inline number', type: ForgeNumberField)
Widget inlineNumber(BuildContext context) => _padded(
  Column(
    children: [
      for (final (label, value) in [
        ('Field one', '36.5'),
        ('Field two', '8'),
        ('Field three', ''),
      ])
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Gap.sm),
          child: Row(
            spacing: Gap.md,
            children: [
              Expanded(child: Text(label)),
              ForgeNumberField(
                label: label,
                unit: '[UNIT]',
                controller: TextEditingController(text: value),
                onChanged: (_) {},
              ),
            ],
          ),
        ),
    ],
  ),
);

@widgetbook.UseCase(name: 'Compact in a row', type: ForgeNumberField)
Widget compactNumbers(BuildContext context) => _padded(
  Column(
    children: [
      for (final (weight, count) in [('40', '10'), ('82.5', '8'), ('', '')])
        SizedBox(
          height: 48,
          child: Row(
            spacing: Gap.sm,
            children: [
              ForgeNumberField.compact(
                label: 'Field one',
                width: 70,
                controller: TextEditingController(text: weight),
                onChanged: (_) {},
              ),
              const Text('×'),
              ForgeNumberField.compact(
                label: 'Field two',
                width: 50,
                controller: TextEditingController(text: count),
                onChanged: (_) {},
              ),
            ],
          ),
        ),
    ],
  ),
);
