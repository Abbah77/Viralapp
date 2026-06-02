import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// AdType — what ad to show
enum AdType { nativeGrid, interstitial, banner }

/// NativeGridAd — mimics a content card in the explore grid
class NativeGridAd {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String ctaText;
  final String destinationUrl;
  final bool isMuted;

  const NativeGridAd({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.ctaText,
    required this.destinationUrl,
    this.isMuted = true,
  });
}

/// AdEngine — controls all ad timing and state.
/// NO Adsterra. Placeholder slots ready for real native SDK (AdMob, AppLovin, etc.)
class AdEngine extends ChangeNotifier {
  final _rng = Random();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _bannerVisible      = false;
  bool _interstitialPending = false;
  int  _feedSwipes         = 0;
  int  _episodeWatched     = 0;
  int  _gridItemsRendered  = 0;

  // Randomized thresholds — NOT fixed positions
  late int _gridAdThreshold;      // how many grid items before first native ad
  late int _interstitialThreshold; // swipes before interstitial
  late int _bannerThreshold;       // swipes before banner appears
  late int _bannerHideCycles;      // how many times banner shows before hiding

  int _bannerShowCount = 0;

  bool get bannerVisible       => _bannerVisible;
  bool get interstitialPending => _interstitialPending;

  AdEngine() {
    _resetThresholds();
  }

  /// Randomize thresholds — keeps ad placement feeling organic
  void _resetThresholds() {
    _gridAdThreshold       = 4 + _rng.nextInt(4);   // 4–7 grid items
    _interstitialThreshold = 6 + _rng.nextInt(5);   // 6–10 swipes
    _bannerThreshold       = 3 + _rng.nextInt(3);   // 3–5 swipes
    _bannerHideCycles      = 2 + _rng.nextInt(3);   // show 2–4 times
  }

  // ── Feed swipe tracking ────────────────────────────────────────────────────
  void onFeedSwipe() {
    _feedSwipes++;

    // Banner logic
    if (_feedSwipes == _bannerThreshold) {
      _showBanner();
    }

    // Interstitial logic
    if (_feedSwipes >= _interstitialThreshold) {
      _feedSwipes = 0;
      _resetThresholds();
      _triggerInterstitial();
    }

    notifyListeners();
  }

  // ── Episode tracking ───────────────────────────────────────────────────────
  void onEpisodeCompleted() {
    _episodeWatched++;
    // Interstitial after every 2–3 episodes (random)
    final threshold = 2 + _rng.nextInt(2);
    if (_episodeWatched >= threshold) {
      _episodeWatched = 0;
      Future.delayed(const Duration(milliseconds: 600), _triggerInterstitial);
    }
  }

  // ── Grid ad logic ──────────────────────────────────────────────────────────
  /// Returns true if this grid index should show a native ad
  bool shouldShowGridAd(int index) {
    if (index == 0) return false; // never first item
    return index % _gridAdThreshold == 0;
  }

  void onGridRendered() {
    _gridItemsRendered++;
    if (_gridItemsRendered % 12 == 0) {
      // Refresh grid ad threshold periodically
      _gridAdThreshold = 4 + _rng.nextInt(4);
    }
  }

  // ── Banner ─────────────────────────────────────────────────────────────────
  void _showBanner() {
    _bannerVisible = true;
    _bannerShowCount++;
    if (_bannerShowCount >= _bannerHideCycles) {
      _bannerShowCount = 0;
      _bannerHideCycles = 2 + _rng.nextInt(3);
      // Auto-hide after random 5–9 seconds
      Timer(Duration(seconds: 5 + _rng.nextInt(4)), () {
        _bannerVisible = false;
        notifyListeners();
      });
    }
  }

  void onBannerClosed() {
    _bannerVisible = false;
    _bannerThreshold = 5 + _rng.nextInt(5); // push next banner further
    notifyListeners();
  }

  // ── Interstitial ───────────────────────────────────────────────────────────
  void _triggerInterstitial() {
    _interstitialPending = true;
    notifyListeners();
  }

  void onInterstitialDismissed() {
    _interstitialPending = false;
    notifyListeners();
  }

  // ── Placeholder native grid ads ────────────────────────────────────────────
  /// Returns a native ad card. Replace with real SDK call when ready.
  NativeGridAd getNativeGridAd(int slot) {
    final ads = [
      NativeGridAd(
        id: 'ad_$slot',
        title: 'Sponsored',
        thumbnailUrl: '',
        ctaText: 'Learn More',
        destinationUrl: '',
      ),
    ];
    return ads[slot % ads.length];
  }
}
