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
  final MovieCard movie;
  final int index;
  const FeedCard({super.key, required this.movie, required this.index});

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> with AutomaticKeepAliveClientMixin {
  VideoController? _vc;
  bool _showPause = false;
  bool _liked = false;
  bool _saved = false;
  bool _navigating = false; // prevent double taps

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

  void _onLongPress() {
    HapticFeedback.mediumImpact();
    _showInfoSheet();
  }

  void _showInfoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MovieInfoSheet(movie: widget.movie, onWatch: _goToPlayer),
    );
  }

  Future<void> _goToPlayer() async {
    if (_navigating) return;
    _navigating = true;
    HapticFeedback.mediumImpact();

    // Pause the trailer
    final fc = context.read<FeedController>();
    fc.togglePlay(widget.index);
    final settings = context.read<SettingsController>();

    try {
      // Use prefetched cache — should be instant
      final detail = await fc.getDetail(widget.movie.slug);
      if (!mounted) { _navigating = false; return; }

      await Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, __, ___) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => PlayerController(
                movie: detail.movie, episodes: detail.episodes)),
              ChangeNotifierProvider.value(value: settings),
            ],
            child: const PlayerScreen(),
          ),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween(begin: 0.94, end: 1.0).animate(
                  CurvedAnimation(parent: anim, curve: RCurve.spring)),
              child: child,
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not load movie', style: RText.body(size: 13)),
          backgroundColor: RColors.bgRaised,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      _navigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GestureDetector(
      onTap: _onTap,
      onLongPress: _onLongPress,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            if (widget.movie.hasThumbnail)
              CachedNetworkImage(
                imageUrl: widget.movie.thumbnailUrl!,
                fit: BoxFit.cover,
                fadeInDuration: RDur.md,
                placeholder: (_, __) => Container(color: RColors.bgCard),
                errorWidget: (_, __, ___) => Container(color: RColors.bgCard),
              )
            else
              Container(color: RColors.bgCard),

            // Trailer overlay
            if (_vc != null && widget.movie.hasTrailer)
              Video(controller: _vc!, controls: NoVideoControls, fit: BoxFit.cover),

            // Bottom gradient
            const Positioned(
              bottom: 0, left: 0, right: 0, height: 420,
              child: DecoratedBox(decoration: BoxDecoration(gradient: RColors.overlayBottom)),
            ),

            // Top gradient
            const Positioned(
              top: 0, left: 0, right: 0, height: 100,
              child: DecoratedBox(decoration: BoxDecoration(gradient: RColors.overlayTop)),
            ),

            // Play/Pause flash
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
                          fc.isPlaying(widget.index) ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          color: RColors.text, size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate()
                  .scale(begin: const Offset(0.6, 0.6), duration: RDur.sm, curve: RCurve.spring)
                  .fadeIn(duration: RDur.xs)
                  .then(delay: 400.ms)
                  .fadeOut(duration: RDur.md),

            // Right side actions
            Positioned(
              right: 12, bottom: 110,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionBtn(
                    icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    label: 'Like',
                    color: _liked ? RColors.like : RColors.text,
                    glow: _liked ? RColors.like : null,
                    onTap: () { HapticFeedback.lightImpact(); setState(() => _liked = !_liked); },
                  ),
                  const SizedBox(height: 22),
                  _ActionBtn(
                    icon: Icons.comment_outlined,
                    label: 'Comments',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showCommentsSheet(context);
                    },
                  ),
                  const SizedBox(height: 22),
                  _ActionBtn(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _shareNative(context);
                    },
                  ),
                  const SizedBox(height: 22),
                  _ActionBtn(
                    icon: _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    label: 'Save',
                    color: _saved ? RColors.brand : RColors.text,
                    glow: _saved ? RColors.brand : null,
                    onTap: () { HapticFeedback.lightImpact(); setState(() => _saved = !_saved); },
                  ),
                ],
              ).animate()
                  .fadeIn(delay: 150.ms, duration: RDur.lg)
                  .slideX(begin: 0.5, end: 0, delay: 150.ms, duration: RDur.lg, curve: RCurve.spring),
            ),

            // Bottom info
            Positioned(
              left: 16, right: 76, bottom: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.movie.title,
                    style: RText.body(size: 15, weight: FontWeight.w700),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _goToPlayer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [RColors.brand, RColors.brand2]),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: RColors.brand.withOpacity(0.5), blurRadius: 20, spreadRadius: 1),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text('Watch Episode 1', style: RText.body(size: 13, weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                      .boxShadow(
                        duration: 1600.ms,
                        begin: const BoxShadow(color: Color(0x660090FF), blurRadius: 20, spreadRadius: 1),
                        end: const BoxShadow(color: Color(0xAA0090FF), blurRadius: 32, spreadRadius: 4),
                      ),
                ],
              ).animate()
                  .fadeIn(delay: 80.ms, duration: RDur.lg)
                  .slideY(begin: 0.2, end: 0, delay: 80.ms, duration: RDur.lg, curve: RCurve.spring),
            ),
          ],
        ),
      ),
    );
  }
}

