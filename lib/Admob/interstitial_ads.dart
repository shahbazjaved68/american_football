import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdManager {
  static InterstitialAd? _interstitialAd;
  static bool _isAdLoaded = false;
  static bool _isLoading = false;

  /// Initialize at app start
  static void initialize() {
    _loadInterstitialAd();
  }

  /// Load Interstitial Ad
  static void _loadInterstitialAd() {
    if (_isLoading) return; // Prevent duplicate requests
    _isLoading = true;

    InterstitialAd.load(
       //adUnitId: 'ca-app-pub-6736849953392817/6246458158', // ✅ Actual ad unit ID
       adUnitId: 'ca-app-pub-3940256099942544/1033173712', // ✅ Test ad unit ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          _isLoading = false;
          debugPrint('✅ Interstitial Ad Loaded');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          _isAdLoaded = false;
          _isLoading = false;
          debugPrint('❌ InterstitialAd failed to load: $error');

          // Retry after a short delay
          Future.delayed(const Duration(seconds: 10), () {
            _loadInterstitialAd();
          });
        },
      ),
    );
  }

  /// Show Interstitial Ad
  static void showInterstitialAd({VoidCallback? onAdDismissed}) {
    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _loadInterstitialAd(); // Preload next ad
          if (onAdDismissed != null) onAdDismissed();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _loadInterstitialAd(); // Retry loading
          if (onAdDismissed != null) onAdDismissed();
        },
      );

      _interstitialAd!.show();
      _interstitialAd = null;
      _isAdLoaded = false;
      debugPrint('🎬 Interstitial Ad Shown');
    } else {
      debugPrint('⚠️ Interstitial ad not ready, continuing flow...');
      if (onAdDismissed != null) onAdDismissed();
      _loadInterstitialAd(); // Try to load again
    }
  }

  /// Dispose Ad (if needed)
  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
    _isLoading = false;
  }
}
