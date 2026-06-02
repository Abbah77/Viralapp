import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../ads/ad_engine.dart';
import '../ads/native_grid_ad_card.dart';
import '../controllers/player_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/tokens.dart';
import '../widgets/dot_loader.dart';
import 'player_screen.dart';
import 'search_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _scroll = ScrollController();
  final List<MovieCard> _movies = [];
  int? _nextCursor;
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300 &&
        _hasMore && !_isFetchingMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final r = await ApiService.getFeed(limit: 20);
      if (mounted) setState(() { _movies.addAll(r.data); _nextCursor = r.nextCursor; _hasMore = r.hasMore; });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load content');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isFetchingMore || !_hasMore) return;
    setState(() => _isFetchingMore = true);
    try {
      final r = await ApiService.getFeed(cursor: _nextCursor, limit: 20);
      if (mounted) setState(() { _movies.addAll(r.data); _nextCursor = r.nextCursor; _hasMore = r.hasMore; });
    } catch (_) {}
    if (mounted) setState(() => _isFetchingMore = false);
  }

  Future<void> _openPlayer(MovieCard movie) async {
    HapticFeedback.mediumImpact();
    final settings = context.read<SettingsController>();
    try {
      final detail = await ApiService.getMovie(movie.slug);
      if (!mounted) return;
      Navigator.of(context).push(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
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
            scale: Tween(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: anim, curve: RCurve.spring)),
            child: child,
          ),
        ),
      ));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final adEngine = context.read<AdEngine>();

    return Scaffold(
      backgroundColor: RColors.bg,
      body: NestedScrollView(
        controller: _scroll,
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Row(children: [
                  Text('Explore', style: RText.wordmark(size: 22)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => MultiProvider(
                          providers: [
                            ChangeNotifierProvider.value(value: context.read<SettingsController>()),
                            ChangeNotifierProvider.value(value: adEngine),
                          ],
                          child: const SearchScreen(),
                        ),
                      ));
                    },
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: RColors.glass,
                            border: Border.all(color: RColors.glassBorder),
                          ),
                          child: const Icon(Icons.search_rounded, color: RColors.text, size: 20),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
        body: _isLoading
          ? const Center(child: SamsungLoader(size: 36))
          : _error != null
            ? _ErrorState(onRetry: _load, message: _error!)
            : _movies.isEmpty
              ? const Center(child: Text('No content', style: TextStyle(color: RColors.text3)))
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            adEngine.onGridRendered();
                            // Inject native ad at dynamic positions
                            if (adEngine.shouldShowGridAd(i)) {
                              final ad = adEngine.getNativeGridAd(i);
                              return NativeGridAdCard(ad: ad)
                                .animate()
                                .fadeIn(delay: Duration(milliseconds: (i % 9) * 30));
                            }
                            // Map index accounting for injected ads
                            final movieIdx = i - (i ~/ adEngine.shouldShowGridAd(i) ? 1 : 0);
                            final safeIdx = i.clamp(0, _movies.length - 1);
                            return _MovieTile(
                              movie: _movies[safeIdx],
                              onTap: () => _openPlayer(_movies[safeIdx]),
                            ).animate().fadeIn(
                              delay: Duration(milliseconds: (i % 9) * 35),
                              duration: RDur.md,
                            ).scale(begin: const Offset(0.92, 0.92), curve: RCurve.spring);
                          },
                          childCount: _movies.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.65,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _isFetchingMore
                        ? const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: SamsungLoader(size: 28)))
                        : const SizedBox(height: 120),
                    ),
                  ],
                ),
      ),
    );
  }
}

class _MovieTile extends StatelessWidget {
  final MovieCard movie;
  final VoidCallback onTap;
  const _MovieTile({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(fit: StackFit.expand, children: [
          if (movie.hasThumbnail)
            CachedNetworkImage(
              imageUrl: movie.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: RColors.bgCard),
              errorWidget: (_, __, ___) => Container(color: RColors.bgCard),
            )
          else
            Container(color: RColors.bgCard),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Color(0xCC07070B), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 6, left: 6, right: 6,
            child: Text(movie.title,
              style: RText.label(size: 10, color: RColors.text),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, color: RColors.text3, size: 44),
      const SizedBox(height: 14),
      Text(message, style: RText.body(size: 14, color: RColors.text3)),
      const SizedBox(height: 18),
      GestureDetector(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [RColors.brand, RColors.brand2]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text('Retry', style: RText.body(size: 13, weight: FontWeight.w700)),
        ),
      ),
    ]),
  );
}
