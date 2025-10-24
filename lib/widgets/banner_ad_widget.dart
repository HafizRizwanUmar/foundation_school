import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ad unit ID
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd != null && _isLoaded) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            alignment: Alignment.center,
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ),
      );
    }

    // Fallback placeholder while ad loads or if ad fails
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Center(
        child: _isLoaded
            ? const SizedBox.shrink()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading ad...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Interstitial Ad Helper
class InterstitialAdHelper {
  static InterstitialAd? _interstitialAd;
  static bool _isLoaded = false;

  static void loadAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test ad unit ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded');
          _interstitialAd = ad;
          _isLoaded = true;
          _setFullScreenContentCallback(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error.');
          _interstitialAd = null;
          _isLoaded = false;
        },
      ),
    );
  }

  static void _setFullScreenContentCallback(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('$ad onAdShowedFullScreenContent.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _isLoaded = false;
        loadAd(); // Load next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _isLoaded = false;
        loadAd(); // Load next ad
      },
    );
  }

  static void showAd() {
    if (_isLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      debugPrint('Interstitial ad not ready yet.');
      loadAd(); // Try to load if not loaded
    }
  }

  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoaded = false;
  }
}

// Rewarded Ad Helper
class RewardedAdHelper {
  static RewardedAd? _rewardedAd;
  static bool _isLoaded = false;

  static void loadAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // Test ad unit ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          _rewardedAd = ad;
          _isLoaded = true;
          _setFullScreenContentCallback(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _isLoaded = false;
        },
      ),
    );
  }

  static void _setFullScreenContentCallback(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('$ad onAdShowedFullScreenContent.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _isLoaded = false;
        loadAd(); // Load next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _isLoaded = false;
        loadAd(); // Load next ad
      },
    );
  }

  static void showAd({required Function(AdWithoutView, RewardItem) onUserEarnedReward}) {
    if (_isLoaded && _rewardedAd != null) {
      _rewardedAd!.show(onUserEarnedReward: onUserEarnedReward);
    } else {
      debugPrint('Rewarded ad not ready yet.');
      loadAd(); // Try to load if not loaded
    }
  }

  static void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isLoaded = false;
  }
}

