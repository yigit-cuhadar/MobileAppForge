import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';

/// A short list of benefits, one line each. [BenefitList.numbered] marks
/// each line with its number in an accent-soft circle (a welcome);
/// [BenefitList.checked] with a success check (a paywall header).
class BenefitList extends StatelessWidget {
  const BenefitList.numbered(this.lines, {super.key}) : _numbered = true;

  const BenefitList.checked(this.lines, {super.key}) : _numbered = false;

  final List<String> lines;
  final bool _numbered;

  static const double _circle = 28;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
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
                    color: colors.accentSoft,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: style.data.copyWith(color: colors.onAccentSoft),
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
            ],
          ),
      ],
    );
  }
}
