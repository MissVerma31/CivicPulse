import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/network/dio_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/reward_model.dart';
import '../../repositories/reward_repo.dart';

class RewardsHistoryScreen extends StatefulWidget {
  const RewardsHistoryScreen({super.key});

  @override
  State<RewardsHistoryScreen> createState() => _RewardsHistoryScreenState();
}

class _RewardsHistoryScreenState extends State<RewardsHistoryScreen> {
  late final RewardRepository _rewardRepository;
  List<RewardHistoryItem> _rewards = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rewardRepository = RewardRepository(DioClient.createDio());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final page = await _rewardRepository.getMyRewards(page: 0, size: 50);
      setState(() => _rewards = page.content);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // DESIGN.md "Gamification & Community Elements" -> Reputation Pill:
  // #FFFBEB bg, 1px #FDE68A border, amber star icon, stat-counter number.
  Widget _buildReputationPill(int totalPoints) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: AppColors.tertiary, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Total points', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Text(
            '$totalPoints',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.02 * 24,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardTile(RewardHistoryItem r) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, color: AppColors.tertiary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.readableReason, style: textTheme.titleLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    r.complaintTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              '+${r.points}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
                fontSize: 15,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final totalPoints = _rewards.fold<int>(0, (sum, r) => sum + r.points);

    return Scaffold(
      appBar: AppBar(title: const Text('Rewards history')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
          children: [
            const SizedBox(height: 100),
            Center(child: Text(_error!, style: textTheme.bodyMedium)),
          ],
        )
            : _rewards.isEmpty
            ? ListView(
          children: [
            const SizedBox(height: 150),
            const Icon(Icons.military_tech_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Center(
              child: Text('No rewards yet', style: textTheme.titleLarge?.copyWith(fontSize: 16)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Get points when your complaints are verified and resolved',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              ),
            ),
          ],
        )
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildReputationPill(totalPoints),
            const SizedBox(height: 16),
            ..._rewards.map(_buildRewardTile),
          ],
        ),
      ),
    );
  }
}