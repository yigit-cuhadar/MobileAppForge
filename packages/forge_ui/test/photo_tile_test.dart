import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

import 'test_photo.dart';

void main() {
  Future<void> pump(WidgetTester tester, PhotoTile tile) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(
        body: Center(child: SizedBox(width: 150, child: tile)),
      ),
    ),
  );

  Finder icon(ForgeIconData data) =>
      find.byWidgetPredicate((w) => w is ForgeIcon && w.icon == data);

  testWidgets('a photo is 3:4 with its view label and opens on tap', (
    tester,
  ) async {
    var taps = 0;
    await pump(
      tester,
      PhotoTile(image: photo, label: 'View A', onTap: () => taps++),
    );

    expect(tester.getSize(find.byType(PhotoTile)), const Size(150, 200));
    expect(find.text('View A'), findsOneWidget);
    await tester.tap(find.byType(PhotoTile));
    expect(taps, 1);
  });

  testWidgets('an empty slot keeps its view label and adds on tap', (
    tester,
  ) async {
    var taps = 0;
    await pump(
      tester,
      PhotoTile.empty(
        message: 'Add photo',
        label: 'View D',
        onTap: () => taps++,
      ),
    );

    expect(icon(ForgeIcons.photoCamera), findsOneWidget);
    expect(find.text('View D'), findsOneWidget);
    await tester.tap(find.text('Add photo'));
    expect(taps, 1);
  });

  testWidgets('loading shimmers the 3:4 tile and keeps its view label', (
    tester,
  ) async {
    await pump(tester, const PhotoTile.loading(label: 'View A'));

    expect(tester.getSize(find.byType(SkeletonBar)), const Size(150, 200));
    expect(find.text('View A'), findsOneWidget);
  });

  testWidgets('uploading shows a thin bar at the progress', (tester) async {
    await pump(tester, const PhotoTile.uploading(progress: 0.6));

    final bar = tester.widget<Progress>(find.byType(Progress));
    expect((bar.value, bar.thin), (0.6, true));
    expect(
      tester.getSize(find.byType(Progress)),
      const Size(150 - 2 * Gap.sm, 4),
    );
  });

  testWidgets('failed offers Retry', (tester) async {
    var retries = 0;
    await pump(
      tester,
      PhotoTile.failed(message: 'Upload failed', onRetry: () => retries++),
    );

    expect(icon(ForgeIcons.error), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('offline waits for the connection', (tester) async {
    await pump(
      tester,
      const PhotoTile.offline(message: 'Waiting for connection'),
    );

    expect(icon(ForgeIcons.cloudOff), findsOneWidget);
    expect(find.text('Waiting for connection'), findsOneWidget);
  });
}
