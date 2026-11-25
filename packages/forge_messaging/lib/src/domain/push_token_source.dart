/// This install's FCM registration token, which messages to one device are
/// sent to.
abstract interface class PushTokenSource {
  /// The token; null while the install has none.
  Future<String?> read();

  /// Fires when FCM issues a new token.
  Stream<void> changes();
}
