# AdMob Easy Manager (v1.0.0)

A robust, production-grade Flutter wrapper for the Google Mobile Ads SDK. Built to eliminate boilerplate, guarantee seamless test ads on physical devices, prevent memory leaks, and provide fail-safe loading overlays with zero duplicate callbacks.

## Features

- **Platform-Specific IDs**: Configure Android and iOS Ad Unit IDs separately, or use Android-only / iOS-only setups effortlessly.
- **Flexible Format Setup**: Only provide the Ad Unit IDs you actually use (e.g., only Banner & Interstitial) — no need to declare dummy IDs for unused formats.
- **Test Device Whitelisting**: Pass your physical test device IDs directly into `init(testDeviceIds: [...])` to get 100% fill rate test ads without manual native configuration.
- **Hybrid Status**: Automatically serves Google sample test ads during development (`kDebugMode`) and seamless live ads in release mode.
- **Zero Duplicate Callbacks**: Strict single-invocation guarantee for `onSuccess`, `onError`, `onRewarded`, and `onDismissed`.
- **Fail-Safe Loading Overlay**: Built-in 6s auto-dismiss protection ensures users never get stuck on a dimmed screen if an ad times out.
- **Dark & Light Mode Native Ads**: Pre-configured `NativeAdsContainer` automatically adjusts typography and card background colors for Dark and Light themes.
- **Adaptive Banner Sizing**: Automatically sizes banners to the current device orientation and screen width.
- **Memory-Safe Preload Cache**: Replaced or evicted ads are automatically disposed to prevent native memory leaks.

## Supported Ad Formats

- Banner Ads (Anchored Adaptive)
- Interstitial Ads
- Rewarded Ads
- Rewarded Interstitial Ads
- Native Ads (Small & Medium templates)
- App Open Ads

---

## Getting Started

### 1. Add Dependency

In your app's `pubspec.yaml`:

```yaml
dependencies:
  admob_easy_manager:
    git:
      url: https://github.com/vihagana99/admob_easy_manager.git
      ref: 1.0.0
```

Or for local package development:

```yaml
dependencies:
  admob_easy_manager:
    path: ../admob_easy_manager
```

### 2. Platform Setup

#### Android (`android/app/src/main/AndroidManifest.xml`)
Inside the `<application>` tag, add your AdMob Application ID:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

#### Android (`MainActivity.kt`)
Extend `FlutterFragmentActivity` (required for modern Google Mobile Ads):

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
```

#### iOS (`ios/Runner/Info.plist`)
Inside `<dict>`, add your iOS AdMob Application ID:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
```

---

## Initialization Examples

You can initialize `AdsManager` in `main()` before `runApp()`.

### Option 1: Android Only (Android IDs Only)

If you are only building for Android or only want to provide Android Ad Unit IDs:

```dart
import 'package:flutter/material.dart';
import 'package:admob_easy_manager/admob_easy_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure only Android IDs (provide only the ad formats you use)
  final androidIds = AdMobIds.single(
    appId: "ca-app-pub-xxxxxxxx~xxxxxxxxxx",
    bannerId: "ca-app-pub-xxxxxxxx/xxxxxxxxxx",
    interstitialId: "ca-app-pub-xxxxxxxx/xxxxxxxxxx",
    rewardedId: "ca-app-pub-xxxxxxxx/xxxxxxxxxx",
  );

  await AdsManager.instance.init(
    androidIds: androidIds,
    status: AdsStatus.hybrid, // Hybrid: test ads in debug, live ads in release
    testDeviceIds: [
      'YOUR_TEST_DEVICE_ID',
    ],
  );

  runApp(const MyApp());
}
```

---

### Option 2: Cross-Platform (Android & iOS Separately - Recommended)

For apps targeting both Android and iOS with distinct AdMob Ad Unit IDs:

```dart
import 'package:flutter/material.dart';
import 'package:admob_easy_manager/admob_easy_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android IDs
  final androidIds = AdMobIds.single(
    appId: "ca-app-pub-xxxxxxxx~xxxxxxxxxx",
    bannerId: "ca-app-pub-xxxxxxxx/xxxxxxxxxx",
    interstitialId: "ca-app-pub-xxxxxxxx/xxxxxxxxxx",
    rewardedId: "ca-app-pub-xxxxxxxx/xxxxxxxxxx",
    nativeId: "ca-app-pub-xxxxxxxx/xxxxxxxxxx",
  );

  // iOS IDs
  final iosIds = AdMobIds.single(
    appId: "ca-app-pub-yyyyyyyy~yyyyyyyyyy",
    bannerId: "ca-app-pub-yyyyyyyy/yyyyyyyyyy",
    interstitialId: "ca-app-pub-yyyyyyyy/yyyyyyyyyy",
    rewardedId: "ca-app-pub-yyyyyyyy/yyyyyyyyyy",
    nativeId: "ca-app-pub-yyyyyyyy/yyyyyyyyyy",
  );

  await AdsManager.instance.init(
    androidIds: androidIds,
    iosIds: iosIds,
    status: AdsStatus.hybrid,
    testDeviceIds: [
      'YOUR_TEST_DEVICE_ID',
      'kGADSimulatorID',
    ],
  );

  runApp(const MyApp());
}
```

