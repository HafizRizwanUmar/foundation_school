import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdProvider with ChangeNotifier {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  
  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;
  
  int _lessonCompletionCount = 0;
  int _courseCompletionCount = 0;
  
  // Ad Unit IDs (Use test IDs for development)
  static const String _bannerAdUnitId = 'ca-app-pub-3000745917961529/9876434482'; // Test ID
  static const String _interstitialAdUnitId = 'ca-app-pub-3000745917961529/4418942293'; // Test ID
  static const String _rewardedAdUnitId = 'ca-app-pub-3000745917961529/7250271140'; // Test ID

  // Getters
  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;

  // Initialize ads
  Future<void> initializeAds() async {
    await _loadBannerAd();
    await _loadInterstitialAd();
    await _loadRewardedAd();
  }

  // Load Banner Ad
  Future<void> _loadBannerAd() async {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          _isBannerAdLoaded = false;
          notifyListeners();
          // Retry loading after 30 seconds
          Future.delayed(const Duration(seconds: 30), _loadBannerAd);
        },
      ),
    );
    
    await _bannerAd!.load();
  }

  // Load Interstitial Ad
  Future<void> _loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          notifyListeners();
          
          // Set full screen content callback
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
              notifyListeners();
              // Load next interstitial ad
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial ad failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
              notifyListeners();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _isInterstitialAdLoaded = false;
          notifyListeners();
          // Retry loading after 60 seconds
          Future.delayed(const Duration(seconds: 60), _loadInterstitialAd);
        },
      ),
    );
  }

  // Load Rewarded Ad
  Future<void> _loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          notifyListeners();
          
          // Set full screen content callback
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;
              notifyListeners();
              // Load next rewarded ad
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Rewarded ad failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;
              notifyListeners();
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _isRewardedAdLoaded = false;
          notifyListeners();
          // Retry loading after 60 seconds
          Future.delayed(const Duration(seconds: 60), _loadRewardedAd);
        },
      ),
    );
  }

  // Show Interstitial Ad (strategically placed)
  Future<void> showInterstitialAd({VoidCallback? onAdClosed}) async {
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      // Set callback for when ad is closed
      if (onAdClosed != null) {
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _interstitialAd = null;
            _isInterstitialAdLoaded = false;
            notifyListeners();
            onAdClosed();
            _loadInterstitialAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            debugPrint('Interstitial ad failed to show: $error');
            ad.dispose();
            _interstitialAd = null;
            _isInterstitialAdLoaded = false;
            notifyListeners();
            onAdClosed();
            _loadInterstitialAd();
          },
        );
      }
      
      await _interstitialAd!.show();
    } else {
      // If ad not loaded, call callback immediately
      onAdClosed?.call();
    }
  }

  // Show Rewarded Ad
  Future<void> showRewardedAd({
    required VoidCallback onRewardEarned,
    VoidCallback? onAdClosed,
  }) async {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          onRewardEarned();
        },
      );
      
      // Set callback for when ad is closed
      if (onAdClosed != null) {
        _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _rewardedAd = null;
            _isRewardedAdLoaded = false;
            notifyListeners();
            onAdClosed();
            _loadRewardedAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            debugPrint('Rewarded ad failed to show: $error');
            ad.dispose();
            _rewardedAd = null;
            _isRewardedAdLoaded = false;
            notifyListeners();
            onAdClosed();
            _loadRewardedAd();
          },
        );
      }
    } else {
      // If ad not loaded, call callback immediately
      onAdClosed?.call();
    }
  }

  // Track lesson completion for strategic ad placement
  void onLessonCompleted() {
    _lessonCompletionCount++;
    
    // Show interstitial ad every 3 lessons
    if (_lessonCompletionCount % 3 == 0) {
      showInterstitialAd();
    }
  }

  // Track course completion for strategic ad placement
  void onCourseCompleted() {
    _courseCompletionCount++;
    
    // Show interstitial ad after each course completion
    showInterstitialAd();
  }

  // Check if should show banner ad (not on lesson screen)
  bool shouldShowBannerAd(String screenName) {
    // Don't show banner ads on lesson screen to avoid distraction
    if (screenName == 'lesson') return false;
    
    return _isBannerAdLoaded;
  }

  // Dispose ads
  void disposeAds() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }

  @override
  void dispose() {
    disposeAds();
    super.dispose();
  }
}

