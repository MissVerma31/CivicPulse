import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Shows progress toward the badges that have not been earned yet.
/// Rules (from the backend): Bronze/Silver/Gold Reporter = 3/10/25
/// complaints submitted, Trusted Citizen = 5 verified complaints,
/// Community Hero = 100 reputation points.
class BadgeProgress extends StatelessWidget {
  final int submitted;
  final int verified;
  final int points;

  const BadgeProgress({
    super.key,
    required this.submitted,
    required this.verified,
    required this.points,
  });

  static const _reporterTiers = [
    (3, 'Bronze Reporter'),
    (10, 'Silver Reporter'),
    (25, 'Gold Reporter'),
  ];

  Widget _row(BuildContext context, String name, String hint, int value, int target) {
    final textTheme = Theme.of(context).textTheme;
    final progress = (value / target).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text('$value / $target', style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              color: AppColors.tertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(hint, style: textTheme.bodySmall),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    // Reporter track: only the next tier not yet reached.
    final nextTiers = _reporterTiers.where((t) => submitted < t.$1).toList();
    if (nextTiers.isNotEmpty) {
      final t = nextTiers.first;
      rows.add(_row(context, t.$2, 'Submit ${t.$1} complaints', submitted, t.$1));
    }
    if (verified < 5) {
      rows.add(_row(context, 'Trusted Citizen', 'Get 5 complaints verified', verified, 5));
    }
    if (points < 100) {
      rows.add(_row(context, 'Community Hero', 'Reach 100 reputation points', points, 100));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Next badges', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }
}