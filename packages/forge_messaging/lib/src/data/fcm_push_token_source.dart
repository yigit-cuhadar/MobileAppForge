import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:forge_core/forge_core.dart';

import '../domain/push_token_source.dart';

/// [PushTokenSource] over [FirebaseMessaging]. FCM auto-init is off until
/// the first `TopicRepository.follow`, so an install that never allowed
/// notifications has no token and is not given one here.
class FcmPushTokenSource implements PushTokenSource {
  const FcmPushTokenSource(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  Future<String?> read() async {
    if (!_messaging.isAutoInitEnabled) return null;
    try {
      // iOS has no token without APNs.
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          await _messaging.getAPNSToken() == null) {
        return null;
      }
      // A registration token, which `sendEachForMulticast` takes; the newer
      // installation ids (register, onRegistered) are not used yet.
      // ignore: deprecated_member_use
      return await _messaging.getToken();
    } on Object catch (error) {
      // No Play services, or offline.
      Log.d('messaging', 'no push token: $error');
      return null;
    }
  }

  @override
  Stream<void> changes() =>
      // ignore: deprecated_member_use
      _messaging.onTokenRefresh.map((_) {});
}
