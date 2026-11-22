import 'package:material_ui/material_ui.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Week', type: DayBars)
Widget weekDayBars(BuildContext context) {
  final empty = context.knobs.boolean(label: 'Empty week');
  const values = <double>[0, 44, 0, 0, 30, 0, 12];
  return ListView(
    padding: const EdgeInsets.all(Gap.md),
    children: [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          width: 170,
          child: DayBars(
            days: [
              for (final (i, label) in [
                'M',
                'T',
                'W',
                'T',
                'F',
                'S',
                'S',
              ].indexed)
                (label: label, value: empty ? 0.0 : values[i]),
            ],
            color: ForgeStyle.of(context).colors.accent,
            semanticLabel: '[VALUE] per day',
          ),
        ),
      ),
    ],
  );
}
