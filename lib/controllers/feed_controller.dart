import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import '../models/video_model.dart';
import '../services/api_service.dart';

class FeedController extends ChangeNotifier {
  final List<VideoModel> _videos = [];
  final Map<int, Player> _players = {};

  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _error;

  List<VideoModel> get videos => _videos;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const int _maxAlivePlayers = 5;
  static const int _preloadAhead = 2;
  static const int _fetchMoreThreshold = 5;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await _fetchFeed(page: 1);
    _isLoading = false;
    notifyListeners();

    if (_videos.isNotEmpty) {
      await _initPlayer(0);
      await _initPlayer(1);
      _players[0]?.play();
    }
  }

  Future<void> _fetchFeed({required int page}) async {
    try {
      final response = await ApiService.getFeed(page: page);
      _videos.addAll(response.videos);
      _error = null;
    } catch (e) {
      _error = 'Failed to load. Pull to refresh.';
    }
  }

  Future<void> onPageChanged(int index) async {
    final previous = _currentIndex;
    _currentIndex = index;

    // Pause previous immediately
    _players[previous]?.pause();

    // Init and play current
    await _initPlayer(index);
    _players[index]?.play();

    // Preload next players silently
    for (int i = 1; i <= _preloadAhead; i++) {
      final next = index + i;
      if (next < _videos.length) {
        _initPlayer(next);
      }
    }

    // Cleanup far away players
    _disposeFarPlayers(index);

    // Fetch more near end
    if (index >= _videos.length - _fetchMoreThreshold && !_isFetchingMore) {
      _fetchMore();
    }

    notifyListeners();
  }

  Future<void> _initPlayer(int index) async {
    if (_players.containsKey(index)) return;
    if (index >= _videos.length || index < 0) return;

    final player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024, // 32MB buffer
      ),
    );

    _players[index] = player;

    await player.open(
      Media(_videos[index].videoUrl),
      play: false,
    );

    await player.setPlaylistMode(PlaylistMode.loop);
  }

  void _disposeFarPlayers(int current) {
    final toDispose = _players.keys
        .where((i) => (i - current).abs() > _maxAlivePlayers)
        .toList();

    for (final i in toDispose) {
      _players[i]?.dispose();
      _players.remove(i);
    }
  }

  Future<void> _fetchMore() async {
    if (_isFetchingMore) return;
    _isFetchingMore = true;
    final nextPage = (_videos.length ~/ 20) + 1;
    await _fetchFeed(page: nextPage);
    _isFetchingMore = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    // Dispose all players
    for (final p in _players.values) {
      p.dispose();
    }
    _players.clear();
    _videos.clear();
    _currentIndex = 0;
    await init();
  }

  Player? getPlayer(int index) => _players[index];

  void togglePlayPause(int index) {
    final player = _players[index];
    if (player == null) return;
    player.state.playing ? player.pause() : player.play();
    notifyListeners();
  }

  bool isPlaying(int index) => _players[index]?.state.playing ?? false;

  @override
  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    _players.clear();
    super.dispose();
  }
}
