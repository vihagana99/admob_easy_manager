/// Container for AdMob Application ID and format-specific Ad Unit IDs.
/// Supports both single ID setups and round-robin multiple ID setups.
class AdMobIds {
  final String appId;
  final List<String> interstitialIds;
  final List<String> bannerIds;
  final List<String> appOpenIds;
  final List<String> rewardedIds;
  final List<String> nativeIds;
  final List<String> rewardedIntIds;

  const AdMobIds({
    required this.appId,
    required this.interstitialIds,
    required this.bannerIds,
    required this.appOpenIds,
    required this.rewardedIds,
    required this.nativeIds,
    required this.rewardedIntIds,
  }) : assert(interstitialIds.length > 0, 'interstitialIds cannot be empty'),
       assert(bannerIds.length > 0, 'bannerIds cannot be empty'),
       assert(appOpenIds.length > 0, 'appOpenIds cannot be empty'),
       assert(rewardedIds.length > 0, 'rewardedIds cannot be empty'),
       assert(nativeIds.length > 0, 'nativeIds cannot be empty'),
       assert(rewardedIntIds.length > 0, 'rewardedIntIds cannot be empty');

  /// Convenience constructor for apps with one Ad Unit ID per ad format.
  factory AdMobIds.single({
    required String appId,
    required String interstitialId,
    required String bannerId,
    required String appOpenId,
    required String rewardedId,
    required String nativeId,
    required String rewardedIntId,
  }) {
    return AdMobIds(
      appId: appId,
      interstitialIds: [interstitialId],
      bannerIds: [bannerId],
      appOpenIds: [appOpenId],
      rewardedIds: [rewardedId],
      nativeIds: [nativeId],
      rewardedIntIds: [rewardedIntId],
    );
  }

  String getInterstitial(int index) =>
      interstitialIds[index.abs() % interstitialIds.length];

  String getBanner(int index) => bannerIds[index.abs() % bannerIds.length];

  String getAppOpen(int index) => appOpenIds[index.abs() % appOpenIds.length];

  String getRewarded(int index) => rewardedIds[index.abs() % rewardedIds.length];

  String getNative(int index) => nativeIds[index.abs() % nativeIds.length];

  String getRewardedInterstitial(int index) =>
      rewardedIntIds[index.abs() % rewardedIntIds.length];
}
