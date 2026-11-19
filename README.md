# AdMob Ads Manager (v2.0.0)

A robust, production-grade Flutter wrapper for Google Mobile Ads SDK. Built to eliminate boilerplate, guarantee seamless test ads on physical devices, prevent memory leaks, and provide fail-safe loading overlays with zero duplicate callbacks.

## Features

- **Test Device Whitelisting**: Pass your physical device IDs directly into `init(testDeviceIds: [...])` to get 100% fill test ads without manual `updateRequestConfiguration` code.
- **Hybrid Status**: Automatically serves Google sample test ads during development (`kDebugMode`) and seamless live ads in release mode.
- **Zero Duplicate Callbacks**: Strict single-invocation guarantee for `onSuccess`, `onError`, `onRewarded`, and `onDismissed`.
- **Fail-Safe Loading Overlay**: Built-in 6s auto-dismiss protection ensures users never get stuck on a dimmed screen if an ad times out.
- **Dark Mode Native Ads**: Pre-configured `NativeAdsContainer` automatically adjusts typography and card background colors for Dark and Light themes.
- **Adaptive Banner Sizing**: Automatically sizes banners to the current device orientation and screen width.
- **Memory-Safe Preload Cache**: Replaced or evicted ads are automatically disposed to prevent native memory leaks.

## Supported Ad Formats

- App Open Ads
- Interstitial Ads
- Rewarded Ads
- Rewarded Interstitial Ads
- Native Ads (Small & Medium templates)
- Banner Ads (Adaptive)

## Getting Started

### 1. Add Dependency

In your `pubspec.yaml`:

```yaml
dependencies:
  admob_ads_manager:
    git:
      url: https://github.com/YOUR_USERNAME/admob_ads_manager.git
```

Or for local development:

```yaml
dependencies:
  admob_ads_manager:
    path: ../admob_ads_manager
```

### 2. Platform Setup

#### Android (`android/app/src/main/AndroidManifest.xml`)
Inside the `<application>` tag:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

#### Android (`MainActivity.kt`)
Extend `FlutterFragmentActivity`:

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
```

### 3. Usage

#### Initialize

```dart
import 'package:admob_ads_manager/admob_ads_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ids = AdMobIds.single(
    appId: "ca-app-pub-xxxxxxxx~xxxxxxxxxx",
    interstitialId: "ca-app-pub-xxxxxxxx/xxxxxxxxxx",
    bannerId: "ca-app-pub-xxxxxxxx/xxxxxxxxxx",
    appOpenId: "ca-app-pub-xxxxxxxx/xxxxxxxxxx",
    nativeId: "ca-app-pub-xxxxxxxx/xxxxxxxxxx",
    rewardedId: "ca-app-pub-xxxxxxxx/xxxxxxxxxx",
    rewardedIntId: "ca-app-pub-xxxxxxxx/xxxxxxxxxx",
  );

  await AdsManager.instance.init(
    ids: ids,
    status: AdsStatus.hybrid,
    testDeviceIds: [
      '812C0EC2FB8FD8BE632D8224AF713B09',
      'kGADSimulatorID',
    ],
  );

  runApp(const MyApp());
}
```

#### Show Interstitial Ad

```dart
await AdsManager.instance.showInterstitial(
  context,
  0,
  RequestHandlerImpl(
    timeout: const Duration(seconds: 8),
    onSuccess: () => navigateToNextScreen(),
    onError: (err) => navigateToNextScreen(),
  ),
);
```

#### Show Rewarded Ad

```dart
await AdsManager.instance.showRewarded(
  context,
  0,
  RewardedCallbacks(
    onRewarded: () {
      grantCoinsOrTokens();
    },
    onError: (err) {
      showErrorDialog();
    },
  ),
);
```

#### Native Ad Widget

```dart
NativeAdsContainer(
  index: 0,
  size: NativeAdsSize.small,
)
```

#### Banner Ad Widget

```dart
BannerAdContainer(index: 0)
```

## License

MIT License
