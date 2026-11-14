import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_preset.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';
import 'pressable.dart';

/// A grey 44px search pill with a clear button while it holds text. With
/// [onFilters], a round filter button sits beside it, with a badge counting
/// the [activeFilters].
class ForgeSearchField extends StatefulWidget {
  const ForgeSearchField({
    super.key,
    required this.hint,
    required this.clearLabel,
    required this.onChanged,
    this.controller,
    this.onFilters,
    this.filtersLabel,
    this.activeFilters = 0,
  }) : assert(onFilters == null || filtersLabel != null);

  final String hint;

  /// The clear button's name for screen readers.
  final String clearLabel;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final VoidCallback? onFilters;

  /// The filter button's name for screen readers.
  final String? filtersLabel;
  final int activeFilters;

  @override
  State<ForgeSearchField> createState() => _ForgeSearchFieldState();
}

class _ForgeSearchFieldState extends State<ForgeSearchField> {
  final _focus = FocusNode();
  TextEditingController? _own;

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
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _focus.dispose();
    _own?.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final p = style.colors;
    final body = Theme.of(context).textTheme.bodyMedium!;
    final pill = Container(
      height: ForgeTheme.tapMin,
      padding: const EdgeInsetsDirectional.only(start: Gap.md, end: Gap.sm),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: BorderRadius.circular(ForgeTheme.tapMin / 2),
      ),
      // Always set, so focusing does not rebuild the field below it.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ForgeTheme.tapMin / 2),
        border: _focus.hasFocus ? Border.all(color: p.accent, width: 2) : null,
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
              decoration: InputDecoration.collapsed(
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
    );
    if (widget.onFilters == null) return pill;
    return Row(
      spacing: Gap.sm,
      children: [
        Expanded(child: pill),
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
