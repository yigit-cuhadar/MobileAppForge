import 'dart:async';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:forge_core/forge_core.dart';

/// Firebase Analytics and Crashlytics, collecting only where allowed and
/// only for a user who said yes, or never answered when [_collectUnanswered].
///
/// Each user's last answer, "never answered" included, is a file of their
/// own in [_directory], so [restore] can apply the signed-in user's at
/// launch, before their stored answer is read; another user's answer never
/// applies, and a user with no file here collects nothing until [apply].
/// [follow] waits for [apply] even when a file exists: the app is reading the
/// user's stored answer then, and the file may be older than it.
///
/// Changes run one at a time, in order. A user change ([follow]) or a
/// later answer counts from the moment it is made: an answer still waiting,
/// or still running (e.g. on a slow crash report deletion), stops before
/// its next step, so a yes never turns collection on, or is saved, after
/// it was overtaken.
class FirebaseTelemetry implements Telemetry {
  FirebaseTelemetry({
    required this._allowed,
    required this._collectUnanswered,
    required this._directory,
    required this._analytics,
    required this._crashlytics,
  });

  final bool _allowed;
  final bool _collectUnanswered;
  final Future<Directory> Function() _directory;
  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;

  /// The user collection follows; see [follow].
  String? _uid;
  Future<void> _tail = Future.value();
  int _latest = 0;

  /// Applies the answer [uid] (whoever is signed in at launch) last gave on
  /// this device: collection is off for nobody or a user with no answer
  /// saved here.
  /// Call once, from the app's main entry point; a background entry point
  /// leaves collection to the app. Never fails: on an error collection is
  /// left off.
  Future<void> restore(String? uid) async {
    _uid = uid;
    try {
      await _setCollection(uid != null && await _collects(uid) == true);
    } catch (error, stack) {
      Log.e('FirebaseTelemetry', 'consent not restored', error, stack);
      await guard(() => _setCollection(false));
    }
  }

  @override
  Future<Result<void>> follow(String? uid) {
    if (uid == _uid) return Future.value(const Ok(null));
    // Set now, so an answer in flight for the previous user stops.
    _uid = uid;
    ++_latest;
    return _run(() => _setCollection(false));
  }

  @override
  Future<Result<void>> apply(String uid, bool? consent) {
    final turn = ++_latest;
    // A later answer, a user change or a forget since: no longer counts.
    bool current() => turn == _latest && uid == _uid;
    return _run(() async {
      if (!current()) return;
      if (!(consent ?? _collectUnanswered)) {
        await _setCollection(false);
        return _save(uid, consent);
      }
      // Reports recorded while this user was not collected for here are
      // never sent. The yes is saved last, so a failure on the way never
      // leaves one saved.
      if (await _collects(uid) != true) {
        await _crashlytics.deleteUnsentReports();
      }
      if (!current()) return;
      await _setCollection(true);
      // Overtaken while turning on: the change that did it runs next and
      // turns collection off again; the yes is not saved.
      if (!current()) return;
      await _save(uid, consent);
    });
  }

  @override
  Future<Result<void>> forget(String uid) {
    ++_latest;
    return _run(() async {
      await _setCollection(false);
      await _save(uid, false);
      await _analytics.resetAnalyticsData();
      await _crashlytics.deleteUnsentReports();
    });
  }

  @override
  Future<void> logEvent(
    String name, [
    Map<String, Object> parameters = const {},
  ]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (error) {
      Log.d('FirebaseTelemetry', 'event $name not logged: $error');
    }
  }

  @override
  Future<void> logScreen(String name) async {
    try {
      await _analytics.logScreenView(screenName: name);
    } catch (error) {
      Log.d('FirebaseTelemetry', 'screen $name not logged: $error');
    }
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (error) {
      Log.d('FirebaseTelemetry', 'user property $name not set: $error');
    }
  }

  Future<Result<void>> _run(Future<void> Function() body) {
    final run = _tail.then((_) => body());
    _tail = run.catchError((Object _) {});
    return guard(() => run);
  }

  /// Collects for the followed user with their [consent], identified by
  /// their uid. Turning on sets the id first and turning off clears it last,
  /// so nothing is collected under a wrong id, nor kept on by a failure.
  Future<void> _setCollection(bool consent) async {
    final collect = _allowed && consent;
    if (!collect) await _enableCollection(false);
    final id = collect ? _uid : null;
    await _analytics.setUserId(id: id);
    await _crashlytics.setUserIdentifier(id ?? '');
    if (collect) await _enableCollection(true);
  }

  Future<void> _enableCollection(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  /// Whether [uid]'s answer saved here collects; null when none was saved
  /// here or it is unreadable.
  Future<bool?> _collects(String uid) async {
    try {
      return switch (await (await _file(uid)).readAsString()) {
        'true' => true,
        'false' => false,
        'null' => _collectUnanswered,
        _ => null,
      };
    } on FileSystemException {
      return null;
    }
  }

  Future<void> _save(String uid, bool? consent) async {
    final file = await _file(uid);
    await file.parent.create(recursive: true);
    await file.writeAsString('$consent', flush: true);
  }

  Future<File> _file(String uid) async {
    // Firebase uids are letters and digits; anything else is replaced.
    final name = uid.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return File('${(await _directory()).path}/analytics_consent_$name');
  }
}
