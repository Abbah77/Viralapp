import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../controllers/feed_controller.dart';
import '../controllers/player_controller.dart';
import '../models/models.dart';
import '../theme/tokens.dart';
import '../screens/player_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchCtrl = TextEditingController();
  List<VideoModel> _results = [];
  bool _searching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() => _searching = true);

    // Search from feed videos locally
    try {
      final fc = context.read<FeedController>();
      final q = query.toLowerCase();
      final filtered = fc.videos
          .where((v) =>
              v.caption.toLowerCase().contains(q) ||
              v.hashtags.toLowerCase().contains(q))
          .toList();
      setState(() {
        _results = filtered;
        _hasSearched = true;
      });
    } catch (_) {
      setState(() => _results = []);
    }

    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: RColors.glass,
                          shape: BoxShape.circle,
                          border: Border.all(color: RColors.glassBorder),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: RColors.text, size: 18),
                      ),
                    ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: RColors.glassMd,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: RColors.glassBorder),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            autofocus: true,
                            style: RText.body(size: 14),
                            textInputAction: TextInputAction.search,
                            onChanged: _search,
                            onSubmitted: _search,
                            decoration: InputDecoration(
                              hintText: 'Search movies...',
                              hintStyle:
                                  RText.body(size: 14, color: RColors.text3),
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: RColors.text3, size: 20),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _searchCtrl.clear();
                                        _search('');
                                      },
                                      child: const Icon(Icons.close_rounded,
                                          color: RColors.text3, size: 18),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Results
            Expanded(
              child: _searching
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: RColors.brand, strokeWidth: 2),
                    )
                  : _hasSearched && _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_rounded,
                                  color: RColors.text3, size: 48),
                              const SizedBox(height: 12),
                              Text('No results found',
                                  style: RText.body(
                                      size: 15,
                                      weight: FontWeight.w600,
                                      color: RColors.text2)),
                            ],
                          ),
                        )
                      : _hasSearched
                          ? _ResultsGrid(videos: _results)
                          : _TrendingGrid(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fc = context.watch<FeedController>();
    final videos = fc.videos.take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Trending Now',
            style: RText.body(size: 16, weight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _ResultsGrid(videos: videos)),
      ],
    );
  }
}

class _ResultsGrid extends StatelessWidget {
  final List<VideoModel> videos;
  const _ResultsGrid({required this.videos});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: videos.length,
      itemBuilder: (_, i) => _MoviePoster(
        video: videos[i],
        index: i,
      ),
    );
  }
}

class _MoviePoster extends StatefulWidget {
  final VideoModel video;
  final int index;
  const _MoviePoster({required this.video, required this.index});

  @override
  State<_MoviePoster> createState() => _MoviePosterState();
}

class _MoviePosterState extends State<_MoviePoster> {
  bool _longPressed = false;

  void _onTap() {
    HapticFeedback.lightImpact();
    final movie = MovieModel.fromVideo(widget.video);
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => ChangeNotifierProvider(
          create: (_) => PlayerController(movie: movie),
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
    return GestureDetector(
      onTap: _onTap,
      onLongPressStart: (_) {
        HapticFeedback.mediumImpact();
        setState(() => _longPressed = true);
      },
      onLongPressEnd: (_) => setState(() => _longPressed = false),
      child: AnimatedScale(
        scale: _longPressed ? 0.93 : 1.0,
        duration: RDur.sm,
        curve: RCurve.spring,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: widget.video.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: RColors.bgCard),
                errorWidget: (_, __, ___) =>
                    Container(color: RColors.bgCard),
              ),
              // Gradient
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xEE050508), Colors.transparent],
                    stops: [0.0, 0.6],
                  ),
                ),
              ),
              // Title
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Text(
                  widget.video.caption,
                  style: RText.body(size: 12, weight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Long press preview indicator
              if (_longPressed)
                Container(
                  color: Colors.black38,
                  child: const Center(
                    child: Icon(Icons.play_circle_outline_rounded,
                        color: Colors.white, size: 48),
                  ),
                ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: widget.index * 40))
          .slideY(
            begin: 0.1,
            end: 0,
            delay: Duration(milliseconds: widget.index * 40),
            duration: RDur.lg,
            curve: RCurve.spring,
          ),
    );
  }
}
