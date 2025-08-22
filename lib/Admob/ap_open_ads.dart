import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  bool _isAdShowing = false;

  /// Load the App Open Ad
  void loadAd() {
    AppOpenAd.load(
      adUnitId: 'ca-app-pub-6736849953392817/7673389778', // Replace with your AdMob App Open Ad Unit ID
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load App Open Ad: $error');
        },
      ),
    );
  }

  /// Show the App Open Ad
  void showAdIfAvailable() {
    if (_appOpenAd == null || _isAdShowing) {
      print('App Open Ad is not ready yet or already showing.');
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        print('App Open Ad dismissed.');
        _isAdShowing = false;
        ad.dispose();
        loadAd(); // Preload a new ad after the current one is dismissed
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('Failed to show App Open Ad: $error');
        _isAdShowing = false;
        ad.dispose();
        loadAd(); // Preload a new ad
      },
      onAdShowedFullScreenContent: (ad) {
        print('App Open Ad is showing.');
        _isAdShowing = true;
      },
    );

    _appOpenAd!.show();
    _appOpenAd = null;
  }
}
