import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../controllers/feed_controller.dart';
import '../controllers/player_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/tokens.dart';
import 'player_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _ctrl = TextEditingController();
  List<MovieCard> _results = [];
  bool _searching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _results = []; _hasSearched = false; _searching = false; });
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await ApiService.search(query);
      setState(() { _results = results; _hasSearched = true; });
    } catch (_) {
      // fallback to local feed search
      final fc = context.read<FeedController>();
      final q = query.toLowerCase();
      setState(() {
        _results = fc.movies.where((m) => m.title.toLowerCase().contains(q)).toList();
        _hasSearched = true;
      });
    }
    setState(() => _searching = false);
  }

  Future<void> _openPlayer(MovieCard movie) async {
    HapticFeedback.lightImpact();
    final settings = context.read<SettingsController>();
    try {
      final detail = await ApiService.getMovie(movie.slug);
      if (!mounted) return;
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 420),
          pageBuilder: (_, __, ___) => MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => PlayerController(
                  movie: detail.movie,
                  episodes: detail.episodes,
                ),
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load movie', style: RText.body(size: 13)),
            backgroundColor: RColors.bgRaised,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: RColors.glassMd,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: RColors.glassBorder),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      style: RText.body(size: 14),
                      textInputAction: TextInputAction.search,
                      onChanged: _search,
                      onSubmitted: _search,
                      decoration: InputDecoration(
                        hintText: 'Search movies...',
                        hintStyle: RText.body(size: 14, color: RColors.text3),
                        prefixIcon: const Icon(Icons.search_rounded, color: RColors.text3, size: 20),
                        suffixIcon: _ctrl.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () { _ctrl.clear(); _search(''); },
                                child: const Icon(Icons.close_rounded, color: RColors.text3, size: 18),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: _searching
                  ? const Center(child: CircularProgressIndicator(color: RColors.brand, strokeWidth: 2.5))
                  : _hasSearched && _results.isEmpty
                      ? _EmptySearch()
                      : _hasSearched
                          ? _Grid(movies: _results, onTap: _openPlayer)
                          : _Trending(onTap: _openPlayer),
            ),
          ],
        ),
      ),
    );
  }
}

class _Trending extends StatelessWidget {
  final Function(MovieCard) onTap;
  const _Trending({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final movies = context.watch<FeedController>().movies;
    if (movies.isEmpty) {
      return Center(
        child: Text('Browse movies here', style: RText.body(size: 13, color: RColors.text3)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text('Trending', style: RText.body(size: 16, weight: FontWeight.w700)),
        ),
        Expanded(child: _Grid(movies: movies, onTap: onTap)),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  final List<MovieCard> movies;
  final Function(MovieCard) onTap;
  const _Grid({required this.movies, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: movies.length,
      itemBuilder: (_, i) => _Poster(movie: movies[i], index: i, onTap: () => onTap(movies[i])),
    );
  }
}

class _Poster extends StatefulWidget {
  final MovieCard movie;
  final int index;
  final VoidCallback onTap;
  const _Poster({required this.movie, required this.index, required this.onTap});

  @override
  State<_Poster> createState() => _PosterState();
}

class _PosterState extends State<_Poster> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPressStart: (_) { HapticFeedback.mediumImpact(); setState(() => _pressed = true); },
      onLongPressEnd: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: RDur.sm, curve: RCurve.spring,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.movie.hasThumbnail
                  ? CachedNetworkImage(
                      imageUrl: widget.movie.thumbnailUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: RColors.bgCard),
                      errorWidget: (_, __, ___) => Container(color: RColors.bgCard),
                    )
                  : Container(color: RColors.bgCard),

              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Color(0xEE050508), Colors.transparent],
                    stops: [0.0, 0.55],
                  ),
                ),
              ),

              Positioned(
                bottom: 10, left: 10, right: 10,
                child: Text(
                  widget.movie.title,
                  style: RText.body(size: 12, weight: FontWeight.w600),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ),

              if (_pressed)
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 52),
                  ),
                ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: widget.index * 35), duration: RDur.md)
          .slideY(begin: 0.08, end: 0,
              delay: Duration(milliseconds: widget.index * 35),
              duration: RDur.lg, curve: RCurve.spring),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: RColors.bgRaised,
              border: Border.all(color: RColors.glassBorder),
            ),
            child: const Icon(Icons.search_off_rounded, color: RColors.text3, size: 30),
          ),
          const SizedBox(height: 16),
          Text('No results found',
              style: RText.body(size: 15, weight: FontWeight.w600, color: RColors.text2)),
          const SizedBox(height: 6),
          Text('Try a different title', style: RText.body(size: 13, color: RColors.text3)),
        ],
      ),
    );
  }
}