---

### Option 3: Unified / Single Configuration

If you prefer passing a single fallback configuration:

```dart
final ids = AdMobIds.single(
  bannerId: "ca-app-pub-xxxxxxxx/xxxxxxxxxx",
  interstitialId: "ca-app-pub-xxxxxxxx/xxxxxxxxxx",
);

await AdsManager.instance.init(
  ids: ids,
  status: AdsStatus.hybrid,
);
```

---

### Option 4: Multiple Ad IDs (Round-Robin Setup)

If you have multiple Ad Unit IDs per format to balance fill rates and traffic:

```dart
const androidIds = AdMobIds(
  bannerIds: [
    'ca-app-pub-xxxxxxxx/banner_1',
    'ca-app-pub-xxxxxxxx/banner_2',
  ],
  interstitialIds: [
    'ca-app-pub-xxxxxxxx/interstitial_1',
    'ca-app-pub-xxxxxxxx/interstitial_2',
  ],
);

await AdsManager.instance.init(
  androidIds: androidIds,
  status: AdsStatus.hybrid,
);
```

---

## Ad Operating Modes (`AdsStatus`)

| Status | Description |
| :--- | :--- |
| `AdsStatus.hybrid` | **(Recommended)** Automatically loads Google sample test ads in `debug` mode (`kDebugMode`) and live ads in `release` mode. |
| `AdsStatus.testing` | Always forces Google sample test ads across all build modes. |
| `AdsStatus.enabled` | Always loads live production ads. |
| `AdsStatus.disabled` | Disables all ad loading and displays, immediately invoking callbacks safely. |

---

## Showing Ads (Code Examples)

### 1. Banner Ad (Adaptive Widget)

Adaptive banners automatically calculate the screen width and display an anchored banner:

```dart
// Standard adaptive banner
const BannerAdContainer(index: 0)

// Banner with optional callbacks and placeholder
BannerAdContainer(
  index: 0,
  placeholder: const SizedBox(height: 50),
  onLoaded: (ad) => debugPrint('Banner loaded!'),
  onFailedToLoad: (error) => debugPrint('Banner error: $error'),
)
```

---

### 2. Interstitial Ad

Displays a full-screen interstitial ad with an on-demand loading overlay and safe single-invocation callbacks:

```dart
// Optional: Preload ahead of time for instant display
await AdsManager.instance.preLoad(AdsUnit.interstitial, 0);

// Show interstitial ad
await AdsManager.instance.showInterstitial(
  context,
  0,
  RequestHandlerImpl(
    timeout: const Duration(seconds: 8),
    onSuccess: () {
      // Proceed to the next screen or trigger action
      Navigator.pushNamed(context, '/home');
    },
    onError: (error) {
      // Gracefully continue even if the ad failed to load or timed out
      Navigator.pushNamed(context, '/home');
    },
  ),
);
```

---

### 3. Rewarded Ad

Rewarding users after watching an ad with guaranteed callback delivery:

```dart
await AdsManager.instance.showRewarded(
  context,
  0,
  RewardedCallbacks(
    onRewarded: () {
      // Grant in-game coins, unlock feature, etc.
      userCoins += 50;
    },
    onError: (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load rewarded ad: $error')),
      );
    },
    onDismissed: () {
      debugPrint('Rewarded ad closed');
    },
  ),
);
```

---

### 4. Rewarded Interstitial Ad

For rewarded ads shown at natural transition points without an opt-in prompt:

```dart
await AdsManager.instance.showRewardedInterstitial(
  context,
  0,
  RewardedCallbacks(
    onRewarded: () => unlockBonusLevel(),
    onError: (err) => continueGame(),
  ),
);
```

---

### 5. Native Ad Widget

Pre-styled Native Ads with automatic Dark Mode & Light Mode theme detection:

```dart
// Small template
const NativeAdsContainer(
  index: 0,
  size: NativeAdsSize.small,
)

// Medium template with error fallback
NativeAdsContainer(
  index: 0,
  size: NativeAdsSize.medium,
  placeholder: const SizedBox(height: 120),
  onLoaded: (ad) => debugPrint('Native ad loaded!'),
  onFailedToLoad: (err) => debugPrint('Native ad failed: $err'),
)
```

---

### 6. App Open Ad

For showing full-screen ads when the user returns to the app:

```dart
await AdsManager.instance.showAppOpen(
  context,
  0,
  RequestHandlerImpl(
    timeout: const Duration(seconds: 6),
    onSuccess: () => debugPrint('App Open ad dismissed'),
    onError: (err) => debugPrint('App Open ad failed: $err'),
  ),
);
```

---

## License

MIT License
