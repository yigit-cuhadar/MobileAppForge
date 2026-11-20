import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_app_gate/forge_app_gate.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockAppGateCubit extends MockCubit<AppGateState>
    implements AppGateCubit {}

const strings = AppGateStrings();
final v15 = Version.tryParse('1.5')!;

void main() {
  late MockAppGateCubit cubit;
  late StreamController<AppGateState> states;

  setUp(() {
    cubit = MockAppGateCubit();
    states = StreamController();
    when(() => cubit.resumed()).thenAnswer((_) async {});
    when(() => cubit.retry()).thenAnswer((_) async {});
    when(() => cubit.dismissUpdate()).thenAnswer((_) async {});
    when(() => cubit.openStore()).thenAnswer((_) async {});
  });

  tearDown(() => states.close());

  Future<void> pump(WidgetTester tester, AppGateStatus status) async {
    whenListen(
      cubit,
      states.stream,
      initialState: AppGateState(status: status),
    );
    await tester.pumpWidget(
      BlocProvider<AppGateCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: ForgeTheme.light(),
          builder: (context, child) => AppGate(strings: strings, child: child!),
          home: const Scaffold(body: Text('App')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('open shows the app', (tester) async {
    await pump(tester, const AppOpen());

    expect(find.text('App'), findsOneWidget);
    expect(find.text(strings.update), findsNothing);
  });

  group('update required', () {
    testWidgets('hides the app; Update opens the store', (tester) async {
      await pump(tester, const UpdateRequired());

      expect(find.text('App'), findsNothing);
      expect(find.text(strings.updateRequiredTitle), findsOneWidget);
      await tester.tap(find.text(strings.update));
      verify(() => cubit.openStore()).called(1);
    });

    testWidgets('Back does nothing', (tester) async {
      await pump(tester, const UpdateRequired());

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text(strings.updateRequiredTitle), findsOneWidget);
    });
  });

  group('maintenance', () {
    testWidgets("shows the server's message; Try again retries", (
      tester,
    ) async {
      await pump(tester, const Maintenance('Back at 10:00'));

      expect(find.text('App'), findsNothing);
      expect(find.text(strings.maintenanceTitle), findsOneWidget);
      expect(find.text('Back at 10:00'), findsOneWidget);
      await tester.tap(find.text(strings.retry));
      verify(() => cubit.retry()).called(1);
    });

    testWidgets("shows the app's message without one", (tester) async {
      await pump(tester, const Maintenance(''));

      expect(find.text(strings.maintenanceMessage), findsOneWidget);
      expect(await tester.binding.handlePopRoute(), isTrue);
    });

    testWidgets('the app comes back when it ends', (tester) async {
      await pump(tester, const Maintenance(''));

      states.add(const AppGateState());
      await tester.pumpAndSettle();

      expect(find.text('App'), findsOneWidget);
      expect(find.text(strings.maintenanceTitle), findsNothing);
      expect(await tester.binding.handlePopRoute(), isFalse);
    });
  });

  group('update recommended', () {
    testWidgets('a sheet over the app; Update opens the store', (tester) async {
      await pump(tester, UpdateRecommended(v15));

      expect(find.text('App'), findsOneWidget);
      expect(find.text(strings.updateAvailableTitle), findsOneWidget);
      await tester.tap(find.text(strings.update));
      verify(() => cubit.openStore()).called(1);
    });

    testWidgets('Later dismisses it', (tester) async {
      await pump(tester, UpdateRecommended(v15));

      await tester.tap(find.text(strings.later));
      verify(() => cubit.dismissUpdate()).called(1);
    });

    testWidgets('a swipe down dismisses it', (tester) async {
      await pump(tester, UpdateRecommended(v15));

      await tester.fling(
        find.text(strings.updateAvailableTitle),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();
      verify(() => cubit.dismissUpdate()).called(1);
    });

    testWidgets('a tap on the scrim dismisses it', (tester) async {
      await pump(tester, UpdateRecommended(v15));

      await tester.tapAt(const Offset(20, 20));
      verify(() => cubit.dismissUpdate()).called(1);
    });

    testWidgets('Back dismisses it', (tester) async {
      await pump(tester, UpdateRecommended(v15));

      expect(await tester.binding.handlePopRoute(), isTrue);
      verify(() => cubit.dismissUpdate()).called(1);
    });

    testWidgets('slides in when an offer arrives', (tester) async {
      await pump(tester, const AppOpen());

      states.add(AppGateState(status: UpdateRecommended(v15)));
      await tester.pumpAndSettle();

      expect(find.text(strings.updateAvailableTitle), findsOneWidget);
      expect(
        tester.getBottomLeft(find.byType(BottomSheet)).dy,
        tester.view.physicalSize.height / tester.view.devicePixelRatio,
      );
    });
  });

  testWidgets('checks again on resume', (tester) async {
    await pump(tester, const AppOpen());

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    verify(() => cubit.resumed()).called(1);
  });
}
