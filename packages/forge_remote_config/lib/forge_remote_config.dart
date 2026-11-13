/// Firebase Remote Config, or an in-memory fake, for values the app changes
/// without a release, such as A/B test variants.
///
/// Register `RemoteConfigModule(defaults: {...}, backend: ...)` and await
/// `sl<RemoteConfigRepository>().initialize()` once in the composition root;
/// it does not wait for the network. Values fetched in a session apply from
/// the next launch, so a session never sees a value change. Read values
/// through the app's own use cases, which own the keys.
///
/// **A/B Testing** needs no other client package: Firebase assigns variants
/// by installation and measures them with Google Analytics, so only users
/// whose Analytics collection is on are counted. A new install sees the
/// defaults in its first session and its variant from the second; log the
/// experiment's activation event where the variant is shown, so only
/// sessions that read it are counted.
library;

export 'src/data/fake_remote_config_repository.dart';
export 'src/domain/remote_config_repository.dart';
export 'src/remote_config_module.dart';
