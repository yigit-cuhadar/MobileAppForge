import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';

/// Opens a [ForgeMenu] under the widget of [context] (its more button),
/// right edges aligned. A row closes the menu, then runs its [onTap];
/// a tap outside closes it.
Future<void> showForgeMenu({
  required BuildContext context,
  required List<ForgeMenuItem> items,
}) => _showUnder(
  context,
  gap: 0,
  builder: (menuContext) => ForgeMenu(
    items: [
      for (final item in items)
        ForgeMenuItem(
          label: item.label,
          destructive: item.destructive,
          selected: item.selected,
          onTap: () {
            Navigator.pop(menuContext);
            item.onTap();
          },
        ),
    ],
  ),
);

/// Opens a [ForgeInfoCard] under the tapped value of [context], right edges
/// aligned; a tap outside closes it.
Future<void> showForgeInfo({
  required BuildContext context,
  required String title,
  required List<(String, String)> facts,
}) => _showUnder(
  context,
  gap: Gap.sm,
  builder: (_) => ForgeInfoCard(title: title, facts: facts),
);

/// One row of a [ForgeMenu].
class ForgeMenuItem {
  const ForgeMenuItem({
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;

  /// In danger; it sits last.
  final bool destructive;

  /// Ticked: the current choice.
  final bool selected;
}

/// A small floating menu: plain text rows split by lines, no icons, one
/// group, a destructive action last.
class ForgeMenu extends StatelessWidget {
  ForgeMenu({super.key, required this.items})
    : assert(
        items.every((item) => !item.destructive || item == items.last),
        'Only the last row may be destructive.',
      );

  final List<ForgeMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final body = Theme.of(context).textTheme.bodyMedium!;
    return _Floating(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, item) in items.indexed)
            Semantics(
              selected: item.selected,
              child: InkWell(
                onTap: item.onTap,
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: ForgeTheme.tapMin,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: Gap.md),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : Border(top: BorderSide(color: colors.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          style: body.copyWith(
                            color: item.destructive
                                ? colors.danger
                                : colors.ink,
                          ),
                        ),
                      ),
                      if (item.selected)
                        ForgeIcon(
                          ForgeIcons.check,
                          size: 16,
                          color: colors.ink,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The info form: a title line and rows of facts, label left and value
/// right in mono; no actions.
class ForgeInfoCard extends StatelessWidget {
  const ForgeInfoCard({super.key, required this.title, required this.facts});

  final String title;

  /// Label and value of each row.
  final List<(String, String)> facts;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final body = Theme.of(context).textTheme.bodyMedium!;
    return _Floating(
      child: Semantics(
        label: title,
        explicitChildNodes: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm),
                child: Text(
                  title,
                  style: body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              for (final (label, value) in facts)
                Container(
                  constraints: const BoxConstraints(minHeight: 36),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.line)),
                  ),
                  child: Row(
                    spacing: Gap.md,
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: body.copyWith(color: colors.inkMuted),
                        ),
                      ),
                      Text(
                        value,
                        style: style.data.copyWith(
                          fontSize: 14,
                          color: colors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The floating surface both forms share: 240 wide, line border, a soft
/// shadow.
class _Floating extends StatelessWidget {
  const _Floating({required this.child});

  final Widget child;

  static const double width = 240;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final radius = BorderRadius.circular(style.radii.md);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: style.colors.surface,
        borderRadius: radius,
        border: Border.all(color: style.colors.line),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.14),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

Future<void> _showUnder(
  BuildContext context, {
  required double gap,
  required WidgetBuilder builder,
}) {
  final navigator = Navigator.of(context);
  final box = context.findRenderObject()! as RenderBox;
  final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
  final anchor = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
  return navigator.push(
    _UnderRoute(
      anchor: anchor,
      gap: gap,
      builder: builder,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    ),
  );
}

class _UnderRoute extends PopupRoute<void> {
  _UnderRoute({
    required this.anchor,
    required this.gap,
    required this.builder,
    required this.barrierLabel,
  });

  final Rect anchor;
  final double gap;
  final WidgetBuilder builder;

  @override
  final String barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => CustomSingleChildLayout(
    delegate: _UnderLayout(anchor, gap),
    child: Builder(builder: builder),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: animation, child: child);
}

/// Places the child under [anchor] with right edges aligned, inside the
/// screen's gutter; above it when there is no room below.
class _UnderLayout extends SingleChildLayoutDelegate {
  _UnderLayout(this.anchor, this.gap);

  final Rect anchor;
  final double gap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen().deflate(const EdgeInsets.all(Gap.md));

  @override
  Offset getPositionForChild(Size size, Size child) {
    final x = (anchor.right - child.width).clamp(
      Gap.md,
      size.width - Gap.md - child.width,
    );
    final below = anchor.bottom + gap;
    final y = below + child.height <= size.height - Gap.md
        ? below
        : anchor.top - gap - child.height;
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_UnderLayout old) =>
      old.anchor != anchor || old.gap != gap;
}
