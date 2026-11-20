import 'package:forge_core/forge_core.dart';

import 'version.dart';

/// What the server asks of this platform's installs right now. A version
/// that is unset or not a version asks nothing.
final class AppGateRules extends Equatable {
  const AppGateRules({
    this.minimum,
    this.recommended,
    this.maintenance = false,
    this.maintenanceMessage = '',
  });

  /// Older installs cannot be used until updated.
  final Version? minimum;

  /// Older installs are offered the update.
  final Version? recommended;

  /// The app is closed for everyone, on every platform.
  final bool maintenance;

  /// The server's text for [maintenance]; empty for the app's own.
  final String maintenanceMessage;

  /// The status of an install of [installed] (null: unknown, which only
  /// [maintenance] can close) that dismissed the offer of [dismissed].
  /// Maintenance comes first: an update does not help while it lasts.
  AppGateStatus statusFor(Version? installed, {Version? dismissed}) {
    if (maintenance) return Maintenance(maintenanceMessage);
    if (installed == null) return const AppOpen();
    if (minimum case final minimum? when installed < minimum) {
      return const UpdateRequired();
    }
    if (recommended case final recommended?
        when installed < recommended && recommended != dismissed) {
      return UpdateRecommended(recommended);
    }
    return const AppOpen();
  }

  @override
  List<Object?> get props => [
    minimum,
    recommended,
    maintenance,
    maintenanceMessage,
  ];
}

sealed class AppGateStatus extends Equatable {
  const AppGateStatus();

  @override
  List<Object?> get props => [];
}

/// Nothing stands in the way.
final class AppOpen extends AppGateStatus {
  const AppOpen();
}

/// The app, with the offer to update to [version] over it.
final class UpdateRecommended extends AppGateStatus {
  const UpdateRecommended(this.version);
  final Version version;

  @override
  List<Object?> get props => [version];
}

/// Only the way to the store is open.
final class UpdateRequired extends AppGateStatus {
  const UpdateRequired();
}

/// The app is closed; [message] is the server's text, or empty.
final class Maintenance extends AppGateStatus {
  const Maintenance(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
