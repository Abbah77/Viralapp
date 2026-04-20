import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import '../models/video_model.dart';
import '../services/api_service.dart';

class FeedController extends ChangeNotifier {
  final List<VideoModel> _videos = [];
  final Map<int, Player> _players = {};
  
  int _currentIndex = 0;
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _error;

  List<VideoModel> get videos => _videos;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Max alive players to save memory
  static const int _maxPlayers = 5;
  static const int _preloadAhead = 2;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await _fetchFeed();
    _isLoading = false;
    notifyListeners();

    // Start playing first video
    if (_videos.isNotEmpty) {
      await _initPlayer(0);
      getPlayer(0)?.play();
    }
  }

  Future<void> _fetchFeed() async {
    try {
      final response = await ApiService.getFeed(page: _currentPage);
      _videos.addAll(response.videos);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> onPageChanged(int index) async {
    final previous = _currentIndex;
    _currentIndex = index;

    // Pause previous
    _players[previous]?.pause();

    // Play current
    await _initPlayer(index);
    _players[index]?.play();

    // Preload next players
    for (int i = 1; i <= _preloadAhead; i++) {
      final nextIndex = index + i;
      if (nextIndex < _videos.length) {
        await _initPlayer(nextIndex);
      }
    }

    // Dispose far players
    _disposeFarPlayers(index);

    // Fetch more when near end
    if (index >= _videos.length - 5 && !_isFetchingMore) {
      _fetchMore();
    }

    notifyListeners();
  }

  Future<void> _initPlayer(int index) async {
    if (_players.containsKey(index)) return;
    if (index >= _videos.length) return;

    final player = Player();
    _players[index] = player;

    await player.open(
      Media(_videos[index].videoUrl),
      play: false,
    );

    // Loop video
    await player.setPlaylistMode(PlaylistMode.loop);
  }

  void _disposeFarPlayers(int currentIndex) {
    final toDispose = _players.keys
        .where((i) => (i - currentIndex).abs() > _maxPlayers)
        .toList();

    for (final i in toDispose) {
      _players[i]?.dispose();
      _players.remove(i);
    }
  }

  Future<void> _fetchMore() async {
    if (_isFetchingMore) return;
    _isFetchingMore = true;
    _currentPage++;
    await _fetchFeed();
    _isFetchingMore = false;
    notifyListeners();
  }

  Player? getPlayer(int index) => _players[index];

  void togglePlayPause(int index) {
    final player = _players[index];
    if (player == null) return;
    player.state.playing ? player.pause() : player.play();
    notifyListeners();
  }

  bool isPlaying(int index) {
    return _players[index]?.state.playing ?? false;
  }

  @override
  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
    super.dispose();
  }
}
