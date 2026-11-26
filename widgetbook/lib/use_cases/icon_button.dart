import 'package:material_ui/material_ui.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _row(List<Widget> buttons) => Center(
  child: Row(mainAxisSize: MainAxisSize.min, children: buttons),
);

@widgetbook.UseCase(name: 'Muted', type: ForgeIconButton)
Widget mutedIconButtons(BuildContext context) => _row([
  ForgeIconButton(icon: ForgeIcons.close, label: 'Remove', onPressed: () {}),
  ForgeIconButton(icon: ForgeIcons.help, label: 'Help', onPressed: () {}),
  ForgeIconButton(icon: ForgeIcons.moreHoriz, label: 'More', onPressed: () {}),
]);

@widgetbook.UseCase(name: 'Ink', type: ForgeIconButton)
Widget inkIconButtons(BuildContext context) => _row([
  ForgeIconButton(
    icon: ForgeIcons.chevronLeft,
    label: 'Back',
    onPressed: () {},
    variant: ForgeIconButtonVariant.ink,
  ),
  ForgeIconButton(
    icon: ForgeIcons.playArrow,
    label: 'Start',
    onPressed: () {},
    variant: ForgeIconButtonVariant.ink,
  ),
]);

@widgetbook.UseCase(name: 'On featured', type: ForgeIconButton)
Widget onFeaturedIconButton(BuildContext context) {
  final style = ForgeStyle.of(context);
  return Center(
    child: Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: style.colors.featured,
        borderRadius: BorderRadius.circular(style.radii.lg),
      ),
      child: ForgeIconButton(
        icon: ForgeIcons.moreHoriz,
        label: 'More',
        onPressed: () {},
        variant: ForgeIconButtonVariant.onFeatured,
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'Disabled', type: ForgeIconButton)
Widget disabledIconButton(BuildContext context) => _row(const [
  ForgeIconButton(icon: ForgeIcons.close, label: 'Remove', onPressed: null),
  ForgeIconButton(
    icon: ForgeIcons.playArrow,
    label: 'Start',
    onPressed: null,
    variant: ForgeIconButtonVariant.ink,
  ),
]);

@widgetbook.UseCase(name: 'Toggled', type: ForgeIconButton)
Widget toggledIconButtons(BuildContext context) => const _Toggled();

/// Off and on side by side; each switches when tapped.
class _Toggled extends StatefulWidget {
  const _Toggled();

  @override
  State<_Toggled> createState() => _ToggledState();
}

class _ToggledState extends State<_Toggled> {
  final _on = [false, true];

  @override
  Widget build(BuildContext context) => _row([
    for (final (i, on) in _on.indexed)
      ForgeIconButton(
        icon: ForgeIcons.star,
        label: 'Favourite',
        toggled: on,
        onPressed: () => setState(() => _on[i] = !on),
      ),
  ]);
}

@widgetbook.UseCase(name: 'Sunken', type: ForgeIconButton)
Widget sunkenIconButton(BuildContext context) => _row([
  ForgeIconButton(
    icon: ForgeIcons.playArrow,
    label: 'Play',
    variant: ForgeIconButtonVariant.ink,
    fill: ForgeIconButtonFill.sunken,
    onPressed: () {},
  ),
  ForgeIconButton(icon: ForgeIcons.moreHoriz, label: 'More', onPressed: () {}),
]);

@widgetbook.UseCase(name: 'Surface, over a picture', type: ForgeIconButton)
Widget surfaceIconButtons(BuildContext context) => const _OverPicture();

/// Pause or play, and a speed that switches, in a picture's corner.
class _OverPicture extends StatefulWidget {
  const _OverPicture();

  @override
  State<_OverPicture> createState() => _OverPictureState();
}

class _OverPictureState extends State<_OverPicture> {
  var _playing = true;
  var _slow = false;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    return Center(
      child: Container(
        width: 320,
        height: 200,
        alignment: Alignment.bottomRight,
        padding: const EdgeInsets.all(Gap.xs),
        decoration: BoxDecoration(
          color: style.colors.surfaceSunken,
          borderRadius: BorderRadius.circular(style.radii.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: Gap.xs,
          children: [
            ForgeIconButton(
              icon: _playing ? ForgeIcons.pause : ForgeIcons.playArrow,
              label: _playing ? 'Pause' : 'Play',
              variant: ForgeIconButtonVariant.ink,
              fill: ForgeIconButtonFill.surface,
              onPressed: () => setState(() => _playing = !_playing),
            ),
            ForgeIconButton.text(
              '0.5×',
              label: 'Half speed',
              variant: ForgeIconButtonVariant.ink,
              fill: ForgeIconButtonFill.surface,
              toggled: _slow,
              onPressed: () => setState(() => _slow = !_slow),
            ),
          ],
        ),
      ),
    );
  }
}
