import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart' as mk;  // ← PREFIXED
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video.dart' as models;
import '../services/player_cache.dart';

class SingleVideoScreen extends StatefulWidget {
  final models.Video video;
  final PlayerCache playerCache;

  const SingleVideoScreen({
    super.key,
    required this.video,
    required this.playerCache,
  });

  @override
  State<SingleVideoScreen> createState() => _SingleVideoScreenState();
}

class _SingleVideoScreenState extends State<SingleVideoScreen> {
  mk.VideoController? _controller;
  bool _isReady = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _setupPlayer();
  }

  Future<void> _setupPlayer() async {
    final player = widget.playerCache.getPlayer(widget.video.id) ??
        await widget.playerCache.createPlayer(widget.video);
    
    setState(() {
      _controller = widget.playerCache.getController(widget.video.id);
      _isReady = true;
    });
    
    player.play();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!_isReady)
              CachedNetworkImage(
                imageUrl: widget.video.thumbnailUrl,
                fit: BoxFit.contain,
              ),
            if (_isReady && _controller != null)
              mk.Video(  // ← USE PREFIX
                controller: _controller!,
                fit: BoxFit.contain,
              ),
            if (_showControls)
              _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(16.0),
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.video.caption,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    if (widget.video.hashtags.isNotEmpty)
                      Text(
                        widget.video.hashtags,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border, color: Colors.white, size: 30),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.comment, color: Colors.white, size: 30),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white, size: 30),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
