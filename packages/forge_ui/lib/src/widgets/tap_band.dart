import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme/forge_theme.dart';

/// Lets a [TapBandArea] find its small control when hit-testing.
class TapBandLink {
  RenderBox? target;
}

/// Marks a small control for its [TapBandArea].
class TapBandTarget extends SingleChildRenderObjectWidget {
  const TapBandTarget({super.key, required this.link, required super.child});

  final TapBandLink link;

  @override
  RenderProxyBox createRenderObject(BuildContext context) =>
      RenderTapBandTarget(link);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTapBandTarget renderObject,
  ) => renderObject.link = link;
}

class RenderTapBandTarget extends RenderProxyBox {
  RenderTapBandTarget(TapBandLink link) {
    this.link = link;
  }

  set link(TapBandLink link) => link.target = this;
}

/// Sends touches within a tap-min square around each linked control to
/// that control, though it is drawn smaller and the layout stays as drawn.
class TapBandArea extends SingleChildRenderObjectWidget {
  const TapBandArea({super.key, required this.links, required super.child});

  final List<TapBandLink> links;

  @override
  RenderProxyBox createRenderObject(BuildContext context) =>
      RenderTapBandArea(links);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTapBandArea renderObject,
  ) => renderObject.links = links;
}

class RenderTapBandArea extends RenderProxyBox {
  RenderTapBandArea(this.links);

  List<TapBandLink> links;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.contains(position)) {
      for (final link in links) {
        final target = link.target;
        if (target == null || !target.attached || !target.hasSize) continue;
        final local = target.globalToLocal(localToGlobal(position));
        final centre = target.size.center(Offset.zero);
        final area = Rect.fromCenter(
          center: centre,
          width: max(ForgeTheme.tapMin, target.size.width),
          height: max(ForgeTheme.tapMin, target.size.height),
        );
        if (area.contains(local)) {
          target.hitTest(result, position: centre);
          result.add(BoxHitTestEntry(this, position));
          return true;
        }
      }
    }
    return super.hitTest(result, position: position);
  }
}
