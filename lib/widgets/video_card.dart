import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/video.dart';
import '../services/player_cache.dart';

class VideoCard extends StatefulWidget {
  final Video video;
  final bool isVisible;
  final PlayerCache playerCache;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const VideoCard({
    super.key,
    required this.video,
    required this.isVisible,
    required this.playerCache,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  VideoController? _controller;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final player = await widget.playerCache.createPlayer(widget.video);
    if (mounted) {
      setState(() {
        _controller = widget.playerCache.getController(widget.video.id);
        _isVideoReady = true;
      });
    }
  }

  @override
  void didUpdateWidget(VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller?.player.play();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller?.player.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail ALWAYS visible first — this is the key to perceived speed
        CachedNetworkImage(
          imageUrl: widget.video.thumbnailUrl,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (_, __) => Container(color: Colors.black),
          errorWidget: (_, __, ___) => Container(color: Colors.grey[900]),
        ),
        
        // Video layer on top once ready
        if (_isVideoReady && _controller != null)
          Video(
            controller: _controller!,
            fit: BoxFit.contain,
            controls: NoVideoControls(),
          ),
        
        // UI Overlay
        _buildOverlay(),
      ],
    );
  }

  Widget _buildOverlay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@user',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.video.caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.video.hashtags,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _buildActionButton(Icons.favorite_border, '0'),
                  const SizedBox(height: 16),
                  _buildActionButton(Icons.comment, '0'),
                  const SizedBox(height: 16),
                  _buildActionButton(Icons.share, 'Share'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // DO NOT dispose player here — PlayerCache manages lifecycle
    super.dispose();
  }
}

class NoVideoControls extends StatelessWidget {
  const NoVideoControls({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
