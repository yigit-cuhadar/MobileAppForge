import 'dart:convert';
import 'dart:io';

import 'package:forge_core/forge_core.dart';
import 'package:forge_remote_config/forge_remote_config.dart';

import '../domain/app_gate_repository.dart';
import '../domain/app_gate_status.dart';
import '../domain/version.dart';

/// The Remote Config keys of the rules. Versions are per platform
/// (`ios`, `android`); maintenance is one switch for all.
abstract final class AppGateKeys {
  static String minimumVersion(String platform) => 'min_version_$platform';
  static String recommendedVersion(String platform) =>
      'recommended_version_$platform';
  static const maintenance = 'maintenance';
  static const maintenanceMessage = 'maintenance_message';

  /// Every key, with a default that asks nothing.
  static const defaults = <String, Object>{
    'min_version_ios': '',
    'min_version_android': '',
    'recommended_version_ios': '',
    'recommended_version_android': '',
    maintenance: false,
    maintenanceMessage: '',
  };
}

/// [AppGateRepository] on Remote Config, with the dismissed offer as JSON
/// (`{"version": 1, "dismissed": "1.4.0"}`) in `app_gate.json` in
/// [_directory]. A file that cannot be read reads as nothing dismissed: at
/// worst the offer shows again.
class RemoteAppGateRepository implements AppGateRepository {
  RemoteAppGateRepository(
    this._config, {
    required this._platform,
    required this._installedVersion,
    required this._directory,
    required this._launchStore,
  });

  final RemoteConfigRepository _config;

  /// `ios` or `android`; null elsewhere, where no version rule applies.
  final String? _platform;
  final Future<String> Function() _installedVersion;
  final Future<Directory> Function() _directory;

  /// Opens the store page; false if nothing could open it.
  final Future<bool> Function() _launchStore;

  /// Saved or loaded this session, so a check never reads behind a save.
  Version? _dismissed;
  bool _dismissedKnown = false;

  static const _fileVersion = 1;

  @override
  Future<Result<Version>> installedVersion() => guard(() async {
    final text = await _installedVersion();
    return Version.tryParse(text) ??
        (throw FormatException('not a version: $text'));
  });

  @override
  AppGateRules rules() {
    final platform = _platform;
    Version? version(String Function(String) key) => platform == null
        ? null
        : Version.tryParse(_config.getString(key(platform)));
    return AppGateRules(
      minimum: version(AppGateKeys.minimumVersion),
      recommended: version(AppGateKeys.recommendedVersion),
      maintenance: _config.getBool(AppGateKeys.maintenance),
      maintenanceMessage: _config
          .getString(AppGateKeys.maintenanceMessage)
          .trim(),
    );
  }

  @override
  Future<Result<void>> refresh() =>
      _config.refresh(AppGateKeys.defaults.keys.toSet());

  @override
  Future<Result<Version?>> loadDismissed() => guard(() async {
    if (_dismissedKnown) return _dismissed;
    final file = await _file();
    Version? dismissed;
    if (await file.exists()) {
      try {
        if (jsonDecode(await file.readAsString()) case {
          'version': _fileVersion,
          'dismissed': final String text,
        }) {
          dismissed = Version.tryParse(text);
        }
      } on FormatException catch (error, stack) {
        Log.e('app_gate', 'dismissed file unreadable', error, stack);
      }
    }
    if (!_dismissedKnown) {
      _dismissed = dismissed;
      _dismissedKnown = true;
    }
    return _dismissed;
  });

  @override
  Future<Result<void>> saveDismissed(Version version) {
    _dismissed = version;
    _dismissedKnown = true;
    return guard(() async {
      final file = await _file();
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.partial');
      await temporary.writeAsString(
        jsonEncode({'version': _fileVersion, 'dismissed': '$version'}),
        flush: true,
      );
      await temporary.rename(file.path);
    });
  }

  @override
  Future<Result<void>> openStore() => guard(() async {
    if (!await _launchStore()) throw StateError('no app opened the store');
  });

  Future<File> _file() async =>
      File('${(await _directory()).path}/app_gate.json');
}
