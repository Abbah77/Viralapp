import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/video.dart';
import '../services/api_service.dart';
import '../services/player_cache.dart';
import '../widgets/video_card.dart';

class ForYouFeed extends StatefulWidget {
  const ForYouFeed({super.key});

  @override
  State<ForYouFeed> createState() => _ForYouFeedState();
}

class _ForYouFeedState extends State<ForYouFeed> {
  final ApiService _api = ApiService();
  final PlayerCache _playerCache = PlayerCache();
  final PageController _pageController = PageController();
  
  List<Video> _videos = [];
  List<PreloadVideo> _preloadQueue = [];
  int _currentIndex = 0;
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _fetchFeed() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() => _isLoading = true);
    
    try {
      final response = await _api.fetchFeed(page: _currentPage);
      
      setState(() {
        _videos.addAll(response.videos);
        _preloadQueue = response.preloadUrls;
        _currentPage++;
        _hasMore = response.videos.isNotEmpty;
      });
      
      // Preload thumbnails aggressively
      _prefetchThumbnails();
      
      // Preload next video URLs in background
      _preloadNextVideos();
      
    } catch (e) {
      debugPrint('Feed error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _prefetchThumbnails() {
    for (var preload in _preloadQueue.take(10)) {
      precacheImage(
        CachedNetworkImageProvider(preload.thumbnailUrl),
        context,
      );
    }
  }

  Future<void> _preloadNextVideos() async {
    for (var preload in _preloadQueue.take(4)) {
      _playerCache.preloadVideo(preload.videoUrl);
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    
    // Fetch more when 15/20
    if (index >= _videos.length - 5 && _hasMore) {
      _fetchFeed();
    }
    
    // Clean up players far from current
    _cleanupDistantPlayers(index);
  }

  void _cleanupDistantPlayers(int currentIndex) {
    final keysToKeep = <String>{};
    
    // Keep players for ±2 from current
    for (int i = currentIndex - 2; i <= currentIndex + 2; i++) {
      if (i >= 0 && i < _videos.length) {
        keysToKeep.add(_videos[i].id);
      }
    }
    
    // Dispose others (simplified — PlayerCache handles eviction internally)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _videos.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _videos.length + (_hasMore ? 1 : 0),
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                if (index == _videos.length) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                
                return VideoCard(
                  video: _videos[index],
                  isVisible: index == _currentIndex,
                  playerCache: _playerCache,
                  onNext: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  onPrevious: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _playerCache.disposeAll();
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
