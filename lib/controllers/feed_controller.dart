import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import '../models/models.dart';
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

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await _fetch(page: 1);
    _isLoading = false;
    notifyListeners();
    if (_videos.isNotEmpty) {
      await _initPlayer(0);
      await _initPlayer(1);
      _players[0]?.play();
    }
  }

  Future<void> _fetch({required int page}) async {
    try {
      final r = await ApiService.getFeed(page: page);
      _videos.addAll(r.videos);
      _error = null;
    } catch (e) {
      _error = 'Could not load. Pull to refresh.';
    }
  }

  Future<void> onPageChanged(int index) async {
    _players[_currentIndex]?.pause();
    _currentIndex = index;
    await _initPlayer(index);
    _players[index]?.play();
    for (int i = 1; i <= 2; i++) {
      if (index + i < _videos.length) _initPlayer(index + i);
    }
    _cleanup(index);
    if (index >= _videos.length - 5 && !_isFetchingMore) _fetchMore();
    notifyListeners();
  }

  Future<void> _initPlayer(int i) async {
    if (_players.containsKey(i) || i >= _videos.length || i < 0) return;
    final p = Player(
      configuration: const PlayerConfiguration(bufferSize: 32 * 1024 * 1024),
    );
    _players[i] = p;
    await p.open(Media(_videos[i].videoUrl), play: false);
    await p.setPlaylistMode(PlaylistMode.loop);
  }

  void _cleanup(int current) {
    final far = _players.keys.where((i) => (i - current).abs() > 4).toList();
    for (final i in far) {
      _players[i]?.dispose();
      _players.remove(i);
    }
  }

  Future<void> _fetchMore() async {
    _isFetchingMore = true;
    await _fetch(page: (_videos.length ~/ 20) + 1);
    _isFetchingMore = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    for (final p in _players.values) p.dispose();
    _players.clear();
    _videos.clear();
    _currentIndex = 0;
    await init();
  }

  Player? getPlayer(int i) => _players[i];
  bool isPlaying(int i) => _players[i]?.state.playing ?? false;

  void togglePlay(int i) {
    final p = _players[i];
    if (p == null) return;
    p.state.playing ? p.pause() : p.play();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final p in _players.values) p.dispose();
    _players.clear();
    super.dispose();
  }
}
