import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/coin_service.dart';
import '../theme/tokens.dart';
import '../widgets/dot_loader.dart';

enum QuestType { watchAd, downloadApp, dailyLogin, watchEpisodes, shareApp }
enum QuestStatus { available, claimed, cooldown }

class Quest {
  final String id;
  final QuestType type;
  final String title;
  final String description;
  final int coinsReward;
  final String icon;
  QuestStatus status;
  DateTime? cooldownUntil;

  Quest({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.coinsReward,
    required this.icon,
    this.status = QuestStatus.available,
    this.cooldownUntil,
  });

  bool get isOnCooldown =>
      status == QuestStatus.cooldown &&
      cooldownUntil != null &&
      DateTime.now().isBefore(cooldownUntil!);
}

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});
  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  late List<Quest> _quests;
  late Timer _tick;

  @override
  void initState() {
    super.initState();
    _quests = _buildQuests();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _tick.cancel(); super.dispose(); }

  List<Quest> _buildQuests() => [
    Quest(id: 'daily_login',     type: QuestType.dailyLogin,    title: 'Daily Check-in',        description: 'Log in today to claim your reward',         coinsReward: 15,  icon: '📅'),
    Quest(id: 'watch_ad_1',      type: QuestType.watchAd,       title: 'Watch a Short Ad',      description: 'Watch a 15-second ad to earn coins',        coinsReward: 8,   icon: '📺'),
    Quest(id: 'watch_ad_2',      type: QuestType.watchAd,       title: 'Watch Another Ad',      description: 'Watch one more ad for bonus coins',         coinsReward: 8,   icon: '🎬'),
    Quest(id: 'download_app_1',  type: QuestType.downloadApp,   title: 'Try This App',          description: 'Download the featured app and earn big',    coinsReward: 60,  icon: '📲'),
    Quest(id: 'download_app_2',  type: QuestType.downloadApp,   title: 'Discover a New Game',   description: 'Download and earn a massive reward',        coinsReward: 80,  icon: '🎮'),
    Quest(id: 'watch_episodes',  type: QuestType.watchEpisodes, title: 'Watch 3 Episodes',      description: 'Watch any 3 episodes today',                coinsReward: 20,  icon: '▶️'),
    Quest(id: 'share_app',       type: QuestType.shareApp,      title: 'Share Reelz',           description: 'Share the app with a friend',               coinsReward: 25,  icon: '🔗'),
  ];

  Future<void> _claimQuest(Quest quest) async {
    if (quest.status != QuestStatus.available) return;
    HapticFeedback.mediumImpact();

    final coins = context.read<CoinService>();

    setState(() => quest.status = QuestStatus.claimed);

    // Simulate quest action
    await Future.delayed(const Duration(milliseconds: 600));

    await coins.earnFromQuest(quest.coinsReward);

    // Set cooldown for repeatable quests
    if (quest.type == QuestType.watchAd) {
      setState(() {
        quest.status = QuestStatus.cooldown;
        quest.cooldownUntil = DateTime.now().add(const Duration(minutes: 30));
      });
    }

    if (mounted) _showRewardPopup(quest.coinsReward);
  }

  void _showRewardPopup(int coins) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RewardSheet(coins: coins),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coinSvc = context.watch<CoinService>();
    final totalAvailable = _quests.where((q) => q.status == QuestStatus.available).fold(0, (s, q) => s + q.coinsReward);

    return Scaffold(
      backgroundColor: RColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(children: [
                    Text('Earn Coins', style: RText.wordmark(size: 20)),
                    const Spacer(),
                    _CoinWidget(coins: coinSvc.coins),
                  ]),
                ),
                const SizedBox(height: 20),
                _EarningsBanner(totalAvailable: totalAvailable),
                const SizedBox(height: 8),
              ]),
            ),
          ),

          // ── Daily quests ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(label: 'Daily Tasks', icon: Icons.calendar_today_rounded),
                  const SizedBox(height: 10),
                  ..._quests.asMap().entries.map((e) =>
                    _QuestCard(quest: e.value, onClaim: () => _claimQuest(e.value))
                      .animate().fadeIn(delay: Duration(milliseconds: e.key * 50)).slideY(begin: 0.15, end: 0, curve: RCurve.spring),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Earnings Banner ────────────────────────────────────────────────────────────

class _EarningsBanner extends StatelessWidget {
  final int totalAvailable;
  const _EarningsBanner({required this.totalAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RColors.brand.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFFFFBB38), Color(0xFFFF8C00)]),
            boxShadow: [BoxShadow(color: const Color(0xFFFFBB38).withOpacity(0.4), blurRadius: 14)],
          ),
          child: const Center(child: Text('⚡', style: TextStyle(fontSize: 24))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$totalAvailable coins available', style: RText.body(size: 18, weight: FontWeight.w800, color: RColors.gold)),
          Text('Complete tasks to earn them all', style: RText.label(color: RColors.text3)),
        ])),
      ]),
    );
  }
}

