import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_manager.dart';
import 'ads_unit.dart';

/// Pre-configured Banner Ad widget with adaptive banner sizing and error fallbacks.
class BannerAdContainer extends StatefulWidget {
  final int index;
  final Widget? placeholder;
  final void Function(BannerAd ad)? onLoaded;
  final void Function(LoadAdError error)? onFailedToLoad;

  const BannerAdContainer({
    super.key,
    this.index = 0,
    this.placeholder,
    this.onLoaded,
    this.onFailedToLoad,
  });

  @override
  State<BannerAdContainer> createState() => _BannerAdContainerState();
}

class _BannerAdContainerState extends State<BannerAdContainer> {
  BannerAd? _banner;
  bool _isLoaded = false;
  AdSize? _adSize;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_banner == null && !_isLoading) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant BannerAdContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _disposeAd();
      _load();
    }
  }

  void _disposeAd() {
    _banner?.dispose();
    _banner = null;
    _isLoaded = false;
    _adSize = null;
    _isLoading = false;
  }

  Future<void> _load() async {
    if (_isLoading) return;
    if (AdsManager.instance.isAdsDisabled) return;

    _isLoading = true;

    final width = MediaQuery.sizeOf(context).width.truncate();
    final adSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (!mounted) {
      _isLoading = false;
      return;
    }

    _adSize = adSize ?? AdSize.banner;
    final adUnitId = AdsManager.instance.getAdUnitId(AdsUnit.banner, widget.index);

    final ad = BannerAd(
      adUnitId: adUnitId,
      size: _adSize!,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _isLoaded = true;
          });
          widget.onLoaded?.call(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ [BannerAdContainer] Banner failed to load: $error');
          ad.dispose();
          if (!mounted) return;
          setState(() {
            if (_banner == ad) _banner = null;
            _isLoaded = false;
          });
          _isLoading = false;
          widget.onFailedToLoad?.call(error);
        },
      ),
    );

    await ad.load();
    if (!mounted) {
      ad.dispose();
      return;
    }

    setState(() {
      _banner = ad;
    });
    _isLoading = false;
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _banner == null || _adSize == null) {
      return widget.placeholder ?? const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: _adSize!.height.toDouble(),
      child: Align(
        alignment: Alignment.center,
        child: AdWidget(ad: _banner!),
      ),
    );
  }
}
