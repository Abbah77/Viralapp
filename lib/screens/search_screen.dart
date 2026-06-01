import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../controllers/player_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/tokens.dart';
import '../ads/ad_engine.dart';
import '../widgets/dot_loader.dart';
import 'player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  List<MovieCard> _results = [];
  bool _loading = false;
  bool _hasSearched = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _results = []; _hasSearched = false; _loading = false; });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    if (q == _lastQuery && _hasSearched) return;
    _lastQuery = q;
    try {
      final res = await ApiService.search(q);
      if (mounted) setState(() { _results = res; _loading = false; _hasSearched = true; });
    } catch (_) {
      if (mounted) setState(() { _results = []; _loading = false; _hasSearched = true; });
    }
  }

  Future<void> _openPlayer(MovieCard movie) async {
    HapticFeedback.mediumImpact();
    final settings = context.read<SettingsController>();
    try {
      final detail = await ApiService.getMovie(movie.slug);
      if (!mounted) return;
      Navigator.of(context).push(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => PlayerController(
              movie: detail.movie, episodes: detail.episodes,
                  adEngine: context.read<AdEngine>())),
            ChangeNotifierProvider.value(value: settings),
          ],
          child: const PlayerScreen(),
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: RCurve.spring)),
            child: child,
          ),
        ),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not load movie', style: RText.body(size: 13)),
          backgroundColor: RColors.bgRaised,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () { HapticFeedback.lightImpact(); Navigator.of(context).pop(); },
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: RColors.bgRaised,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: RColors.glassBorder),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: RColors.text, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: RColors.bgRaised,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: RColors.glassBorderMd),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Icon(Icons.search_rounded, color: RColors.text3, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _ctrl,
                                  focusNode: _focus,
                                  onChanged: _onChanged,
                                  style: RText.body(size: 14),
                                  cursorColor: RColors.brand,
                                  decoration: InputDecoration(
                                    hintText: 'Search movies & series…',
                                    hintStyle: RText.body(size: 14, color: RColors.text3),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (_ctrl.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _ctrl.clear();
                                    _onChanged('');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: const Icon(Icons.cancel_rounded, color: RColors.text3, size: 18),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: RDur.md).slideY(begin: -0.2, end: 0, curve: RCurve.spring),

            const SizedBox(height: 16),

            // Results
            Expanded(
              child: _loading
                  ? const Center(child: SamsungLoader(size: 34))
                  : !_hasSearched
                      ? _EmptyHint()
                      : _results.isEmpty
                          ? _NoResults(query: _lastQuery)
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _results.length,
                              itemBuilder: (_, i) => _ResultCard(
                                movie: _results[i],
                                onTap: () => _openPlayer(_results[i]),
                              ).animate()
                                  .fadeIn(delay: Duration(milliseconds: i * 40), duration: RDur.md)
                                  .slideY(begin: 0.15, end: 0, curve: RCurve.spring),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.movie_filter_outlined, color: RColors.text3, size: 48),
          const SizedBox(height: 16),
          Text('Search for movies & series', style: RText.body(size: 15, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Type to find what you want to watch', style: RText.body(size: 13, color: RColors.text3)),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, color: RColors.text3, size: 48),
          const SizedBox(height: 16),
          Text('No results for "$query"', style: RText.body(size: 15, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Try a different title', style: RText.body(size: 13, color: RColors.text3)),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final MovieCard movie;
  final VoidCallback onTap;
  const _ResultCard({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: RColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RColors.glassBorder),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              child: SizedBox(
                width: 80, height: 110,
                child: movie.hasThumbnail
                    ? CachedNetworkImage(
                        imageUrl: movie.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: RColors.bgRaised),
                        errorWidget: (_, __, ___) => Container(
                          color: RColors.bgRaised,
                          child: const Icon(Icons.movie_rounded, color: RColors.text3, size: 28),
                        ),
                      )
                    : Container(
                        color: RColors.bgRaised,
                        child: const Icon(Icons.movie_rounded, color: RColors.text3, size: 28),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(movie.title,
                    style: RText.body(size: 14, weight: FontWeight.w700),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [RColors.brand, RColors.brand2]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text('Watch', style: RText.body(size: 12, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}
