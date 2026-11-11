import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/purchases_models.dart';

/// Broadcasts the current user's entitlement and replays the latest one to
/// each new listener. Closed while a user switch is unresolved, so the
/// previous user's values never reach the next user.
class EntitlementChannel {
  final _controller = StreamController<Entitlement>.broadcast();
  Entitlement? _latest;
  bool _open = false;

  Entitlement? get latest => _latest;

  /// Call before switching users; [open] once the switch succeeded.
  void close() {
    _open = false;
    _latest = null;
  }

  Entitlement open(Entitlement entitlement) {
    _open = true;
    return add(entitlement);
  }

  /// Ignored while closed.
  Entitlement add(Entitlement entitlement) {
    if (!_open) return entitlement;
    _latest = entitlement;
    _controller.add(entitlement);
    return entitlement;
  }

  Stream<Entitlement> get stream => Stream.multi((listener) {
    final latest = _latest;
    if (latest != null) listener.add(latest);
    final subscription = _controller.stream.listen(listener.add);
    listener.onCancel = subscription.cancel;
  });
}

/// The store's own subscription list, used when the SDK has no better link.
Uri storeSubscriptionsUrl() => Uri.parse(switch (defaultTargetPlatform) {
  TargetPlatform.android =>
    'https://play.google.com/store/account/subscriptions',
  _ => 'https://apps.apple.com/account/subscriptions',
});
