import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/app_gate_status.dart';
import 'app_gate_cubit.dart';
import 'app_gate_pages.dart';
import 'app_gate_strings.dart';

/// Shows the [AppGateCubit] read from the context around the app's
/// [child]: the update or maintenance page in its place, where Back does
/// nothing, or the sheet offering an update over it, which Later, a swipe
/// down, a tap on the scrim or Back dismisses. Checks again whenever the
/// app resumes.
///
/// Put it in `MaterialApp.builder`, around the router's navigator: the app
/// stays mounted, hidden, while a page is up, and comes back as it was.
class AppGate extends StatefulWidget {
  const AppGate({super.key, required this.strings, required this.child});

  final AppGateStrings strings;
  final Widget child;

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final AppLifecycleListener _lifecycle;
  late final AnimationController _sheet = BottomSheet.createAnimationController(
    this,
  );

  AppGateCubit get _cubit => context.read<AppGateCubit>();

  @override
  void initState() {
    super.initState();
    // Registered before the router's, which is built under this widget, so
    // Back reaches the gate first.
    WidgetsBinding.instance.addObserver(this);
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_cubit.resumed()),
    );
    if (_cubit.state.status is UpdateRecommended) unawaited(_sheet.forward());
  }

  @override
  Future<bool> didPopRoute() async {
    switch (_cubit.state.status) {
      case UpdateRequired() || Maintenance():
        return true;
      case UpdateRecommended():
        unawaited(_cubit.dismissUpdate());
        return true;
      case AppOpen():
        return false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycle.dispose();
    _sheet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return BlocConsumer<AppGateCubit, AppGateState>(
      listenWhen: (previous, current) =>
          previous.status is! UpdateRecommended &&
          current.status is UpdateRecommended,
      listener: (context, state) => unawaited(_sheet.forward(from: 0)),
      builder: (context, state) {
        final page = switch (state.status) {
          UpdateRequired() => UpdateRequiredPage(
            strings: strings,
            onUpdate: () => unawaited(_cubit.openStore()),
          ),
          Maintenance(:final message) => MaintenancePage(
            strings: strings,
            message: message.isEmpty ? strings.maintenanceMessage : message,
            retrying: state.retrying,
            onRetry: () => unawaited(_cubit.retry()),
          ),
          AppOpen() || UpdateRecommended() => null,
        };
        final hidden = page != null;
        return Stack(
          fit: StackFit.expand,
          children: [
            ExcludeFocus(
              excluding: hidden,
              child: TickerMode(
                enabled: !hidden,
                child: Offstage(offstage: hidden, child: widget.child),
              ),
            ),
            if (state.status is UpdateRecommended) ...[
              ModalBarrier(
                color: Theme.of(context).bottomSheetTheme.modalBarrierColor,
                onDismiss: () => unawaited(_cubit.dismissUpdate()),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedBuilder(
                  animation: _sheet,
                  // Slides by its own height, as a swipe drags it.
                  builder: (context, child) => FractionalTranslation(
                    translation: Offset(0, 1 - _sheet.value),
                    child: child,
                  ),
                  child: BottomSheet(
                    animationController: _sheet,
                    onClosing: () => unawaited(_cubit.dismissUpdate()),
                    builder: (context) => UpdateAvailableSheet(
                      strings: strings,
                      onUpdate: () => unawaited(_cubit.openStore()),
                      onLater: () => unawaited(_cubit.dismissUpdate()),
                    ),
                  ),
                ),
              ),
            ],
            ?page,
          ],
        );
      },
    );
  }
}
