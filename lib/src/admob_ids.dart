/// Container for AdMob Application ID and format-specific Ad Unit IDs.
/// Supports single ID setups, round-robin multiple ID setups, and optional format configurations.
class AdMobIds {
  final String appId;
  final List<String> interstitialIds;
  final List<String> bannerIds;
  final List<String> appOpenIds;
  final List<String> rewardedIds;
  final List<String> nativeIds;
  final List<String> rewardedIntIds;

  const AdMobIds({
    this.appId = '',
    this.interstitialIds = const [],
    this.bannerIds = const [],
    this.appOpenIds = const [],
    this.rewardedIds = const [],
    this.nativeIds = const [],
    this.rewardedIntIds = const [],
  });

  /// Convenience constructor for apps with one Ad Unit ID per ad format.
  /// Formats can be omitted if not used in the application.
  factory AdMobIds.single({
    String appId = '',
    String? interstitialId,
    String? bannerId,
    String? appOpenId,
    String? rewardedId,
    String? nativeId,
    String? rewardedIntId,
  }) {
    return AdMobIds(
      appId: appId,
      interstitialIds: interstitialId != null ? [interstitialId] : const [],
      bannerIds: bannerId != null ? [bannerId] : const [],
      appOpenIds: appOpenId != null ? [appOpenId] : const [],
      rewardedIds: rewardedId != null ? [rewardedId] : const [],
      nativeIds: nativeId != null ? [nativeId] : const [],
      rewardedIntIds: rewardedIntId != null ? [rewardedIntId] : const [],
    );
  }

  String getInterstitial(int index) {
    if (interstitialIds.isEmpty) {
      throw StateError('No interstitial ad unit IDs configured in AdMobIds.');
    }
    return interstitialIds[index.abs() % interstitialIds.length];
  }

  String getBanner(int index) {
    if (bannerIds.isEmpty) {
      throw StateError('No banner ad unit IDs configured in AdMobIds.');
    }
    return bannerIds[index.abs() % bannerIds.length];
  }

  String getAppOpen(int index) {
    if (appOpenIds.isEmpty) {
      throw StateError('No app open ad unit IDs configured in AdMobIds.');
    }
    return appOpenIds[index.abs() % appOpenIds.length];
  }

  String getRewarded(int index) {
    if (rewardedIds.isEmpty) {
      throw StateError('No rewarded ad unit IDs configured in AdMobIds.');
    }
    return rewardedIds[index.abs() % rewardedIds.length];
  }

  String getNative(int index) {
    if (nativeIds.isEmpty) {
      throw StateError('No native ad unit IDs configured in AdMobIds.');
    }
    return nativeIds[index.abs() % nativeIds.length];
  }

  String getRewardedInterstitial(int index) {
    if (rewardedIntIds.isEmpty) {
      throw StateError('No rewarded interstitial ad unit IDs configured in AdMobIds.');
    }
    return rewardedIntIds[index.abs() % rewardedIntIds.length];
  }
}
