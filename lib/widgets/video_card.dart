import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/video_model.dart';
import '../controllers/feed_controller.dart';
import '../theme/tokens.dart';
import 'action_button.dart';

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

class _VideoCardState extends State<VideoCard>
    with AutomaticKeepAliveClientMixin {
  VideoController? _videoController;
  bool _showPlayIcon = false;
  bool _captionExpanded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tryBindController();
  }

  void _tryBindController() {
    final player = widget.controller.getPlayer(widget.index);
    if (player != null && _videoController == null) {
      _videoController = VideoController(player);
    }
  }

  @override
  void didUpdateWidget(VideoCard old) {
    super.didUpdateWidget(old);
    if (_videoController == null) {
      _tryBindController();
      if (_videoController != null && mounted) setState(() {});
    }
  }

  void _onTap() {
    HapticFeedback.selectionClick();
    widget.controller.togglePlayPause(widget.index);
    setState(() => _showPlayIcon = true);
    Future.delayed(900.ms, () {
      if (mounted) setState(() => _showPlayIcon = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: _onTap,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Thumbnail background ─────────────────────────────
            CachedNetworkImage(
              imageUrl: widget.video.thumbnailUrl,
              fit: BoxFit.cover,
              fadeInDuration: ReelzDurations.md,
              placeholder: (_, __) => Container(color: ReelzColors.bgCard),
              errorWidget: (_, __, ___) =>
                  Container(color: ReelzColors.bgCard),
            ),

            // ── Video player ─────────────────────────────────────
            if (_videoController != null)
              Video(
                controller: _videoController!,
                controls: NoVideoControls,
                fit: BoxFit.cover,
              ),

            // ── Bottom gradient ──────────────────────────────────
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 420,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: ReelzColors.overlayBottom,
                ),
              ),
            ),

            // ── Top gradient ─────────────────────────────────────
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 130,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: ReelzColors.overlayTop,
                ),
              ),
            ),

            // ── Play/Pause indicator ─────────────────────────────
            if (_showPlayIcon)
              Center(
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ReelzColors.glass,
                        border: Border.all(
                          color: ReelzColors.glassBorderMd,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: widget.controller.isPlaying(widget.index)
                            ? ReelzIcons.play()
                            : ReelzIcons.pause(),
                      ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1.0, 1.0),
                    duration: ReelzDurations.sm,
                    curve: ReelzCurves.spring,
                  )
                  .fadeIn(duration: ReelzDurations.xs)
                  .then(delay: 500.ms)
                  .fadeOut(duration: ReelzDurations.md),

            // ── Right side actions ───────────────────────────────
            Positioned(
              right: 12,
              bottom: 100,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActionButton(
                    isLike: true,
                    icon: ReelzIcons.heart(),
                    activeIcon:
                        ReelzIcons.heart(filled: true, color: ReelzColors.like),
                    label: 'Like',
                  ),
                  const SizedBox(height: 18),
                  ActionButton(
                    icon: ReelzIcons.comment(),
                    label: 'Comment',
                  ),
                  const SizedBox(height: 18),
                  ActionButton(
                    icon: ReelzIcons.share(),
                    label: 'Share',
                  ),
                  const SizedBox(height: 18),
                  ActionButton(
                    icon: ReelzIcons.bookmark(),
                    activeIcon: ReelzIcons.bookmark(
                        filled: true, color: ReelzColors.brand),
                    label: 'Save',
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: ReelzDurations.lg)
                  .slideX(
                    begin: 0.4,
                    end: 0,
                    delay: 200.ms,
                    duration: ReelzDurations.lg,
                    curve: ReelzCurves.spring,
                  ),
            ),

            // ── Bottom info ──────────────────────────────────────
            Positioned(
              left: 16,
              right: 80,
              bottom: 88,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Caption
                  if (widget.video.caption.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(
                          () => _captionExpanded = !_captionExpanded),
                      child: AnimatedSize(
                        duration: ReelzDurations.md,
                        curve: ReelzCurves.easeOut,
                        child: Text(
                          widget.video.caption,
                          style: ReelzTextStyles.caption,
                          maxLines: _captionExpanded ? 6 : 2,
                          overflow: _captionExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Hashtags
                  if (widget.video.hashtags.isNotEmpty)
                    Text(
                      widget.video.hashtags,
                      style: ReelzTextStyles.hashtag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: ReelzDurations.lg)
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    delay: 100.ms,
                    duration: ReelzDurations.lg,
                    curve: ReelzCurves.spring,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
