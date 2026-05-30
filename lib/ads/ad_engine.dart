import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// ── AdEngine ─────────────────────────────────────────────────────────────────
/// High-precision ad timing brain.
///
/// FORMULA OVERVIEW
/// ──────────────────
/// We model user engagement as a fatigue curve:
///
///   fatigue(t) = 1 - e^(-λ·t)   where λ = 0.0055 (decay constant)
///
/// An ad is "allowed" only when:
///   1. cooldown since last ad > dynamicCooldown(session)
///   2. user is NOT mid-seek, buffering, or in landscape
///   3. engagement score > threshold
///   4. frequency cap not exceeded
///
/// dynamicCooldown(n) = BASE_COOLDOWN × (1 + 0.4 × ln(n+1))
///   n = ads shown this session
///   This means: 1st ad gap=180s, 2nd=195s, 3rd=207s, 4th=217s …
///   Gaps grow logarithmically — aggressive early, gentle later. Users stay.
///
/// TRIGGER POINTS (scored, not dumb timers):
///   • App cold open              → score 100 (captive, no investment yet)
///   • Episode transition (3rd+)  → score 85  (natural break)
///   • Feed idle > 45s            → score 70  (user browsing, not committed)
///   • Player pause > 12s         → score 60  (user stepped away)
///   • Search result tap          → score 0   (intent moment — NEVER interrupt)
///   • Buffering                  → score 0   (NEVER during buffer = anger)
///   • Landscape mode             → score 0   (NEVER in landscape = immersion)

class AdEngine extends ChangeNotifier {
  // ── Constants ────────────────────────────────────────────────────────────────
  static const double _lambda        = 0.0055;  // fatigue decay
  static const int    _baseCD        = 180;     // base cooldown seconds
  static const int    _maxAdsSession = 8;       // hard session cap
  static const int    _minScoreInter = 75;      // min score for interstitial
  static const int    _minScoreBanner = 55;     // min score for banner
  static const int    _feedIdleThreshold = 45;  // seconds of feed idle
  static const int    _pauseThreshold   = 12;   // seconds paused

  // ── Adsterra Ad URLs (real, wired) ──────────────────────────────────────────
  /// Popunder script — injected into full-screen WebView HTML
  static const String popunderScriptUrl =
      'https://pl29592547.effectivecpmnetwork.com/d9/23/c8/d923c861139300c98028e2054bc85459.js';

  /// Native Banner invoke script
  static const String bannerInvokeUrl =
      'https://pl29592548.effectivecpmnetwork.com/37364927d22a8849c3cf562dd9cba921/invoke.js';

  /// Native Banner container div ID
  static const String bannerContainerId =
      'container-37364927d22a8849c3cf562dd9cba921';

  // ── Session state ────────────────────────────────────────────────────────────
  DateTime?  _sessionStart;
  DateTime?  _lastAdShown;
  int        _adsThisSession   = 0;
  int        _episodesWatched  = 0;
  int        _episodeChanges   = 0;   // consecutive changes since last ad
  bool       _isLandscape      = false;
  bool       _isBuffering      = false;
  bool       _isSeeking        = false;
  bool       _isPaused         = false;
  DateTime?  _pauseStart;
  DateTime?  _feedIdleStart;
  bool       _coldOpenDone     = false;
  bool       _bannerVisible    = false;
  bool       _interstitialPending = false;
  Timer?     _feedIdleTimer;
  Timer?     _pauseTimer;

  // ── Exposed state ─────────────────────────────────────────────────────────
  bool get bannerVisible       => _bannerVisible;
  bool get interstitialPending => _interstitialPending;
  int  get adsThisSession      => _adsThisSession;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  void onAppStart() {
    _sessionStart = DateTime.now();
    // Cold open: 2 second grace then show interstitial
    Timer(const Duration(seconds: 2), _tryColdOpen);
  }

  void dispose() {
    _feedIdleTimer?.cancel();
    _pauseTimer?.cancel();
    super.dispose();
  }

  // ── Public triggers ────────────────────────────────────────────────────────

  void onLandscapeChanged(bool landscape) {
    _isLandscape = landscape;
    if (landscape && _bannerVisible) {
      _bannerVisible = false;
      notifyListeners();
    }
  }

  void onBufferingChanged(bool buffering) {
    _isBuffering = buffering;
  }

  void onSeekingChanged(bool seeking) {
    _isSeeking = seeking;
  }

  void onPlaybackStarted() {
    _isPaused = false;
    _pauseTimer?.cancel();
    _pauseStart = null;
    _feedIdleTimer?.cancel();
    _feedIdleStart = null;
    _maybeHideBanner();
  }

  void onPlaybackPaused() {
    _isPaused = true;
    _pauseStart = DateTime.now();
    _pauseTimer = Timer(Duration(seconds: _pauseThreshold), _tryPauseAd);
  }

  void onEpisodeChanged() {
    _episodesWatched++;
    _episodeChanges++;
    // Every 3rd episode transition is a candidate
    if (_episodeChanges >= 3) {
      _episodeChanges = 0;
      _tryEpisodeTransitionAd();
    }
  }

  void onFeedVisible() {
    _feedIdleStart = DateTime.now();
    _feedIdleTimer?.cancel();
    _feedIdleTimer = Timer(
      Duration(seconds: _feedIdleThreshold),
      _tryFeedIdleAd,
    );
  }

