import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/purchases_models.dart';

/// Broadcasts entitlement updates and replays the latest one to each new
/// listener.
class EntitlementChannel {
  final _controller = StreamController<Entitlement>.broadcast();
  Entitlement? _latest;

  Entitlement? get latest => _latest;

  Entitlement add(Entitlement entitlement) {
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
