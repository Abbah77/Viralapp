import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/models.dart';

class PlayerController extends ChangeNotifier {
  final MovieCard movie;
  final List<EpisodeModel> episodes;
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

  // Video aspect ratio — detected from actual video
  double _videoAspectRatio = 9 / 16; // default vertical
  bool _isVerticalVideo = true;

  PlayerController({
    required this.movie,
    required this.episodes,
    int startEpisode = 0,
  }) {
    _currentEp = startEpisode;
    _player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024,
      ),
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
  bool get isVerticalVideo => _isVerticalVideo;
  double get videoAspectRatio => _videoAspectRatio;
  EpisodeModel get episode => episodes[_currentEp];
  int get totalEpisodes => episodes.length;

  Future<void> _init() async {
    WakelockPlus.enable();

    if (episodes.isEmpty) return;

    await _player.open(
      Media(episodes[_currentEp].url),
      play: true,
    );

    // Detect video aspect ratio
    _player.stream.videoParams.listen((params) {
      if (params.w != null && params.h != null && params.w! > 0 && params.h! > 0) {
        _videoAspectRatio = params.w! / params.h!;
        _isVerticalVideo = _videoAspectRatio < 1.0;
        notifyListeners();
      }
    });

    _player.stream.position.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.stream.duration.listen((dur) {
      if (dur.inSeconds > 0) {
        _duration = dur;
        notifyListeners();
      }
    });

    _player.stream.buffering.listen((b) {
      _isBuffering = b;
      notifyListeners();
    });

    _player.stream.completed.listen((completed) {
      if (completed) _onEpisodeCompleted();
    });

    _autoHide();
  }

  void _onEpisodeCompleted() {
    if (_currentEp < episodes.length - 1) {
      playEpisode(_currentEp + 1);
    }
  }

  Future<void> playEpisode(int index) async {
    if (index < 0 || index >= episodes.length) return;
    _currentEp = index;
    _position = Duration.zero;
    _duration = Duration.zero;
    _isBuffering = true;
    await _player.open(Media(episodes[index].url), play: true);
    notifyListeners();
  }

  void togglePlayPause() {
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
    _player.seek(const Duration(seconds: 90));
  }

  Future<void> setSpeed(double s) async {
    _speed = s;
    await _player.setRate(s);
    notifyListeners();
  }

  Future<void> setLandscape(bool landscape) async {
    _isLandscape = landscape;
    if (landscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
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
