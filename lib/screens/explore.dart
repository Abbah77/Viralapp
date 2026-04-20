import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video.dart';
import '../services/api_service.dart';
import '../services/player_cache.dart';
import 'single_video.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ApiService _api = ApiService();
  final PlayerCache _playerCache = PlayerCache();
  final ScrollController _scrollController = ScrollController();
  
  List<Video> _videos = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchVideos() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() => _isLoading = true);
    
    try {
      final videos = await _api.searchVideos(page: _currentPage);
      setState(() {
        _videos.addAll(videos);
        _currentPage++;
        _hasMore = videos.isNotEmpty;
      });
    } catch (e) {
      debugPrint('Explore error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchVideos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Explore', style: TextStyle(color: Colors.white)),
      ),
      body: _videos.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: _videos.length + (_hasMore ? 3 : 0),
              itemBuilder: (context, index) {
                if (index >= _videos.length) {
                  return Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }
                
                final video = _videos[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SingleVideoScreen(
                        video: video,
                        playerCache: _playerCache,
                      ),
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[900]),
                    errorWidget: (_, __, ___) => Container(color: Colors.grey[900]),
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _playerCache.disposeAll();
    super.dispose();
  }
}
