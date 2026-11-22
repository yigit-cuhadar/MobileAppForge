import 'package:material_ui/material_ui.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Three entries', type: ColorKey)
Widget threeColorKey(BuildContext context) {
  final colors = ForgeStyle.of(context).colors;
  return ListView(
    padding: const EdgeInsets.all(Gap.md),
    children: [
      ColorKey(
        entries: [
          ColorKeyEntry(colors.accentSoft, 'Under [VALUE] · 4'),
          ColorKeyEntry(colors.accent, '[VALUE]–[VALUE] · 0'),
          ColorKeyEntry(colors.danger, 'Over [VALUE] · 0'),
        ],
      ),
    ],
  );
}
