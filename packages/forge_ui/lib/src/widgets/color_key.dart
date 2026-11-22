import 'package:material_ui/material_ui.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';

/// One entry of a [ColorKey]: a colour the card uses and what it means.
class ColorKeyEntry {
  const ColorKeyEntry(this.color, this.label);

  final Color color;
  final String label;
}

/// What a card's colours mean: a 10px swatch before each label, the
/// entries spread across one row; they wrap when they do not fit (larger
/// text).
class ColorKey extends StatelessWidget {
  const ColorKey({super.key, required this.entries});

  final List<ColorKeyEntry> entries;

  static const double _swatch = 10;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final label = Theme.of(context).textTheme.labelMedium!
        .copyWith(fontWeight: FontWeight.w400, color: style.colors.ink);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: Gap.md,
      runSpacing: Gap.xs,
      children: [
        for (final entry in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Container(
                width: _swatch,
                height: _swatch,
                decoration: BoxDecoration(
                  color: entry.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Text(entry.label, style: label),
            ],
          ),
      ],
    );
  }
}
