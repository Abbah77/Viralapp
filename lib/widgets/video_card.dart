import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../models/video_model.dart';
import '../controllers/feed_controller.dart';

class VideoCard extends StatefulWidget {
  final VideoModel video;
  final int index;
  final FeedController controller;

  const VideoCard({
    super.key,
    required this.video,
    required this.index,
    required this.controller,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  VideoController? _videoController;
  bool _showPlayIcon = false;

  @override
  void initState() {
    super.initState();
    _setupController();
  }

  void _setupController() {
    final player = widget.controller.getPlayer(widget.index);
    if (player != null) {
      _videoController = VideoController(player);
    }
  }

  @override
  void didUpdateWidget(VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_videoController == null) {
      final player = widget.controller.getPlayer(widget.index);
      if (player != null) {
        setState(() {
          _videoController = VideoController(player);
        });
      }
    }
  }

  void _onTap() {
    widget.controller.togglePlayPause(widget.index);
    setState(() => _showPlayIcon = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showPlayIcon = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: _onTap,
      child: Container(
        width: size.width,
        height: size.height,
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail background (shows while video loads)
            CachedNetworkImage(
              imageUrl: widget.video.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: const Color(0xFF111111)),
              errorWidget: (context, url, error) => Container(color: const Color(0xFF111111)),
            ),

            // Video player
            if (_videoController != null)
              Video(
                controller: _videoController!,
                controls: NoVideoControls,
                fit: BoxFit.cover,
              ),

            // Gradient overlay bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: size.height * 0.55,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xEE000000),
                      Color(0x88000000),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Top gradient (status bar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x88000000), Colors.transparent],
                  ),
                ),
              ),
            ),

            // Play/Pause icon overlay
            if (_showPlayIcon)
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.controller.isPlaying(widget.index)
                        ? Iconsax.pause
                        : Iconsax.play,
                    color: Colors.white,
                    size: 32,
                  ),
                ).animate().scale(
                  duration: 200.ms,
                  curve: Curves.easeOut,
                ).then().scale(
                  begin: const Offset(1, 1),
                  end: const Offset(0, 0),
                  delay: 400.ms,
                  duration: 200.ms,
                ),
              ),

            // Bottom info
            Positioned(
              bottom: 90,
              left: 16,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Caption
                  if (widget.video.caption.isNotEmpty)
                    Text(
                      widget.video.caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 8),
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 8),

                  // Hashtags
                  if (widget.video.hashtags.isNotEmpty)
                    Text(
                      widget.video.hashtags,
                      style: const TextStyle(
                        color: Color(0xFF25F4EE),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 8),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                ],
              ),
            ),

            // Right side actions
            Positioned(
              right: 12,
              bottom: 100,
              child: Column(
                children: [
                  _ActionButton(
                    icon: Iconsax.heart5,
                    label: 'Like',
                    color: const Color(0xFFFE2C55),
                  ),
                  const SizedBox(height: 20),
                  _ActionButton(
                    icon: Iconsax.message,
                    label: 'Comment',
                  ),
                  const SizedBox(height: 20),
                  _ActionButton(
                    icon: Iconsax.send_2,
                    label: 'Share',
                  ),
                  const SizedBox(height: 20),
                  _ActionButton(
                    icon: Iconsax.more_circle,
                    label: 'More',
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms)
                .slideX(begin: 0.3, end: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _pressed = !_pressed);
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Icon(
              widget.icon,
              color: _pressed
                  ? (widget.color ?? Colors.white)
                  : Colors.white,
              size: 22,
            ),
          ).animate(target: _pressed ? 1 : 0)
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.2, 1.2),
              duration: 150.ms,
              curve: Curves.easeOut,
            ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