// ── Quest Card ─────────────────────────────────────────────────────────────────

class _QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback onClaim;
  const _QuestCard({required this.quest, required this.onClaim});

  String _formatCooldown() {
    if (quest.cooldownUntil == null) return '';
    final rem = quest.cooldownUntil!.difference(DateTime.now());
    if (rem.isNegative) return '';
    final m = rem.inMinutes;
    final s = rem.inSeconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final isClaimed  = quest.status == QuestStatus.claimed;
    final isCooldown = quest.isOnCooldown;
    final isAvailable = quest.status == QuestStatus.available;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: RColors.bgRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailable ? RColors.brand.withOpacity(0.2) : RColors.glassBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: isAvailable ? RColors.brand.withOpacity(0.12) : RColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isAvailable ? RColors.brand.withOpacity(0.25) : RColors.glassBorder),
            ),
            child: Center(child: Text(quest.icon, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(quest.title, style: RText.body(size: 14, weight: FontWeight.w700,
                color: isClaimed ? RColors.text3 : RColors.text)),
            const SizedBox(height: 3),
            Text(quest.description, style: RText.label(color: RColors.text3), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (isCooldown && quest.cooldownUntil != null) ...[
              const SizedBox(height: 4),
              Text('Refreshes in ${_formatCooldown()}', style: RText.label(size: 10, color: RColors.brand)),
            ],
          ])),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isAvailable ? onClaim : null,
            child: AnimatedContainer(
              duration: RDur.md,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: isAvailable
                  ? const LinearGradient(colors: [RColors.brand, RColors.brand2])
                  : null,
                color: isAvailable ? null : RColors.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: isAvailable ? null : Border.all(color: RColors.glassBorder),
              ),
              child: isClaimed
                ? const Icon(Icons.check_rounded, color: Colors.green, size: 18)
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🪙', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text('+${quest.coinsReward}',
                      style: RText.body(size: 12, weight: FontWeight.w700,
                        color: isAvailable ? Colors.white : RColors.text3)),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Reward Sheet ───────────────────────────────────────────────────────────────

class _RewardSheet extends StatelessWidget {
  final int coins;
  const _RewardSheet({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
      decoration: BoxDecoration(
        color: RColors.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: RColors.glassMd, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text('⚡', style: const TextStyle(fontSize: 48)).animate().scale(begin: const Offset(0.3, 0.3), curve: RCurve.spring),
        const SizedBox(height: 10),
        Text('+$coins Coins Earned!', style: RText.body(size: 22, weight: FontWeight.w800, color: RColors.gold)),
        const SizedBox(height: 6),
        Text('Keep completing tasks for more!', style: RText.body(size: 13, color: RColors.text3)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity, height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [RColors.brand, RColors.brand2]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text('Collect!', style: RText.body(size: 15, weight: FontWeight.w700))),
          ),
        ),
      ]),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: RColors.brand),
    const SizedBox(width: 6),
    Text(label.toUpperCase(), style: RText.label(size: 11, color: RColors.brand)),
  ]);
}

// ── Coin Widget ────────────────────────────────────────────────────────────────

class _CoinWidget extends StatelessWidget {
  final int coins;
  const _CoinWidget({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: RColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RColors.gold.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('🪙', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 5),
        Text('$coins', style: RText.body(size: 13, weight: FontWeight.w700, color: RColors.gold)),
      ]),
    );
  }
}
