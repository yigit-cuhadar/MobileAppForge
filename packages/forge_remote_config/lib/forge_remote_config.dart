/// Firebase Remote Config, or an in-memory fake, for values the app changes
/// without a release, such as A/B test variants.
///
/// Register `RemoteConfigModule(defaults: {...}, backend: ...)` and await
/// `sl<RemoteConfigRepository>().initialize()` once in the composition root;
/// it does not wait for the network. Read values through the app's own use
/// cases, which own the keys.
///
/// **A/B Testing** needs no other client package: Firebase assigns variants
/// by installation and measures them with Google Analytics, so only users
/// whose Analytics collection is on are counted. Values fetched at startup
/// are activated as soon as they arrive, so a screen read before that shows
/// the default; read a variant when its screen opens and log the
/// experiment's activation event after that read.
library;

export 'src/data/fake_remote_config_repository.dart';
export 'src/domain/remote_config_repository.dart';
export 'src/remote_config_module.dart';
