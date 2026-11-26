import 'package:material_ui/material_ui.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';

/// One benefit of [BenefitList.described]: its [icon], a [title] and one
/// [detail] line.
typedef DescribedBenefit = ({ForgeIconData icon, String title, String detail});

/// A short list of benefits, one line each. [BenefitList.numbered] marks
/// each line with its number in an accent-soft circle (a welcome), or a
/// danger-tinted one with [danger] (a list of mistakes), and may end a line
/// with its own [trailing] widget (a button);
/// [BenefitList.checked] with a success check (a card's short list);
/// [BenefitList.described] gives each an icon tile, a title and a muted
/// line (a paywall header with few benefits).
class BenefitList extends StatelessWidget {
  const BenefitList.numbered(
    this.lines, {
    super.key,
    this.danger = false,
    this.trailing = const {},
  }) : _numbered = true,
       described = const [];

  const BenefitList.checked(this.lines, {super.key})
    : _numbered = false,
      danger = false,
      trailing = const {},
      described = const [];

  const BenefitList.described(this.described, {super.key})
    : lines = const [],
      danger = false,
      trailing = const {},
      _numbered = false;

  final List<String> lines;
  final List<DescribedBenefit> described;
  final bool danger;

  /// The widget ending a line, by the line's index.
  final Map<int, Widget> trailing;
  final bool _numbered;

  static const double _tile = 44;

  static const double _circle = 28;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    if (described.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.md,
        children: [
          for (final benefit in described)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Gap.md,
              children: [
                Container(
                  width: _tile,
                  height: _tile,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.surfaceSunken,
                    borderRadius: BorderRadius.circular(style.radii.md),
                  ),
                  child: ForgeIcon(benefit.icon, size: 22, color: colors.ink),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(benefit.title, style: text.titleMedium),
                      Text(
                        benefit.detail,
                        style: text.bodyMedium!.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: _numbered ? Gap.md : Gap.sm,
      children: [
        for (final (i, line) in lines.indexed)
          Row(
            spacing: _numbered ? Gap.md : Gap.sm,
            children: [
              if (_numbered)
                Container(
                  width: _circle,
                  height: _circle,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: danger
                        ? Color.lerp(colors.surface, colors.danger, 0.12)
                        : colors.accentSoft,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: style.data.copyWith(
                      color: danger
                          ? Color.lerp(colors.ink, colors.danger, 0.7)
                          : colors.onAccentSoft,
                    ),
                  ),
                )
              else
                ForgeIcon(ForgeIcons.check, size: 16, color: colors.success),
              Expanded(
                child: Text(
                  line,
                  style: _numbered ? text.bodyLarge : text.bodyMedium,
                ),
              ),
              ?trailing[i],
            ],
          ),
      ],
    );
  }
}
