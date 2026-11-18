import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_preset.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';
import 'pressable.dart';
import 'bare_decoration.dart';

/// A grey 44px search pill with a clear button while it holds text. With
/// [onFilters], a round filter button sits beside it, with a badge counting
/// the [activeFilters]. Two fields with the same [heroTag] on two routes
/// fly between them: only the pill flies, its width easing from one end to
/// the other, while the filter button moves with its page. A [summary]
/// (a chip naming the filters scrolled away) sits between the pill and the
/// filter button.
class ForgeSearchField extends StatefulWidget {
  const ForgeSearchField({
    super.key,
    required this.hint,
    required String this.clearLabel,
    required ValueChanged<String> this.onChanged,
    this.controller,
    this.focusNode,
    this.onFilters,
    this.filtersLabel,
    this.activeFilters = 0,
    this.heroTag,
    this.summary,
  }) : assert(onFilters == null || filtersLabel != null),
       onTap = null;

  /// The pill with its [hint] only, never editable: [onTap] opens the page
  /// where the search happens.
  const ForgeSearchField.tapOnly({
    super.key,
    required this.hint,
    required VoidCallback this.onTap,
    this.heroTag,
  }) : clearLabel = null,
       onChanged = null,
       controller = null,
       focusNode = null,
       onFilters = null,
       filtersLabel = null,
       activeFilters = 0,
       summary = null;

  final String hint;

  /// The clear button's name for screen readers.
  final String? clearLabel;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  /// Lets the page focus the field, such as once its route has slid in.
  final FocusNode? focusNode;
  final VoidCallback? onFilters;

  /// The filter button's name for screen readers.
  final String? filtersLabel;
  final int activeFilters;
  final VoidCallback? onTap;
  final Object? heroTag;
  final Widget? summary;

  @override
  State<ForgeSearchField> createState() => _ForgeSearchFieldState();
}

class _ForgeSearchFieldState extends State<ForgeSearchField> {
  FocusNode? _ownFocus;
  TextEditingController? _own;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_refresh);
    _controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(ForgeSearchField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _own)?.removeListener(_refresh);
      _controller.addListener(_refresh);
    }
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_refresh);
      _focus.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _focus.removeListener(_refresh);
    _ownFocus?.dispose();
    _own?.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged!('');
  }

  Widget _tapOnly(BuildContext context) => _hero(
    Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: _HintPill(widget.hint),
      ),
    ),
  );

  /// [pill] in a Hero under [ForgeSearchField.heroTag], flying as the bare
  /// pill on a straight path so it never sweeps over a neighbour.
  Widget _hero(Widget pill) {
    final tag = widget.heroTag;
    if (tag == null) return pill;
    return Hero(
      tag: tag,
      createRectTween: (begin, end) => RectTween(begin: begin, end: end),
      flightShuttleBuilder: (_, _, _, _, _) => _HintPill(widget.hint),
      child: pill,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final p = style.colors;
    final body = Theme.of(context).textTheme.bodyMedium!;
    if (widget.onTap != null) return _tapOnly(context);
    final pill = _hero(
      Container(
        height: ForgeTheme.tapMin,
        padding: const EdgeInsetsDirectional.only(start: Gap.md, end: Gap.sm),
        decoration: BoxDecoration(
          color: p.surfaceSunken,
          borderRadius: BorderRadius.circular(ForgeTheme.tapMin / 2),
        ),
        // Always set, so focusing does not rebuild the field below it.
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ForgeTheme.tapMin / 2),
          border: _focus.hasFocus
              ? Border.all(color: p.accent, width: 2)
              : null,
        ),
        child: Row(
          spacing: Gap.sm,
          children: [
            ForgeIcon(ForgeIcons.search, size: 18, color: p.inkMuted),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                onChanged: widget.onChanged,
                textInputAction: TextInputAction.search,
                style: body.copyWith(color: p.ink),
                decoration: bareDecoration(
                  hintText: widget.hint,
                  hintStyle: body.copyWith(color: p.inkSubtle),
                ),
              ),
            ),
            if (_controller.text.isNotEmpty)
              Semantics(
                button: true,
                label: widget.clearLabel,
                child: Pressable(
                  onTap: _clear,
                  height: 32,
                  builder: (context, _) => Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.surfaceSunken,
                      shape: BoxShape.circle,
                    ),
                    child: ForgeIcon(
                      ForgeIcons.close,
                      size: 16,
                      weight: 2.4,
                      color: p.ink,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    final summary = widget.summary;
    if (widget.onFilters == null && summary == null) return pill;
    return Row(
      spacing: Gap.sm,
      children: [
        Expanded(child: pill),
        ?summary,
        if (widget.onFilters != null)
          Semantics(
            button: true,
            label: widget.filtersLabel,
            value: widget.activeFilters > 0 ? '${widget.activeFilters}' : null,
            child: GestureDetector(
              onTap: widget.onFilters,
              child: Container(
                width: ForgeTheme.tapMin,
                height: ForgeTheme.tapMin,
                decoration: BoxDecoration(
                  color: p.surfaceSunken,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ForgeIcon(ForgeIcons.filterList, size: 18, color: p.ink),
                    if (widget.activeFilters > 0)
                      PositionedDirectional(
                        top: Gap.xs,
                        end: Gap.xs,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 16),
                          height: 16,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.accent,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(ForgeRadii.button),
                            ),
                          ),
                          child: ExcludeSemantics(
                            child: Text(
                              '${widget.activeFilters}',
                              style: style.data.copyWith(
                                fontSize: 10,
                                height: 1,
                                color: p.onAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The grey pill holding the search icon and [hint]: the tap-only form, and
/// the shuttle that flies between two fields.
class _HintPill extends StatelessWidget {
  const _HintPill(this.hint);

  final String hint;

  @override
  Widget build(BuildContext context) {
    final p = ForgeStyle.of(context).colors;
    return Container(
      height: ForgeTheme.tapMin,
      padding: const EdgeInsetsDirectional.only(start: Gap.md, end: Gap.sm),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: BorderRadius.circular(ForgeTheme.tapMin / 2),
      ),
      child: Row(
        spacing: Gap.sm,
        children: [
          ForgeIcon(ForgeIcons.search, size: 18, color: p.inkMuted),
          Expanded(
            child: Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(color: p.inkSubtle),
            ),
          ),
        ],
      ),
    );
  }
}
