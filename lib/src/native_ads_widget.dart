import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_manager.dart';
import 'ads_unit.dart';

/// Pre-configured Native Ad container supporting both small and medium templates.
/// Automatically adapts colors for Dark Mode and Light Mode.
class NativeAdsContainer extends StatefulWidget {
  final int index;
  final NativeAdsSize size;
  final Widget? placeholder;
  final NativeTemplateStyle? customStyle;
  final void Function(NativeAd ad)? onLoaded;
  final void Function(LoadAdError error)? onFailedToLoad;

  const NativeAdsContainer({
    super.key,
    this.index = 0,
    this.size = NativeAdsSize.small,
    this.placeholder,
    this.customStyle,
    this.onLoaded,
    this.onFailedToLoad,
  });

  @override
  State<NativeAdsContainer> createState() => _NativeAdsContainerState();
}

class _NativeAdsContainerState extends State<NativeAdsContainer> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant NativeAdsContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index || oldWidget.size != widget.size) {
      _disposeAd();
      _load();
    }
  }

  void _disposeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _isLoaded = false;
    _isLoading = false;
  }

  void _load() {
    if (_isLoading) return;
    if (AdsManager.instance.isAdsDisabled) return;

    _isLoading = true;

    final adUnitId = AdsManager.instance.getAdUnitId(AdsUnit.native, widget.index);
    final isSmall = widget.size == NativeAdsSize.small;

    final templateStyle = widget.customStyle ?? _buildThemeAwareStyle(isSmall);

    final ad = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _isLoaded = true;
          });
          widget.onLoaded?.call(ad as NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ [NativeAdsContainer] Native ad failed to load: $error');
          ad.dispose();
          if (!mounted) return;
          setState(() {
            if (_nativeAd == ad) _nativeAd = null;
            _isLoaded = false;
          });
          _isLoading = false;
          widget.onFailedToLoad?.call(error);
        },
      ),
      nativeTemplateStyle: templateStyle,
      nativeAdOptions: NativeAdOptions(
        mediaAspectRatio: MediaAspectRatio.landscape,
        shouldRequestMultipleImages: true,
        videoOptions: isSmall
            ? null
            : VideoOptions(
                startMuted: true,
                clickToExpandRequested: true,
                customControlsRequested: true,
              ),
      ),
    );

    setState(() {
      _nativeAd = ad;
      _isLoaded = false;
    });

    ad.load();
    _isLoading = false;
  }

  NativeTemplateStyle _buildThemeAwareStyle(bool isSmall) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NativeTemplateStyle(
      templateType: isSmall ? TemplateType.small : TemplateType.medium,
      mainBackgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
      cornerRadius: 12.0,
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: Colors.white,
        backgroundColor: const Color(0xFF8C34E8),
        style: NativeTemplateFontStyle.bold,
        size: 14.0,
      ),
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: isDark ? Colors.white : Colors.black87,
        style: NativeTemplateFontStyle.bold,
        size: 15.0,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: isDark ? Colors.white70 : Colors.black54,
        size: 13.0,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: isDark ? Colors.white54 : Colors.grey,
        size: 11.0,
      ),
    );
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) {
      return widget.placeholder ?? const SizedBox.shrink();
    }

    final height = widget.size == NativeAdsSize.small ? 140.0 : 340.0;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 320,
        minHeight: height,
        maxHeight: height,
      ),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
