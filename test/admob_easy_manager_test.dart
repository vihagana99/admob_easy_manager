import 'package:flutter_test/flutter_test.dart';
import 'package:admob_easy_manager/admob_easy_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdMobIds', () {
    test('single constructor with all IDs', () {
      final ids = AdMobIds.single(
        appId: 'ca-app-pub-1234~5678',
        bannerId: 'banner-1',
        interstitialId: 'interstitial-1',
        appOpenId: 'appopen-1',
        rewardedId: 'rewarded-1',
        nativeId: 'native-1',
        rewardedIntId: 'rewardedint-1',
      );

      expect(ids.appId, 'ca-app-pub-1234~5678');
      expect(ids.getBanner(0), 'banner-1');
      expect(ids.getInterstitial(0), 'interstitial-1');
      expect(ids.getAppOpen(0), 'appopen-1');
      expect(ids.getRewarded(0), 'rewarded-1');
      expect(ids.getNative(0), 'native-1');
      expect(ids.getRewardedInterstitial(0), 'rewardedint-1');
    });

    test('single constructor with partial IDs', () {
      final ids = AdMobIds.single(
        bannerId: 'banner-1',
        interstitialId: 'interstitial-1',
      );

      expect(ids.getBanner(0), 'banner-1');
      expect(ids.getInterstitial(0), 'interstitial-1');
      expect(() => ids.getAppOpen(0), throwsStateError);
      expect(() => ids.getRewarded(0), throwsStateError);
      expect(() => ids.getNative(0), throwsStateError);
      expect(() => ids.getRewardedInterstitial(0), throwsStateError);
    });

    test('round robin multiple IDs', () {
      const ids = AdMobIds(
        bannerIds: ['b-1', 'b-2'],
      );

      expect(ids.getBanner(0), 'b-1');
      expect(ids.getBanner(1), 'b-2');
      expect(ids.getBanner(2), 'b-1');
      expect(ids.getBanner(3), 'b-2');
    });
  });

  group('AdsManager Platform IDs', () {
    test('initializes with platform-specific IDs', () async {
      final android = AdMobIds.single(
        bannerId: 'android-banner',
        interstitialId: 'android-interstitial',
      );
      final ios = AdMobIds.single(
        bannerId: 'ios-banner',
        interstitialId: 'ios-interstitial',
      );

      await AdsManager.instance.init(
        androidIds: android,
        iosIds: ios,
        status: AdsStatus.disabled,
      );

      expect(AdsManager.instance.currentIds, isNotNull);
    });
  });
}
