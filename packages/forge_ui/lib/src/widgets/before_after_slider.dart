import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';
import 'card_frame.dart';
import 'forge_chip.dart';
import 'forge_slider.dart';
import 'photo_tile.dart';

/// One view a [BeforeAfterSlider] compares: two photos of it and their
/// dates, with what changed between them.
class BeforeAfterView {
  const BeforeAfterView({
    required this.name,
    required this.before,
    required this.after,
    required this.beforeDate,
    required this.afterDate,
    required this.change,
  });

  final String name;
  final ImageProvider before;
  final ImageProvider after;
  final String beforeDate;
  final String afterDate;
  final String change;
}

/// A card comparing two photos of the same view, stacked: a slider under
/// the frame fades from the earlier one to the later one, with the two
/// dates at its ends and the shown date and blend on a dark tag. Chips
/// switch between the [views]. It opens on the later photo of the first
/// view.
class BeforeAfterSlider extends StatefulWidget {
  const BeforeAfterSlider({
    super.key,
    required this.views,
    required this.sliderLabel,
  });

  final List<BeforeAfterView> views;

  /// The slider's name for screen readers.
  final String sliderLabel;

  static const double photoHeight = 300;

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  int _view = 0;

  /// The later photo's share, from 0 to 1.
  double _blend = 1;

  void _setBlend(double blend) =>
      setState(() => _blend = blend.clamp(0.0, 1.0));

  @override
  void didUpdateWidget(BeforeAfterSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_view >= widget.views.length) _view = 0;
  }

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final view = widget.views[_view];
    final small = style.data.copyWith(fontSize: 11, height: 14 / 11);
    final percent = '${(_blend * 100).round()}%';
    final shownDate = _blend >= 0.5 ? view.afterDate : view.beforeDate;
    return CardFrame(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Gap.md,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: Gap.sm,
                children: [
                  Expanded(
                    child: Text(
                      view.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium,
                    ),
                  ),
                  // In a narrow card the dates take at most half the row.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth / 2,
                    ),
                    child: Text(
                      '${view.beforeDate} → ${view.afterDate} · ${view.change}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: small.copyWith(color: colors.inkMuted),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: BeforeAfterSlider.photoHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(style.radii.md),
                child: ColoredBox(
                  color: colors.surfaceSunken,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image(image: view.before, fit: BoxFit.cover),
                      Opacity(
                        opacity: _blend,
                        child: Image(image: view.after, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: Gap.sm,
                        right: Gap.sm,
                        child: PhotoTag(
                          label: '$shownDate · $percent',
                          style: small,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              spacing: Gap.sm,
              children: [
                Text(
                  view.beforeDate,
                  style: small.copyWith(color: colors.inkMuted),
                ),
                Expanded(
                  child: Semantics(
                    slider: true,
                    label: widget.sliderLabel,
                    value: percent,
                    increasedValue:
                        '${((_blend + 0.1).clamp(0.0, 1.0) * 100).round()}%',
                    decreasedValue:
                        '${((_blend - 0.1).clamp(0.0, 1.0) * 100).round()}%',
                    onIncrease: () => _setBlend(_blend + 0.1),
                    onDecrease: () => _setBlend(_blend - 0.1),
                    child: SliderArea(
                      onChanged: _setBlend,
                      builder: (context, dragging) => SizedBox(
                        height: ForgeTheme.tapMin,
                        child: Center(
                          child: SliderTrack(
                            fraction: _blend,
                            dragging: dragging,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  view.afterDate,
                  style: small.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                for (var i = 0; i < widget.views.length; i++)
                  ForgeChip(
                    label: widget.views[i].name,
                    selected: i == _view,
                    onPressed: () => setState(() => _view = i),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
