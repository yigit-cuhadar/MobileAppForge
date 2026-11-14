import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// The theme's platform swapped, so each look shows on any host.
Widget _on(BuildContext context, TargetPlatform platform, Widget child) =>
    Theme(
      data: Theme.of(context).copyWith(platform: platform),
      child: Center(child: child),
    );

Widget _switch(BuildContext context, TargetPlatform platform) => _on(
  context,
  platform,
  _Switch(enabled: context.knobs.boolean(label: 'Enabled', initialValue: true)),
);

Widget _checkbox(BuildContext context, TargetPlatform platform) =>
    _on(context, platform, const _Checkbox());

@widgetbook.UseCase(name: 'Android switch', type: ForgeSwitch)
Widget androidSwitch(BuildContext context) =>
    _switch(context, TargetPlatform.android);

@widgetbook.UseCase(name: 'iOS switch', type: ForgeSwitch)
Widget iosSwitch(BuildContext context) => _switch(context, TargetPlatform.iOS);

@widgetbook.UseCase(name: 'Android checkbox', type: ForgeCheckbox)
Widget androidCheckbox(BuildContext context) =>
    _checkbox(context, TargetPlatform.android);

@widgetbook.UseCase(name: 'iOS checkbox', type: ForgeCheckbox)
Widget iosCheckbox(BuildContext context) =>
    _checkbox(context, TargetPlatform.iOS);

class _Switch extends StatefulWidget {
  const _Switch({required this.enabled});

  final bool enabled;

  @override
  State<_Switch> createState() => _SwitchState();
}

class _SwitchState extends State<_Switch> {
  bool _value = true;

  @override
  Widget build(BuildContext context) => ForgeSwitch(
    value: _value,
    onChanged: widget.enabled ? (v) => setState(() => _value = v) : null,
  );
}

class _Checkbox extends StatefulWidget {
  const _Checkbox();

  @override
  State<_Checkbox> createState() => _CheckboxState();
}

class _CheckboxState extends State<_Checkbox> {
  bool _value = true;

  @override
  Widget build(BuildContext context) => ForgeCheckbox(
    value: _value,
    onChanged: (v) => setState(() => _value = v),
  );
}
