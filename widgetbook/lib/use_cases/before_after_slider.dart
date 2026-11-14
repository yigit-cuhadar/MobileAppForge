import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: BeforeAfterSlider)
Widget beforeAfterSlider(BuildContext context) {
  final colors = ForgeStyle.of(context).colors;
  Widget side(Color color, String label) => ColoredBox(
    color: color,
    child: Center(
      child: Text(label, style: TextStyle(color: colors.onAccent)),
    ),
  );
  return Center(
    child: SizedBox(
      width: 320,
      height: 420,
      child: BeforeAfterSlider(
        before: side(colors.inkMuted, '[BEFORE]'),
        after: side(colors.accent, '[AFTER]'),
      ),
    ),
  );
}
