import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads_unit.dart';

class _AdKey {
  final AdsUnit unit;
  final int index;

  const _AdKey(this.unit, this.index);

  @override
  bool operator ==(Object other) =>
      other is _AdKey && unit == other.unit && index == other.index;

  @override
  int get hashCode => Object.hash(unit, index);
}

/// In-memory cache for preloaded full-screen ads.
/// Automatically disposes replaced or evicted ads to avoid memory leaks.
class AdPreloadCache {
  final Map<_AdKey, Object> _cache = {};

  T? get<T>(AdsUnit unit, int index) {
    final obj = _cache[_AdKey(unit, index)];
    return obj is T ? obj : null;
  }

  void set(AdsUnit unit, int index, Object ad) {
    final key = _AdKey(unit, index);
    final old = _cache[key];
    if (old != null && old != ad) {
      _dispose(old);
    }
    _cache[key] = ad;
  }

  bool contains(AdsUnit unit, int index) =>
      _cache.containsKey(_AdKey(unit, index));

  Object? remove(AdsUnit unit, int index) {
    return _cache.remove(_AdKey(unit, index));
  }

  void clear() {
    for (final ad in _cache.values) {
      _dispose(ad);
    }
    _cache.clear();
  }

  void _dispose(Object ad) {
    try {
      if (ad is InterstitialAd) ad.dispose();
      if (ad is AppOpenAd) ad.dispose();
      if (ad is RewardedAd) ad.dispose();
      if (ad is RewardedInterstitialAd) ad.dispose();
      if (ad is NativeAd) ad.dispose();
      if (ad is BannerAd) ad.dispose();
    } catch (_) {}
  }
}
