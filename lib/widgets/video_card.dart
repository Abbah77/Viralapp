import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit_video/media_kit_video.dart' as mk;  // ← PREFIXED
import '../models/video.dart' as models;
import '../services/player_cache.dart';
import '../screens/single_video.dart';

class VideoCard extends StatefulWidget {
  final models.Video video;
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
  mk.VideoController? _controller;
  bool _isVideoReady = false;
  bool _isLiked = false;

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
      if (widget.isVisible) {
        player.play();
      }
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

  void _openFullscreen() {
    _controller?.player.pause();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SingleVideoScreen(
          video: widget.video,
          playerCache: widget.playerCache,
        ),
      ),
    ).then((_) {
      if (widget.isVisible) {
        _controller?.player.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _openFullscreen,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: widget.video.thumbnailUrl,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (_, __) => Container(color: Colors.black),
            errorWidget: (_, __, ___) => Container(color: Colors.grey[900]),
          ),
          
          if (_isVideoReady && _controller != null)
            mk.Video(  // ← USE PREFIX
              controller: _controller!,
              fit: BoxFit.contain,
            ),
          
          _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '@viral_user',
                      style: TextStyle(
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
                    if (widget.video.hashtags.isNotEmpty)
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
                  _buildActionButton(
                    icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                    label: '0',
                    onTap: () => setState(() => _isLiked = !_isLiked),
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    icon: Icons.comment,
                    label: '0',
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    icon: Icons.fullscreen,
                    label: '',
                    onTap: _openFullscreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          if (label.isNotEmpty) ...[
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
