import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/models.dart';
import '../ads/ad_engine.dart';
import '../services/coin_service.dart';

/// Episode lock state
enum EpisodeLockState { free, locked, unlocked }

class PlayerController extends ChangeNotifier {
  final MovieCard movie;
  final List<EpisodeModel> episodes;
  final AdEngine? adEngine;
  CoinService? coinService;

  late final Player _player;

  int _currentEp = 0;
  bool _isLandscape = false;
  bool _showControls = true;
  bool _isLocked = false; // screen lock, not episode lock
  bool _showDrawer = false;
  bool _showToolsDrawer = false;
  double _speed = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isBuffering = true;
  double _videoAspectRatio = 9 / 16;
  bool _isVerticalVideo = true;

  // Episode unlock tracking — set of unlocked episode indices
  final Set<int> _unlockedEpisodes = {};
  bool _showUnlockSheet = false;

  PlayerController({
    required this.movie,
    required this.episodes,
    int startEpisode = 0,
    this.adEngine,
    this.coinService,
  }) {
    _currentEp = startEpisode;
    _player = Player(configuration: const PlayerConfiguration(bufferSize: 32 * 1024 * 1024));
    _init();
  }

  Player get player => _player;
  int get currentEp => _currentEp;
  bool get isLandscape => _isLandscape;
  bool get showControls => _showControls;
  bool get isLocked => _isLocked;
  bool get showDrawer => _showDrawer;
  bool get showToolsDrawer => _showToolsDrawer;
  double get speed => _speed;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isBuffering => _isBuffering;
  bool get isPlaying => _player.state.playing;
  bool get isVerticalVideo => _isVerticalVideo;
  double get videoAspectRatio => _videoAspectRatio;
  bool get showUnlockSheet => _showUnlockSheet;
  EpisodeModel get episode => episodes[_currentEp];
  int get totalEpisodes => episodes.length;

  // ── Episode locking ────────────────────────────────────────────────────────

  /// Episode 1-N (1-indexed display), free up to freeEpisodesCount
  EpisodeLockState lockStateFor(int index) {
    final coinSvc = coinService;
    if (coinSvc == null) return EpisodeLockState.free;
    if (coinSvc.isEpisodeFree(index + 1)) return EpisodeLockState.free;
    if (_unlockedEpisodes.contains(index)) return EpisodeLockState.unlocked;
    return EpisodeLockState.locked;
  }

  bool get currentEpisodeLocked => lockStateFor(_currentEp) == EpisodeLockState.locked;

  /// Attempt to unlock episode with coins. Returns true if success.
  Future<bool> unlockCurrentEpisode() async {
    final coinSvc = coinService;
    if (coinSvc == null) return false;
    final isFinale = _currentEp == episodes.length - 1;
    final success = await coinSvc.unlockEpisode(_currentEp, isFinale: isFinale);
    if (success) {
      _unlockedEpisodes.add(_currentEp);
      _showUnlockSheet = false;
      // Play now that it's unlocked
      await _player.open(Media(episodes[_currentEp].url), play: true);
      notifyListeners();
    }
    return success;
  }

  void showUnlockPrompt() {
    _showUnlockSheet = true;
    notifyListeners();
  }

  void dismissUnlockSheet() {
    _showUnlockSheet = false;
    notifyListeners();
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    WakelockPlus.enable();
    if (episodes.isEmpty) return;

    // Only play if episode is not locked
    if (lockStateFor(_currentEp) != EpisodeLockState.locked) {
      await _player.open(Media(episodes[_currentEp].url), play: true);
    } else {
      // Show unlock sheet
      _showUnlockSheet = true;
    }

    _player.stream.videoParams.listen((params) {
      if (params.w != null && params.h != null && params.w! > 0 && params.h! > 0) {
        _videoAspectRatio = params.w! / params.h!;
        _isVerticalVideo = _videoAspectRatio < 1.0;
        notifyListeners();
      }
    });

    _player.stream.position.listen((pos) { _position = pos; notifyListeners(); });
    _player.stream.duration.listen((dur) { if (dur.inSeconds > 0) { _duration = dur; notifyListeners(); } });
    _player.stream.buffering.listen((b) { _isBuffering = b; notifyListeners(); });
    _player.stream.completed.listen((completed) { if (completed) _onEpisodeCompleted(); });

    _autoHide();
  }

  void _onEpisodeCompleted() {
    adEngine?.onEpisodeCompleted();
    notifyListeners();
  }

  // ── Playback controls ──────────────────────────────────────────────────────

  Future<void> playEpisode(int index) async {
    if (index < 0 || index >= episodes.length) return;
    _currentEp = index;
    _position = Duration.zero;
    _duration = Duration.zero;
    _isBuffering = true;
    _showUnlockSheet = false;

    // Check if locked
    if (lockStateFor(index) == EpisodeLockState.locked) {
      _showUnlockSheet = true;
      notifyListeners();
      return;
    }

    adEngine?.onEpisodeCompleted();
    await _player.open(Media(episodes[index].url), play: true);
    notifyListeners();
  }

  void togglePlayPause() {
    if (currentEpisodeLocked) { showUnlockPrompt(); return; }
    _player.state.playing ? _player.pause() : _player.play();
    notifyListeners();
  }

  void seekTo(Duration pos) => _player.seek(pos);
  void seekRelative(int secs) {
    final target = _position + Duration(seconds: secs);
    _player.seek(target.isNegative ? Duration.zero : target);
  }

  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  void seekProgress(double value) {
    final ms = (value * _duration.inMilliseconds).toInt();
    _player.seek(Duration(milliseconds: ms));
  }

  String get positionLabel => _fmt(_position);
  String get durationLabel => _fmt(_duration);
  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  // ── UI controls ────────────────────────────────────────────────────────────

  void toggleControls() {
    if (_isLocked) return;
    _showControls = !_showControls;
    notifyListeners();
    if (_showControls) _autoHide();
  }

  void _autoHide() {
    Future.delayed(const Duration(seconds: 4), () {
      if (_showControls && !_showDrawer && !_showToolsDrawer && isPlaying) {
        _showControls = false;
        notifyListeners();
      }
    });
  }

  void showControlsTemporary() {
    _showControls = true;
    notifyListeners();
    _autoHide();
  }

  void toggleDrawer()      { _showDrawer = !_showDrawer;           if (_showDrawer) _showControls = false; notifyListeners(); }
  void toggleToolsDrawer() { _showToolsDrawer = !_showToolsDrawer; notifyListeners(); }
  void toggleLock()        { _isLocked = !_isLocked; _showControls = !_isLocked; notifyListeners(); }
  void skipIntro()         { _player.seek(const Duration(seconds: 90)); }

  Future<void> setSpeed(double s) async {
    _speed = s;
    await _player.setRate(s);
    notifyListeners();
  }

  Future<void> setLandscape(bool landscape) async {
    _isLandscape = landscape;
    if (landscape) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    notifyListeners();
  }

  Future<void> toggleOrientation() => setLandscape(!_isLandscape);

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _player.dispose();
    super.dispose();
  }
}
