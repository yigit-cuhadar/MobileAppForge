import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// [dialog] over the scrim, as [showForgeDialog] shows it.
Widget _shown(BuildContext context, ForgeDialog dialog) =>
    ColoredBox(color: Theme.of(context).colorScheme.scrim, child: dialog);

Widget get _cancel => ForgeButton(
  label: 'Cancel',
  onPressed: () {},
  variant: ForgeButtonVariant.secondary,
);

@widgetbook.UseCase(name: 'Danger action', type: ForgeDialog)
Widget dangerDialog(BuildContext context) => _shown(
  context,
  ForgeDialog(
    title: 'Discard changes?',
    message: "Your changes will be lost. This can't be undone.",
    action: ForgeButton(
      label: 'Discard',
      onPressed: () {},
      variant: ForgeButtonVariant.danger,
    ),
    cancel: _cancel,
  ),
);

@widgetbook.UseCase(name: 'Main action', type: ForgeDialog)
Widget mainActionDialog(BuildContext context) => _shown(
  context,
  ForgeDialog(
    title: context.knobs.string(label: 'Title', initialValue: 'Mark as done?'),
    message: context.knobs.string(
      label: 'Message',
      initialValue: 'You can still edit it later.',
    ),
    action: ForgeButton(label: 'Mark as done', onPressed: () {}),
    cancel: _cancel,
  ),
);

@widgetbook.UseCase(name: 'With field, error', type: ForgeDialog)
Widget fieldDialog(BuildContext context) => _shown(
  context,
  ForgeDialog(
    title: 'Set a goal',
    message: 'Pick a number from 1,000 to 50,000.',
    field: Form(
      autovalidateMode: AutovalidateMode.always,
      child: ForgeTextField(
        label: 'Goal',
        controller: TextEditingController(text: '500'),
        keyboardType: TextInputType.number,
        validator: (_) => 'Enter a number from 1,000 to 50,000.',
      ),
    ),
    action: ForgeButton(label: 'Save', onPressed: () {}),
    cancel: _cancel,
  ),
);
