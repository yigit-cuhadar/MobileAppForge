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

  /// The user properties last set, sent again whenever collection turns on:
  /// Analytics drops what is set while it does not collect.
  final _properties = <String, String?>{};

  /// Events and screens logged while the followed user's answer is not
  /// known yet (a new install, a user change): sent once it says collect,
  /// dropped once it says no. Analytics would drop them, and a new user's
  /// first screens are the start of every funnel. At most [_maxHeld].
  final _held = <Future<void> Function()>[];
  bool _holding = false;
  static const _maxHeld = 100;
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
      final collects = uid == null ? false : await _collects(uid);
      _holding = uid != null && collects == null;
      await _setCollection(collects == true);
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
    _drop();
    _holding = uid != null;
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
        _drop();
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
      if (_allowed) {
        await _flush();
      } else {
        _drop();
      }
      await _save(uid, consent);
    });
  }

  @override
  Future<Result<void>> forget(String uid) {
    ++_latest;
    _drop();
    return _run(() async {
      await _setCollection(false);
      await _save(uid, false);
      _properties.clear();
      await _analytics.resetAnalyticsData();
      await _crashlytics.deleteUnsentReports();
    });
  }

  @override
  Future<void> logEvent(
    String name, [
    Map<String, Object> parameters = const {},
  ]) async {
    if (_hold(() => logEvent(name, parameters))) return;
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (error) {
      Log.d('FirebaseTelemetry', 'event $name not logged: $error');
    }
  }

  @override
  Future<void> logScreen(String name) async {
    if (_hold(() => logScreen(name))) return;
    try {
      await _analytics.logScreenView(screenName: name);
    } catch (error) {
      Log.d('FirebaseTelemetry', 'screen $name not logged: $error');
    }
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    _properties[name] = value;
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (error) {
      Log.d('FirebaseTelemetry', 'user property $name not set: $error');
    }
  }

  /// Keeps [send] for later while the answer is not known; false when it
  /// should go now.
  bool _hold(Future<void> Function() send) {
    if (!_holding) return false;
    if (_held.length < _maxHeld) _held.add(send);
    return true;
  }

  /// Stops holding and drops what was held.
  void _drop() {
    _holding = false;
    _held.clear();
  }

  /// Stops holding and sends what was held, in order.
  Future<void> _flush() async {
    final held = List.of(_held);
    _drop();
    for (final log in held) {
      await log();
    }
  }

  Future<Result<void>> _run(Future<void> Function() body) {
    final run = _tail.then((_) => body());
    _tail = run.catchError((Object _) {});
    return guard(() => run);
  }

  /// Collects for the followed user with their [consent], identified by
  /// their uid, with the user properties set so far. Analytics drops an id
  /// or a property set while it does not collect, so turning on sets them
  /// after collection starts; turning off stops collection first, so a
  /// failure never leaves it on.
  Future<void> _setCollection(bool consent) async {
    final collect = _allowed && consent;
    if (!collect) {
      await _enableCollection(false);
      await _analytics.setUserId(id: null);
      await _crashlytics.setUserIdentifier('');
      return;
    }
    await _enableCollection(true);
    await _analytics.setUserId(id: _uid);
    await _crashlytics.setUserIdentifier(_uid ?? '');
    for (final MapEntry(:key, :value) in _properties.entries) {
      await _analytics.setUserProperty(name: key, value: value);
    }
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