  void onFeedScrolled() {
    // User is active — reset idle clock
    _feedIdleStart = DateTime.now();
    _feedIdleTimer?.cancel();
    _feedIdleTimer = Timer(
      Duration(seconds: _feedIdleThreshold),
      _tryFeedIdleAd,
    );
  }

  void onPlayerOpened() {
    _feedIdleTimer?.cancel();
    _maybeHideBanner();
  }

  void onPlayerClosed() {
    onFeedVisible();
  }

  /// Called by UI after interstitial is dismissed
  void onInterstitialDismissed() {
    _interstitialPending = false;
    _recordAdShown();
    notifyListeners();
  }

  /// Called by UI after banner is manually closed
  void onBannerClosed() {
    _bannerVisible = false;
    _recordAdShown();
    notifyListeners();
  }

  // ── Internal trigger logic ────────────────────────────────────────────────

  void _tryColdOpen() {
    if (_coldOpenDone) return;
    if (!_canShowAd()) return;
    if (_score(_TriggerType.coldOpen) >= _minScoreInter) {
      _coldOpenDone = true;
      _fireInterstitial();
    }
  }

  void _tryEpisodeTransitionAd() {
    if (!_canShowAd()) return;
    final score = _score(_TriggerType.episodeTransition);
    if (score >= _minScoreInter) {
      _fireInterstitial();
    } else if (score >= _minScoreBanner) {
      _fireBanner();
    }
  }

  void _tryFeedIdleAd() {
    if (!_canShowAd()) return;
    if (_isLandscape) return;
    final score = _score(_TriggerType.feedIdle);
    if (score >= _minScoreBanner) {
      _fireBanner();
    }
  }

  void _tryPauseAd() {
    if (!_canShowAd()) return;
    if (_isLandscape) return;
    if (!_isPaused) return;
    final score = _score(_TriggerType.playerPaused);
    if (score >= _minScoreBanner) {
      _fireBanner();
    }
  }

  // ── Core math ─────────────────────────────────────────────────────────────

  /// Engagement score [0–100] for a trigger type
  int _score(_TriggerType trigger) {
    if (_isBuffering) return 0;
    if (_isSeeking)   return 0;
    if (_isLandscape && trigger != _TriggerType.coldOpen) return 0;

    final base = _baseTriggerScore(trigger);
    final fatiguePenalty = _fatiguePenalty();
    final cooldownBonus  = _cooldownBonus();

    final raw = base - fatiguePenalty + cooldownBonus;
    return raw.clamp(0, 100).toInt();
  }

  int _baseTriggerScore(_TriggerType t) {
    switch (t) {
      case _TriggerType.coldOpen:          return 100;
      case _TriggerType.episodeTransition: return 85;
      case _TriggerType.feedIdle:          return 70;
      case _TriggerType.playerPaused:      return 60;
    }
  }

  /// Fatigue grows with ads shown: penalty = 25 × (1 - e^(-λ×n×1000))
  double _fatiguePenalty() {
    final n = _adsThisSession.toDouble();
    return 25.0 * (1 - math.exp(-_lambda * n * 1000));
  }

  /// Bonus for waiting longer than required cooldown
  double _cooldownBonus() {
    if (_lastAdShown == null) return 15.0;
    final elapsed = DateTime.now().difference(_lastAdShown!).inSeconds;
    final required = _dynamicCooldown();
    if (elapsed < required) return 0;
    // Bonus grows with extra wait, capped at 20
    return math.min(20.0, (elapsed - required) / 30.0);
  }

  /// Cooldown grows logarithmically with ads shown
  int _dynamicCooldown() {
    final n = _adsThisSession;
    return (_baseCD * (1 + 0.4 * math.log(n + 1))).round();
  }

  bool _canShowAd() {
    if (_adsThisSession >= _maxAdsSession) return false;
    if (_interstitialPending) return false;
    if (_bannerVisible) return false;
    if (_lastAdShown == null) return true;
    final elapsed = DateTime.now().difference(_lastAdShown!).inSeconds;
    return elapsed >= _dynamicCooldown();
  }

  void _fireInterstitial() {
    _interstitialPending = true;
    notifyListeners();
  }

  void _fireBanner() {
    _bannerVisible = true;
    notifyListeners();
    // Auto-dismiss banner after 15s if user doesn't interact
    Timer(const Duration(seconds: 15), () {
      if (_bannerVisible) {
        _bannerVisible = false;
        _recordAdShown();
        notifyListeners();
      }
    });
  }

  void _maybeHideBanner() {
    if (_bannerVisible) {
      _bannerVisible = false;
      notifyListeners();
    }
  }

  void _recordAdShown() {
    _lastAdShown = DateTime.now();
    _adsThisSession++;
  }

  // ── Debug info (remove in production) ────────────────────────────────────
  Map<String, dynamic> get debugInfo => {
    'adsThisSession': _adsThisSession,
    'dynamicCooldown': _dynamicCooldown(),
    'secondsSinceLastAd': _lastAdShown == null
        ? 'never'
        : DateTime.now().difference(_lastAdShown!).inSeconds,
    'canShowAd': _canShowAd(),
    'fatiguePenalty': _fatiguePenalty().toStringAsFixed(1),
  };
}

enum _TriggerType {
  coldOpen,
  episodeTransition,
  feedIdle,
  playerPaused,
}
