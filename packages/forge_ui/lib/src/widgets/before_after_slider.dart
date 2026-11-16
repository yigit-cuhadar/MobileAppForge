import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';
import 'card_frame.dart';
import 'forge_chip.dart';
import 'forge_slider.dart';
import 'photo_tile.dart';
import 'skeleton.dart';

/// One side of a [BeforeAfterView]: a photo, a photo still being fetched
/// (it shimmers), or a missing photo drawn as a sunken frame with a text
/// such as "No photo". Every form fades like a photo.
class ComparedPhoto {
  const ComparedPhoto(ImageProvider this.image) : missing = null;

  /// No photo to show: [missing] says why.
  const ComparedPhoto.missing(String this.missing) : image = null;

  /// The photo is being fetched.
  const ComparedPhoto.loading() : image = null, missing = null;

  final ImageProvider? image;
  final String? missing;
}

/// One view a [BeforeAfterSlider] shows: two photos of it and their dates,
/// with what changed between them, or [BeforeAfterView.single] one photo
/// and its date, without a slider.
class BeforeAfterView {
  const BeforeAfterView({
    required this.name,
    required this.before,
    required ComparedPhoto this.after,
    required this.beforeDate,
    required String this.afterDate,
    required String this.change,
  });

  const BeforeAfterView.single({
    required this.name,
    required ComparedPhoto photo,
    required String date,
  }) : before = photo,
       beforeDate = date,
       after = null,
       afterDate = null,
       change = null;

  final String name;
  final ComparedPhoto before;
  final ComparedPhoto? after;
  final String beforeDate;
  final String? afterDate;
  final String? change;
}

/// A card comparing two photos of the same view, stacked: a slider under
/// the frame fades from the earlier one to the later one, with the two
/// dates at its ends and the shown date and blend on a dark tag. A single
/// view shows its one photo with its date on the tag and no slider. Chips
/// switch between the [views]. It opens on the later photo of the first
/// view.
class BeforeAfterSlider extends StatefulWidget {
  const BeforeAfterSlider({
    super.key,
    required List<BeforeAfterView> this.views,
    required String this.sliderLabel,
  });

  /// A shimmering frame and slider while the views load.
  const BeforeAfterSlider.loading({super.key})
    : views = null,
      sliderLabel = null;

  final List<BeforeAfterView>? views;

  /// The slider's name for screen readers.
  final String? sliderLabel;

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
    if (_view >= (widget.views?.length ?? 0)) _view = 0;
  }

  @override
  Widget build(BuildContext context) {
    final views = widget.views;
    return CardFrame(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Gap.md,
          children: views == null ? _loading(context) : _filled(views),
        ),
      ),
    );
  }

  List<Widget> _loading(BuildContext context) => [
    SkeletonBar(
      widthFactor: 1,
      height: BeforeAfterSlider.photoHeight,
      radius: ForgeStyle.of(context).radii.sm,
    ),
    const SkeletonBar(widthFactor: 1, height: 6),
  ];

  List<Widget> _filled(List<BeforeAfterView> views) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final view = views[_view];
    final after = view.after;
    final small = style.data.copyWith(fontSize: 11, height: 14 / 11);
    final percent = '${(_blend * 100).round()}%';
    final String detail;
    final String tag;
    if (after == null) {
      detail = view.beforeDate;
      tag = view.beforeDate;
    } else {
      detail = '${view.beforeDate} → ${view.afterDate} · ${view.change}';
      tag = '${_blend >= 0.5 ? view.afterDate : view.beforeDate} · $percent';
    }
    return [
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
              constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
              child: Text(
                detail,
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
                _Side(view.before),
                if (after != null)
                  Opacity(opacity: _blend, child: _Side(after)),
                Positioned(
                  top: Gap.sm,
                  right: Gap.sm,
                  child: PhotoTag(label: tag, style: small),
                ),
              ],
            ),
          ),
        ),
      ),
      if (after != null)
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
                      child: SliderTrack(fraction: _blend, dragging: dragging),
                    ),
                  ),
                ),
              ),
            ),
            Text(
              view.afterDate!,
              style: small.copyWith(color: colors.inkMuted),
            ),
          ],
        ),
      Wrap(
        spacing: Gap.sm,
        runSpacing: Gap.sm,
        children: [
          for (var i = 0; i < views.length; i++)
            ForgeChip(
              label: views[i].name,
              selected: i == _view,
              onPressed: () => setState(() => _view = i),
            ),
        ],
      ),
    ];
  }
}

/// One side filling the frame. A missing side is opaque so it fades over
/// the other like a photo.
class _Side extends StatelessWidget {
  const _Side(this.photo);

  final ComparedPhoto photo;

  @override
  Widget build(BuildContext context) {
    if (photo.image case final image?) {
      return Image(image: image, fit: BoxFit.cover);
    }
    if (photo.missing case final missing?) {
      return ColoredBox(
        color: ForgeStyle.of(context).colors.surfaceSunken,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Gap.md),
            child: Text(
              missing,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      );
    }
    return const SkeletonBar(
      widthFactor: 1,
      height: BeforeAfterSlider.photoHeight,
      radius: 0,
    );
  }
}
