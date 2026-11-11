import 'dart:developer' as dev;

/// Minimal logger. [onError] is the hook for crash reporting.
abstract final class Log {
  static void Function(Object error, StackTrace? stack, String reason)? onError;

  static void d(String tag, String message) => dev.log(message, name: tag);

  static void e(
    String tag,
    String message, [
    Object? error,
    StackTrace? stack,
  ]) {
    dev.log(message, name: tag, error: error, stackTrace: stack, level: 1000);
    if (error != null) onError?.call(error, stack, '$tag: $message');
  }
}
