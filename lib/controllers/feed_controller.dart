import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class FeedController extends ChangeNotifier {
  final List<MovieCard> _movies = [];
  final Map<int, Player> _players = {};

  int _currentIndex = 0;
  int? _nextCursor;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _error;

  List<MovieCard> get movies => _movies;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await _fetch();
    _isLoading = false;
    notifyListeners();
    if (_movies.isNotEmpty) {
      _initTrailer(0);
      _initTrailer(1);
      _players[0]?.play();
    }
  }

  Future<void> _fetch() async {
    try {
      final r = await ApiService.getFeed(cursor: _nextCursor, limit: 10);
      _movies.addAll(r.data);
      _nextCursor = r.nextCursor;
      _hasMore = r.hasMore;
      _error = null;
    } catch (e) {
      _error = 'Could not load feed';
    }
  }

  Future<void> onPageChanged(int index) async {
    _players[_currentIndex]?.pause();
    _currentIndex = index;

    await _initTrailer(index);
    _players[index]?.play();

    // Preload next 2
    for (int i = 1; i <= 2; i++) {
      if (index + i < _movies.length) _initTrailer(index + i);
    }

    _cleanup(index);

    // Fetch more near end
    if (index >= _movies.length - 3 && _hasMore && !_isFetchingMore) {
      _fetchMore();
    }

    notifyListeners();
  }

  Future<void> _initTrailer(int i) async {
    if (_players.containsKey(i)) return;
    if (i >= _movies.length || i < 0) return;

    final movie = _movies[i];
    final url = movie.trailerUrl;

    // Skip if no trailer URL
    if (url == null || url.isEmpty) return;

    final p = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 16 * 1024 * 1024, // 16MB — trailers are small
      ),
    );
    _players[i] = p;
    await p.open(Media(url), play: false);
    await p.setPlaylistMode(PlaylistMode.loop);
  }

  void _cleanup(int current) {
    final far = _players.keys
        .where((i) => (i - current).abs() > 4)
        .toList();
    for (final i in far) {
      _players[i]?.dispose();
      _players.remove(i);
    }
  }

  Future<void> _fetchMore() async {
    _isFetchingMore = true;
    await _fetch();
    _isFetchingMore = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    for (final p in _players.values) p.dispose();
    _players.clear();
    _movies.clear();
    _currentIndex = 0;
    _nextCursor = null;
    _hasMore = true;
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