void _showCommentsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _CommentsSheet(),
  );
}

void _shareNative(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ShareSheet(),
  );
}

// ── Comments Sheet — Coming Soon ───────────────────────────────────────────────

class _CommentsSheet extends StatelessWidget {
  const _CommentsSheet();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: RColors.bgCard.withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: RColors.glassBorderMd, width: 0.8)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 14),
                  width: 38, height: 4,
                  decoration: BoxDecoration(color: RColors.glassMd, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text('Comments', style: RText.body(size: 16, weight: FontWeight.w700)),
                  ],
                ),
              ),
              const Expanded(
                child: Center(
                  child: _ComingSoonWidget(
                    icon: Icons.comment_outlined,
                    title: 'Comments',
                    subtitle: 'Be the first to comment when\nwe launch this feature 🚀',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 0.3, end: 0, duration: RDur.md, curve: RCurve.spring).fadeIn(duration: RDur.sm);
  }
}

// ── Share Sheet ────────────────────────────────────────────────────────────────

class _ShareSheet extends StatelessWidget {
  const _ShareSheet();

  @override
  Widget build(BuildContext context) {
    final options = [
      (Icons.link_rounded, 'Copy Link'),
      (Icons.message_rounded, 'Messages'),
      (Icons.telegram, 'Telegram'),
      (Icons.public_rounded, 'WhatsApp'),
      (Icons.more_horiz_rounded, 'More'),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: RColors.bgCard.withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: RColors.glassBorderMd, width: 0.8)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  width: 38, height: 4,
                  decoration: BoxDecoration(color: RColors.glassMd, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Share', style: RText.body(size: 16, weight: FontWeight.w700)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: options.map((o) => GestureDetector(
                  onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 54, height: 54,
                        decoration: BoxDecoration(
                          color: RColors.bgRaised,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: RColors.glassBorder),
                        ),
                        child: Icon(o.$1, color: RColors.text, size: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(o.$2, style: RText.label(size: 10)),
                    ],
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 0.3, end: 0, duration: RDur.md, curve: RCurve.spring).fadeIn(duration: RDur.sm);
  }
}

// ── Movie Info Sheet (long press) ──────────────────────────────────────────────

class _MovieInfoSheet extends StatelessWidget {
  final MovieCard movie;
  final VoidCallback onWatch;
  const _MovieInfoSheet({required this.movie, required this.onWatch});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: RColors.bgCard.withOpacity(0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: RColors.glassBorderMd, width: 0.8)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 38, height: 4,
                  decoration: BoxDecoration(color: RColors.glassMd, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (movie.hasThumbnail)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 90, height: 120,
                          child: CachedNetworkImage(
                            imageUrl: movie.thumbnailUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: RColors.bgRaised),
                          ),
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(movie.title,
                            style: RText.body(size: 16, weight: FontWeight.w700), maxLines: 3),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: RColors.brand.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: RColors.brand.withOpacity(0.3)),
                            ),
                            child: Text('Series', style: RText.label(color: RColors.brand)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onWatch();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [RColors.brand, RColors.brand2]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: RColors.brand.withOpacity(0.4), blurRadius: 20)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text('Watch Now', style: RText.body(size: 15, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 0.3, end: 0, duration: RDur.md, curve: RCurve.spring).fadeIn(duration: RDur.sm);
  }
}

// ── Coming Soon Widget ─────────────────────────────────────────────────────────

class _ComingSoonWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ComingSoonWidget({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: RColors.brand.withOpacity(0.3)),
          ),
          child: Icon(icon, color: RColors.brand, size: 32),
        ),
        const SizedBox(height: 16),
        Text(title, style: RText.body(size: 16, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(subtitle,
          style: RText.body(size: 13, color: RColors.text3),
          textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: RColors.brand.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RColors.brand.withOpacity(0.3)),
          ),
          child: Text('Coming Soon 🚀', style: RText.body(size: 12, weight: FontWeight.w700, color: RColors.brand)),
        ),
      ],
    );
  }
}

// ── Action button ──────────────────────────────────────────────────────────────

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? glow;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon, required this.label,
    this.color = RColors.text, this.glow, this.onTap,
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
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap?.call(); },
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
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.glow != null ? widget.glow!.withOpacity(0.18) : RColors.glass,
                    border: Border.all(
                      color: widget.glow != null ? widget.glow!.withOpacity(0.4) : RColors.glassBorder,
                    ),
                    boxShadow: widget.glow != null ? [
                      BoxShadow(color: widget.glow!.withOpacity(0.4), blurRadius: 18, spreadRadius: 2),
                    ] : null,
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

// ── CachedNetworkImage import helper (already imported above) ──────────────────
