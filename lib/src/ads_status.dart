/// Defines how ads should behave across development and production environments.
enum AdsStatus {
  /// Ads are completely disabled. No ad requests or preloading occur.
  disabled,

  /// Production ads are active. Real ad units are loaded.
  enabled,

  /// Forces Google's official test ad units on Android and iOS.
  testing,

  /// Automatically uses test ads during debug mode (kDebugMode)
  /// and switches to production ads in release mode.
  hybrid,
}
