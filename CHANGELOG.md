## 2.0.0

- Complete architectural overhaul with production-grade stability.
- Added direct `testDeviceIds` support to `AdsManager.init()` for automatic physical device whitelisting.
- Fixed duplicate `handler.onError()` and `callbacks.onError()` invocations on ad load failure.
- Fixed `LoadingOverlay` context unmounting leaks with automatic 6-second failsafe timeout.
- Added Dark Mode theme-aware styling to `NativeAdsContainer` to prevent invisible text or unreadable CTA buttons.
- Enhanced `NativeAdsContainer` with `ConstrainedBox` bounds to resolve platform-view layout calculation bugs.
- Added graceful error handling and auto-disposing in `AdPreloadCache`.
- Added `placeholder`, `onLoaded`, and `onFailedToLoad` callbacks to both `BannerAdContainer` and `NativeAdsContainer`.
