import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/models.dart';

class PlayerController extends ChangeNotifier {
  final MovieModel movie;
  late final Player _player;

  int _currentEp = 0;
  bool _isLandscape = false;
  bool _showControls = true;
  bool _isLocked = false;
  bool _showDrawer = false;
  bool _showToolsDrawer = false;
  double _speed = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isBuffering = true;

  PlayerController({required this.movie, int startEpisode = 0}) {
    _currentEp = startEpisode;
    _player = Player(
      configuration: const PlayerConfiguration(bufferSize: 64 * 1024 * 1024),
    );
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
  EpisodeModel get episode => movie.episodes[_currentEp];
  int get totalEpisodes => movie.episodes.length;

  Future<void> _init() async {
    WakelockPlus.enable();
    await _player.open(Media(movie.videoUrl), play: false);

    // Seek to episode start
    final ep = movie.episodes[_currentEp];
    await _player.seek(Duration(seconds: ep.startSec));
    await _player.play();

    _player.stream.position.listen((pos) {
      _position = pos;
      final ep = movie.episodes[_currentEp];

      // Auto next episode
      if (pos.inSeconds >= ep.endSec - 1 &&
          _currentEp < movie.episodes.length - 1) {
        playEpisode(_currentEp + 1);
      }
      notifyListeners();
    });

    _player.stream.duration.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    _player.stream.buffering.listen((b) {
      _isBuffering = b;
      notifyListeners();
    });
  }

  Future<void> playEpisode(int index) async {
    if (index < 0 || index >= movie.episodes.length) return;
    _currentEp = index;
    final ep = movie.episodes[index];
    await _player.seek(Duration(seconds: ep.startSec));
    await _player.play();
    notifyListeners();
  }

  void togglePlayPause() {
    _player.state.playing ? _player.pause() : _player.play();
    notifyListeners();
  }

  void seekTo(Duration pos) {
    _player.seek(pos);
  }

  void seekRelative(int secs) {
    final newPos = _position + Duration(seconds: secs);
    _player.seek(newPos);
  }

  // Episode progress within current episode only
  double get episodeProgress {
    final ep = movie.episodes[_currentEp];
    final epDur = ep.endSec - ep.startSec;
    if (epDur <= 0) return 0;
    final epPos = (_position.inSeconds - ep.startSec).clamp(0, epDur);
    return epPos / epDur;
  }

  void seekEpisodeProgress(double value) {
    final ep = movie.episodes[_currentEp];
    final epDur = ep.endSec - ep.startSec;
    final targetSec = ep.startSec + (value * epDur).toInt();
    _player.seek(Duration(seconds: targetSec));
  }

  String get positionLabel {
    final ep = movie.episodes[_currentEp];
    final epPos = (_position.inSeconds - ep.startSec).clamp(0, ep.endSec);
    return _formatDur(Duration(seconds: epPos));
  }

  String get durationLabel {
    final ep = movie.episodes[_currentEp];
    final epDur = ep.endSec - ep.startSec;
    return _formatDur(Duration(seconds: epDur));
  }

  String _formatDur(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void toggleControls() {
    if (_isLocked) return;
    _showControls = !_showControls;
    notifyListeners();
    if (_showControls) _autoHideControls();
  }

  void _autoHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_showControls && !_showDrawer && !_showToolsDrawer) {
        _showControls = false;
        notifyListeners();
      }
    });
  }

  void showControlsTemporary() {
    _showControls = true;
    notifyListeners();
    _autoHideControls();
  }

  void toggleDrawer() {
    _showDrawer = !_showDrawer;
    if (_showDrawer) _showControls = false;
    notifyListeners();
  }

  void toggleToolsDrawer() {
    _showToolsDrawer = !_showToolsDrawer;
    notifyListeners();
  }

  void toggleLock() {
    _isLocked = !_isLocked;
    _showControls = !_isLocked;
    notifyListeners();
  }

  void skipIntro() {
    final ep = movie.episodes[_currentEp];
    _player.seek(Duration(seconds: ep.startSec + 90));
  }

  Future<void> setSpeed(double s) async {
    _speed = s;
    await _player.setRate(s);
    notifyListeners();
  }

  Future<void> toggleOrientation() async {
    _isLandscape = !_isLandscape;
    if (_isLandscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _player.dispose();
    super.dispose();
  }
}
