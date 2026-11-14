import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

const _all = [
  ForgeIcons.add,
  ForgeIcons.arrowUpward,
  ForgeIcons.autoAwesome,
  ForgeIcons.backspace,
  ForgeIcons.barChart,
  ForgeIcons.block,
  ForgeIcons.check,
  ForgeIcons.checkCircle,
  ForgeIcons.chevronLeft,
  ForgeIcons.chevronRight,
  ForgeIcons.close,
  ForgeIcons.cloudOff,
  ForgeIcons.cloudUpload,
  ForgeIcons.compare,
  ForgeIcons.contentCopy,
  ForgeIcons.delete,
  ForgeIcons.description,
  ForgeIcons.directionsRun,
  ForgeIcons.directionsWalk,
  ForgeIcons.dragHandle,
  ForgeIcons.dragIndicator,
  ForgeIcons.edit,
  ForgeIcons.editCalendar,
  ForgeIcons.emojiEvents,
  ForgeIcons.error,
  ForgeIcons.event,
  ForgeIcons.expandLess,
  ForgeIcons.expandMore,
  ForgeIcons.favorite,
  ForgeIcons.filterList,
  ForgeIcons.fitnessCenter,
  ForgeIcons.flipCamera,
  ForgeIcons.getApp,
  ForgeIcons.help,
  ForgeIcons.history,
  ForgeIcons.home,
  ForgeIcons.hourglassEmpty,
  ForgeIcons.image,
  ForgeIcons.inbox,
  ForgeIcons.info,
  ForgeIcons.lightbulb,
  ForgeIcons.list,
  ForgeIcons.lock,
  ForgeIcons.mail,
  ForgeIcons.monitorWeight,
  ForgeIcons.moreHoriz,
  ForgeIcons.moreVert,
  ForgeIcons.noPhotography,
  ForgeIcons.notifications,
  ForgeIcons.notificationsOff,
  ForgeIcons.openInNew,
  ForgeIcons.person,
  ForgeIcons.photoCamera,
  ForgeIcons.remove,
  ForgeIcons.removeCircle,
  ForgeIcons.search,
  ForgeIcons.showChart,
  ForgeIcons.star,
  ForgeIcons.stopCircle,
  ForgeIcons.straighten,
  ForgeIcons.sync,
  ForgeIcons.timer,
  ForgeIcons.today,
  ForgeIcons.trendingUp,
  ForgeIcons.tune,
  ForgeIcons.warning,
];

void main() {
  testWidgets('draws every icon in the set', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(children: [for (final icon in _all) ForgeIcon(icon)]),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(ForgeIcon), findsNWidgets(_all.length));
  });

  testWidgets('takes the icon theme size and colour', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: IconTheme(
          data: IconThemeData(size: 22, color: Color(0xFF222B38)),
          child: Center(child: ForgeIcon(ForgeIcons.search)),
        ),
      ),
    );
    expect(tester.getSize(find.byType(ForgeIcon)), const Size(22, 22));
  });

  testWidgets('a semantic label is read out', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: ForgeIcon(ForgeIcons.close, semanticLabel: 'Close'),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Close'), findsOneWidget);
  });
}
