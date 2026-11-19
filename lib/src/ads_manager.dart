import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_ids.dart';
import 'ads_status.dart';
import 'ads_unit.dart';
import 'ad_preload_cache.dart';
import 'loading_overlay.dart';
import 'request_handler.dart';

/// Central singleton controller for Google Mobile Ads in Flutter.
/// Provides robust test device support, single-flight preloading,
/// fail-safe overlays, and zero-duplicate-callback architecture.
class AdsManager {
  static final AdsManager _instance = AdsManager._internal();
  factory AdsManager() => _instance;
  static AdsManager get instance => _instance;
  AdsManager._internal();

  AdMobIds? _ids;
  AdMobIds? _androidIds;
  AdMobIds? _iosIds;
  AdsStatus _status = AdsStatus.enabled;
  bool _forceTestAds = false;

  final AdPreloadCache _cache = AdPreloadCache();
  final LoadingOverlay _loadingOverlay = LoadingOverlay();

  bool _initialized = false;
  final Map<String, Future<void>> _loadingTasks = {};

  /// Initializes the Mobile Ads SDK with IDs, mode status, and optional test devices.
  /// Provide platform-specific IDs via [androidIds] and [iosIds],
  /// or a unified [ids] configuration for both.
  Future<void> init({
    AdMobIds? ids,
    AdMobIds? androidIds,
    AdMobIds? iosIds,
    required AdsStatus status,
    List<String>? testDeviceIds,
    Color? loadingColor,
  }) async {
    assert(
      ids != null || androidIds != null || iosIds != null,
      'At least one of ids, androidIds, or iosIds must be provided to init().',
    );
    _ids = ids;
    _androidIds = androidIds;
    _iosIds = iosIds;
    _status = status;

    if (loadingColor != null) {
      _loadingOverlay.setColor(loadingColor);
    }

    if (testDeviceIds != null && testDeviceIds.isNotEmpty) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: testDeviceIds),
      );
      debugPrint('📺 [AdsManager] Test device IDs registered: $testDeviceIds');
    }

    if (!_initialized) {
      final initStatus = await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('📺 [AdsManager] Mobile Ads SDK initialized successfully.');
      initStatus.adapterStatuses.forEach((name, adapter) {
        debugPrint('📺 [AdsManager] Adapter $name: ${adapter.state} (${adapter.description})');
      });
    }
  }

  /// Forces test ads regardless of current build mode or configuration.
  void setForceTestAds(bool force) => _forceTestAds = force;

  /// Customizes the background color of the on-demand loading overlay.
  void setLoadingColor(Color color) => _loadingOverlay.setColor(color);

  /// Resolves the actual operating mode based on status, debug mode, and force flag.
  AdsStatus get effectiveStatus {
    if (_status == AdsStatus.hybrid) {
      return (kDebugMode || _forceTestAds) ? AdsStatus.testing : AdsStatus.enabled;
    }
    return _status;
  }

  /// Returns true if ad loading and display are disabled.
  bool get isAdsDisabled => effectiveStatus == AdsStatus.disabled;

  /// Returns the active [AdMobIds] configured for the current platform.
  AdMobIds? get currentIds {
    if (!kIsWeb && Platform.isAndroid) {
      return _androidIds ?? _ids;
    } else if (!kIsWeb && Platform.isIOS) {
      return _iosIds ?? _ids;
    }
    return _ids;
  }

  /// Returns the appropriate Ad Unit ID for the given format and index.
  String getAdUnitId(AdsUnit unit, int index) {
    if (effectiveStatus == AdsStatus.testing) {
      if (!kIsWeb && Platform.isAndroid) {
        switch (unit) {
          case AdsUnit.interstitial:
            return 'ca-app-pub-3940256099942544/1033173712';
          case AdsUnit.banner:
            return 'ca-app-pub-3940256099942544/6300978111';
          case AdsUnit.appOpen:
            return 'ca-app-pub-3940256099942544/9257395921';
          case AdsUnit.rewarded:
            return 'ca-app-pub-3940256099942544/5224354917';
          case AdsUnit.native:
            return 'ca-app-pub-3940256099942544/2247696110';
          case AdsUnit.rewardedInt:
            return 'ca-app-pub-3940256099942544/5354046379';
        }
      } else if (!kIsWeb && Platform.isIOS) {
        switch (unit) {
          case AdsUnit.interstitial:
            return 'ca-app-pub-3940256099942544/4411468910';
          case AdsUnit.banner:
            return 'ca-app-pub-3940256099942544/2435281174';
          case AdsUnit.appOpen:
            return 'ca-app-pub-3940256099942544/5575463023';
          case AdsUnit.rewarded:
            return 'ca-app-pub-3940256099942544/1712485313';
          case AdsUnit.native:
            return 'ca-app-pub-3940256099942544/3986624511';
          case AdsUnit.rewardedInt:
            return 'ca-app-pub-3940256099942544/6978759866';
        }
      }
    }

    final ids = currentIds;
    if (ids == null) {
      final platform = !kIsWeb ? Platform.operatingSystem : 'web';
      throw StateError(
        'AdsManager has no IDs configured for platform "$platform". '
        'Provide ${platform == "ios" ? "iosIds" : "androidIds"} or unified ids to AdsManager.instance.init().',
      );
    }

    switch (unit) {
      case AdsUnit.interstitial:
        return ids.getInterstitial(index);
      case AdsUnit.banner:
        return ids.getBanner(index);
      case AdsUnit.appOpen:
        return ids.getAppOpen(index);
      case AdsUnit.rewarded:
        return ids.getRewarded(index);
      case AdsUnit.native:
        return ids.getNative(index);
      case AdsUnit.rewardedInt:
        return ids.getRewardedInterstitial(index);
    }
  }

  String _taskKey(AdsUnit unit, int index) => '${unit.name}#$index';

  /// Preloads an ad into the in-memory cache for instant display later.
  Future<void> preLoad(AdsUnit unit, int index) async {
    if (isAdsDisabled) return;

    switch (unit) {
      case AdsUnit.interstitial:
        return _runSingleLoad(unit, index, () => _preloadInterstitial(index));
      case AdsUnit.rewarded:
        return _runSingleLoad(unit, index, () => _preloadRewarded(index));
      case AdsUnit.rewardedInt:
        return _runSingleLoad(unit, index, () => _preloadRewardedInterstitial(index));
      case AdsUnit.appOpen:
        return _runSingleLoad(unit, index, () => _preloadAppOpen(index));
      case AdsUnit.banner:
      case AdsUnit.native:
        return;
    }
  }

  Future<void> _runSingleLoad(
    AdsUnit unit,
    int index,
    Future<void> Function() loader,
  ) {
    final key = _taskKey(unit, index);
    final existing = _loadingTasks[key];
    if (existing != null) return existing;

    final future = loader().whenComplete(() {
      _loadingTasks.remove(key);
    });

    _loadingTasks[key] = future;
    return future;
  }

  Future<void> _preloadInterstitial(int index) async {
    final completer = Completer<void>();
    final id = getAdUnitId(AdsUnit.interstitial, index);

    InterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _cache.set(AdsUnit.interstitial, index, ad);
          debugPrint('✅ [AdsManager] Interstitial loaded into cache ($id)');
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ [AdsManager] Interstitial load failed: $error ($id)');
          if (!completer.isCompleted) completer.completeError(error);
        },
      ),
    );

    return completer.future;
  }

  Future<void> _preloadAppOpen(int index) async {
    final completer = Completer<void>();
    final id = getAdUnitId(AdsUnit.appOpen, index);

    AppOpenAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _cache.set(AdsUnit.appOpen, index, ad);
          debugPrint('✅ [AdsManager] App Open ad loaded into cache ($id)');
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ [AdsManager] App Open ad load failed: $error ($id)');
          if (!completer.isCompleted) completer.completeError(error);
        },
      ),
    );

    return completer.future;
  }

  Future<void> _preloadRewarded(int index) async {
    final completer = Completer<void>();
    final id = getAdUnitId(AdsUnit.rewarded, index);

    RewardedAd.load(
      adUnitId: id,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _cache.set(AdsUnit.rewarded, index, ad);
          debugPrint('✅ [AdsManager] Rewarded ad loaded into cache ($id)');
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ [AdsManager] Rewarded ad load failed: $error ($id)');
          if (!completer.isCompleted) completer.completeError(error);
        },
      ),
    );

    return completer.future;
  }

  Future<void> _preloadRewardedInterstitial(int index) async {
    final completer = Completer<void>();
    final id = getAdUnitId(AdsUnit.rewardedInt, index);

    RewardedInterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _cache.set(AdsUnit.rewardedInt, index, ad);
          debugPrint('✅ [AdsManager] Rewarded Interstitial loaded into cache ($id)');
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ [AdsManager] Rewarded Interstitial load failed: $error ($id)');
          if (!completer.isCompleted) completer.completeError(error);
        },
      ),
    );

    return completer.future;
  }

  /// Displays an Interstitial Ad. If cached, displays immediately.
  /// Otherwise displays a loading overlay, fetches on demand, and triggers [handler].
  Future<void> showInterstitial(
    BuildContext context,
    int index,
    RequestHandler handler,
  ) async {
    if (isAdsDisabled) {
      handler.dispatchSuccess();
      return;
    }

    InterstitialAd? ad = _cache.get<InterstitialAd>(AdsUnit.interstitial, index);

    if (ad == null) {
      _loadingOverlay.show(context);
      try {
        await preLoad(AdsUnit.interstitial, index);
        ad = _cache.get<InterstitialAd>(AdsUnit.interstitial, index);
      } catch (e) {
        debugPrint('❌ [AdsManager] Error fetching interstitial on demand: $e');
      } finally {
        _loadingOverlay.hide();
      }
    }

    if (ad == null) {
      handler.dispatchError('Failed to load interstitial ad');
      return;
    }

    if (!context.mounted) {
      ad.dispose();
      _cache.remove(AdsUnit.interstitial, index);
      handler.dispatchError('Context unmounted');
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _cache.remove(AdsUnit.interstitial, index);
        handler.dispatchSuccess();
        preLoad(AdsUnit.interstitial, index);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _cache.remove(AdsUnit.interstitial, index);
        handler.dispatchError(error.toString());
        preLoad(AdsUnit.interstitial, index);
      },
    );

    ad.show();
  }

  /// Displays an App Open Ad with seamless caching and loading overlay protection.
  Future<void> showAppOpen(
    BuildContext context,
    int index,
    RequestHandler handler,
  ) async {
    if (isAdsDisabled) {
      handler.dispatchSuccess();
      return;
    }

    AppOpenAd? ad = _cache.get<AppOpenAd>(AdsUnit.appOpen, index);

    if (ad == null) {
      _loadingOverlay.show(context);
      try {
        await preLoad(AdsUnit.appOpen, index);
        ad = _cache.get<AppOpenAd>(AdsUnit.appOpen, index);
      } catch (e) {
        debugPrint('❌ [AdsManager] Error fetching App Open ad on demand: $e');
      } finally {
        _loadingOverlay.hide();
      }
    }

    if (ad == null) {
      handler.dispatchError('Failed to load app open ad');
      return;
    }

    if (!context.mounted) {
      ad.dispose();
      _cache.remove(AdsUnit.appOpen, index);
      handler.dispatchError('Context unmounted');
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _cache.remove(AdsUnit.appOpen, index);
        handler.dispatchSuccess();
        preLoad(AdsUnit.appOpen, index);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _cache.remove(AdsUnit.appOpen, index);
        handler.dispatchError(error.toString());
        preLoad(AdsUnit.appOpen, index);
      },
    );

    ad.show();
  }

  /// Displays a Rewarded Ad, granting reward via [callbacks.onRewarded] on completion.
  Future<void> showRewarded(
    BuildContext context,
    int index,
    RewardedCallbacks callbacks,
  ) async {
    if (isAdsDisabled) {
      callbacks.dispatchDismissed();
      return;
    }

    RewardedAd? ad = _cache.get<RewardedAd>(AdsUnit.rewarded, index);

    if (ad == null) {
      _loadingOverlay.show(context);
      try {
        await preLoad(AdsUnit.rewarded, index);
        ad = _cache.get<RewardedAd>(AdsUnit.rewarded, index);
      } catch (e) {
        debugPrint('❌ [AdsManager] Error fetching rewarded ad on demand: $e');
      } finally {
        _loadingOverlay.hide();
      }
    }

    if (ad == null) {
      callbacks.dispatchError('Failed to load rewarded ad');
      return;
    }

    if (!context.mounted) {
      ad.dispose();
      _cache.remove(AdsUnit.rewarded, index);
      callbacks.dispatchError('Context unmounted');
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        callbacks.onShowed?.call();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _cache.remove(AdsUnit.rewarded, index);
        callbacks.dispatchDismissed();
        preLoad(AdsUnit.rewarded, index);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _cache.remove(AdsUnit.rewarded, index);
        callbacks.dispatchFailedToShow(error);
        preLoad(AdsUnit.rewarded, index);
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        callbacks.dispatchRewarded();
      },
    );
  }

  /// Displays a Rewarded Interstitial Ad.
  Future<void> showRewardedInterstitial(
    BuildContext context,
    int index,
    RewardedCallbacks callbacks,
  ) async {
    if (isAdsDisabled) {
      callbacks.dispatchDismissed();
      return;
    }

    RewardedInterstitialAd? ad = _cache.get<RewardedInterstitialAd>(AdsUnit.rewardedInt, index);

    if (ad == null) {
      _loadingOverlay.show(context);
      try {
        await preLoad(AdsUnit.rewardedInt, index);
        ad = _cache.get<RewardedInterstitialAd>(AdsUnit.rewardedInt, index);
      } catch (e) {
        debugPrint('❌ [AdsManager] Error fetching rewarded interstitial on demand: $e');
      } finally {
        _loadingOverlay.hide();
      }
    }

    if (ad == null) {
      callbacks.dispatchError('Failed to load rewarded interstitial ad');
      return;
    }

    if (!context.mounted) {
      ad.dispose();
      _cache.remove(AdsUnit.rewardedInt, index);
      callbacks.dispatchError('Context unmounted');
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        callbacks.onShowed?.call();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _cache.remove(AdsUnit.rewardedInt, index);
        callbacks.dispatchDismissed();
        preLoad(AdsUnit.rewardedInt, index);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _cache.remove(AdsUnit.rewardedInt, index);
        callbacks.dispatchFailedToShow(error);
        preLoad(AdsUnit.rewardedInt, index);
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        callbacks.dispatchRewarded();
      },
    );
  }
}
