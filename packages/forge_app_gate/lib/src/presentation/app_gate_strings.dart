/// User-facing text of the gate. Apps pass their own instance to localize
/// or reword.
class AppGateStrings {
  const AppGateStrings({
    this.updateRequiredTitle = 'Update required',
    this.updateRequiredMessage =
        'This version is no longer supported. Update to keep going.',
    this.updateAvailableTitle = 'A new version is available',
    this.updateAvailableMessage = 'Update for the latest fixes and features.',
    this.update = 'Update',
    this.later = 'Later',
    this.maintenanceTitle = "We'll be right back",
    this.maintenanceMessage =
        "We're making some improvements. Try again in a little while.",
    this.retry = 'Try again',
  });

  final String updateRequiredTitle;
  final String updateRequiredMessage;
  final String updateAvailableTitle;
  final String updateAvailableMessage;

  /// The button to the store.
  final String update;

  /// Dismisses the offer of an update.
  final String later;
  final String maintenanceTitle;

  /// Shown when the server sends no message of its own.
  final String maintenanceMessage;
  final String retry;
}
