import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../controllers/feed_controller.dart';
import '../controllers/player_controller.dart';
import '../controllers/settings_controller.dart';
import '../theme/tokens.dart';
import '../screens/player_screen.dart';

class FeedCard extends StatefulWidget {
  final VideoModel video;
  final int index;

  const FeedCard({super.key, required this.video, required this.index});

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard>
    with AutomaticKeepAliveClientMixin {
  VideoController? _vc;
  bool _showPause = false;
  bool _liked = false;
  bool _saved = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    final fc = context.read<FeedController>();
    final p = fc.getPlayer(widget.index);
    if (p != null && _vc == null) {
      _vc = VideoController(p);
    }
  }

  @override
  void didUpdateWidget(FeedCard old) {
    super.didUpdateWidget(old);
    if (_vc == null) {
      _bind();
      if (_vc != null && mounted) setState(() {});
    }
  }

  void _onTap() {
    HapticFeedback.selectionClick();
    context.read<FeedController>().togglePlay(widget.index);
    setState(() => _showPause = true);
    Future.delayed(800.ms, () {
      if (mounted) setState(() => _showPause = false);
    });
  }

  void _goToPlayer() {
    HapticFeedback.mediumImpact();
    final movie = MovieModel.fromVideo(widget.video);
    final settings = context.read<SettingsController>();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 480),
        pageBuilder: (_, __, ___) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => PlayerController(movie: movie),
            ),
            ChangeNotifierProvider.value(value: settings),
          ],
          child: const PlayerScreen(),
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: RCurve.spring),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: _onTap,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Thumbnail ─────────────────────────────────────
            CachedNetworkImage(
              imageUrl: widget.video.thumbnailUrl,
              fit: BoxFit.cover,
              fadeInDuration: RDur.md,
              placeholder: (_, __) => Container(color: RColors.bgCard),
              errorWidget: (_, __, ___) => Container(color: RColors.bgCard),
            ),

            // ── Video ─────────────────────────────────────────
            if (_vc != null)
              Hero(
                tag: 'video_${widget.video.id}',
                child: Video(
                  controller: _vc!,
                  controls: NoVideoControls,
                  fit: BoxFit.cover,
                ),
              ),

            // ── Gradients ─────────────────────────────────────
            const Positioned(
              bottom: 0, left: 0, right: 0, height: 420,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: RColors.overlayBottom),
              ),
            ),
            const Positioned(
              top: 0, left: 0, right: 0, height: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: RColors.overlayTop),
              ),
            ),

            // ── Play/Pause Flash ───────────────────────────────
            if (_showPause)
              Center(
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: RColors.glass,
                        border: Border.all(color: RColors.glassBorderMd),
                      ),
                      child: Consumer<FeedController>(
                        builder: (_, fc, __) => Icon(
                          fc.isPlaying(widget.index)
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          color: RColors.text,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    duration: RDur.sm,
                    curve: RCurve.spring,
                  )
                  .fadeIn(duration: RDur.xs)
                  .then(delay: 400.ms)
                  .fadeOut(duration: RDur.md),

            // ── Right Actions — fixed position ─────────────────
            // bottom: 110 aligns with bottom info block
            Positioned(
              right: 12,
              bottom: 110,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionBtn(
                    icon: _liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: 'Like',
                    color: _liked ? RColors.like : RColors.text,
                    glow: _liked ? RColors.like : null,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _liked = !_liked);
                    },
                  ),
                  const SizedBox(height: 22),
                  _ActionBtn(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: () => HapticFeedback.lightImpact(),
                  ),
                  const SizedBox(height: 22),
                  _ActionBtn(
                    icon: _saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    label: 'Save',
                    color: _saved ? RColors.brand : RColors.text,
                    glow: _saved ? RColors.brand : null,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _saved = !_saved);
                    },
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 150.ms, duration: RDur.lg)
                  .slideX(
                    begin: 0.5, end: 0,
                    delay: 150.ms,
                    duration: RDur.lg,
                    curve: RCurve.spring,
                  ),
            ),

            // ── Bottom Info — title + watch btn ────────────────
            Positioned(
              left: 16,
              right: 76,
              bottom: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title only — no hashtags
                  Text(
                    widget.video.caption,
                    style: RText.body(size: 15, weight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

                  // Watch Episode 1 button
                  GestureDetector(
                    onTap: _goToPlayer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [RColors.brand, RColors.brand2],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: RColors.brand.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Watch Episode 1',
                            style: RText.body(
                                size: 13, weight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .boxShadow(
                        duration: 1600.ms,
                        begin: const BoxShadow(
                          color: Color(0x660090FF),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                        end: const BoxShadow(
                          color: Color(0xAA0090FF),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: RDur.lg)
                  .slideY(
                    begin: 0.2, end: 0,
                    delay: 80.ms,
                    duration: RDur.lg,
                    curve: RCurve.spring,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? glow;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    this.color = RColors.text,
    this.glow,
    this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.84 : 1.0,
        duration: RDur.xs,
        curve: RCurve.spring,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: RDur.md,
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.glow != null
                        ? widget.glow!.withOpacity(0.18)
                        : RColors.glass,
                    border: Border.all(
                      color: widget.glow != null
                          ? widget.glow!.withOpacity(0.4)
                          : RColors.glassBorder,
                    ),
                    boxShadow: widget.glow != null
                        ? [
                            BoxShadow(
                              color: widget.glow!.withOpacity(0.4),
                              blurRadius: 18,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(widget.label, style: RText.label()),
          ],
        ),
      ),
    );
  }
}
