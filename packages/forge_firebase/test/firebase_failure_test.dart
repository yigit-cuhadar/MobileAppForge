import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_firebase/forge_firebase.dart';

void main() {
  FirebaseException ex(String plugin, String code) =>
      FirebaseException(plugin: plugin, code: code, message: 'm');

  test('maps Firestore codes', () {
    expect(
      mapFirebaseError(ex('cloud_firestore', 'unavailable')),
      isA<NetworkFailure>(),
    );
    expect(
      mapFirebaseError(ex('cloud_firestore', 'permission-denied')),
      isA<PermissionFailure>(),
    );
    expect(
      mapFirebaseError(ex('cloud_firestore', 'not-found')),
      isA<NotFoundFailure>(),
    );
    expect(
      mapFirebaseError(ex('cloud_firestore', 'aborted')),
      isA<UnknownFailure>(),
    );
  });

  test('maps auth errors and keeps the code', () {
    final failure = mapFirebaseError(ex('firebase_auth', 'wrong-password'));
    expect(
      failure,
      isA<AuthFailure>().having((f) => f.code, 'code', 'wrong-password'),
    );
    expect(
      mapFirebaseError(ex('firebase_auth', 'network-request-failed')),
      isA<NetworkFailure>(),
    );
  });

  test('declines non-Firebase errors', () {
    expect(mapFirebaseError(StateError('x')), isNull);
  });
}
