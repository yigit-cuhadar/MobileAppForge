import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';

/// One tab of a [ForgeNavigationBar].
class ForgeDestination {
  const ForgeDestination({required this.icon, required this.label});

  final ForgeIconData icon;
  final String label;
}

/// The plain bottom tab bar on surface-bar. The selected tab takes accent,
/// the heavier icon stroke and a bold label; the others ink-subtle.
class ForgeNavigationBar extends StatelessWidget {
  const ForgeNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ForgeDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double height = 72;

  /// Stroke of an unselected tab's icon.
  static const double _weight = 1.8;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final label = Theme.of(context).textTheme.labelSmall!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceBar,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              for (final (i, destination) in destinations.indexed)
                Expanded(
                  child: _Tab(
                    destination: destination,
                    selected: i == selectedIndex,
                    color: i == selectedIndex
                        ? colors.accent
                        : colors.inkSubtle,
                    style: label,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.destination,
    required this.selected,
    required this.color,
    required this.style,
    required this.onTap,
  });

  final ForgeDestination destination;
  final bool selected;
  final Color color;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: destination.label,
    onTap: onTap,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ForgeIcon(
            destination.icon,
            size: 22,
            color: color,
            weight: selected
                ? ForgeIcon.selectedWeight
                : ForgeNavigationBar._weight,
          ),
          const SizedBox(height: Gap.xs),
          Text(
            destination.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
