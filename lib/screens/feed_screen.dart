import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../ads/ad_engine.dart';
import '../ads/ad_wrapper.dart';
import '../controllers/feed_controller.dart';
import '../controllers/settings_controller.dart';
import '../services/coin_service.dart';
import '../theme/tokens.dart';
import '../widgets/dot_loader.dart';
import '../widgets/feed_card.dart';
import 'coin_store_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late PageController _page;

  @override
  void initState() {
    super.initState();
    _page = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedController>().init();
    });
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fc    = context.watch<FeedController>();
    final coins = context.watch<CoinService>();

    return AdWrapper(
      child: Scaffold(
        backgroundColor: RColors.bg,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: Text('Reelz', style: RText.wordmark(size: 20)),
          centerTitle: true,
          actions: [
            // Coin balance tap → store
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: coins,
                    child: const CoinStoreScreen(),
                  ),
                ));
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: RColors.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: RColors.gold.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🪙', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text('${coins.coins}', style: RText.body(size: 13, weight: FontWeight.w700, color: RColors.gold)),
                ]),
              ),
            ),
          ],
        ),
        body: fc.isLoading
          ? _LoadingState(isWakingUp: fc.isWakingUp)
          : fc.error != null
            ? _ErrorState(onRetry: () => context.read<FeedController>().refresh())
            : fc.movies.isEmpty
              ? _EmptyState()
              : PageView.builder(
                  controller: _page,
                  scrollDirection: Axis.vertical,
                  onPageChanged: (i) {
                    context.read<FeedController>().onPageChanged(i);
                    context.read<AdEngine>().onFeedSwipe();
                  },
                  itemCount: fc.movies.length,
                  itemBuilder: (_, i) => FeedCard(movie: fc.movies[i], index: i),
                ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final bool isWakingUp;
  const _LoadingState({required this.isWakingUp});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SamsungLoader(size: 44),
      if (isWakingUp) ...[
        const SizedBox(height: 18),
        Text('Warming up…', style: RText.body(size: 13, color: RColors.text3))
          .animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 800.ms),
      ],
    ]),
  );
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, color: RColors.text3, size: 52),
      const SizedBox(height: 16),
      Text('Could not load feed', style: RText.body(size: 16, weight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('Check your connection', style: RText.body(size: 13, color: RColors.text3)),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [RColors.brand, RColors.brand2]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: RColors.brand.withOpacity(0.4), blurRadius: 20)],
          ),
          child: Text('Try Again', style: RText.body(size: 14, weight: FontWeight.w700)),
        ),
      ),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Text('No content yet', style: TextStyle(color: RColors.text3)),
  );
}
