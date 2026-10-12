import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

/// Bottom navigation bar styled after the Stitch mockup: 4 slots, with
/// the 2nd slot ("Report") as a raised circular action button.
///
/// Only the 3 real tabs are tracked by [currentIndex]:
///   0 = Feed (complaint list), 1 = Rewards, 2 = Leaderboard
/// "Report" is an action (opens a screen), not a tab, so it uses
/// [onReportTap] instead of changing [currentIndex].
class CivicBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onReportTap;

  const CivicBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onReportTap,
  });

  static const double _barHeight = 64;
  static const double _raise = 16; // how far the Report circle pokes above the bar

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: _barHeight + _raise + bottomInset,
      child: Stack(
        children: [
          // The visible white bar, starting _raise px below the top so the
          // Report circle can sit above it while staying inside this
          // widget's bounds (keeps taps on the circle working).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: _raise,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0F0F172A),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore_rounded,
                    label: 'Feed',
                    selected: currentIndex == 0,
                    onTap: () => onTabSelected(0),
                  ),
                ),
                Expanded(child: _ReportItem(onTap: onReportTap)),
                Expanded(
                  child: _NavItem(
                    icon: Icons.military_tech_outlined,
                    activeIcon: Icons.military_tech_rounded,
                    label: 'Rewards',
                    selected: currentIndex == 1,
                    onTap: () => onTabSelected(1),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.leaderboard_outlined,
                    activeIcon: Icons.leaderboard_rounded,
                    label: 'Leaders',
                    selected: currentIndex == 2,
                    onTap: () => onTabSelected(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? activeIcon : icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportItem extends StatelessWidget {
  final VoidCallback onTap;
  const _ReportItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.canvas, width: 4),
                  boxShadow: AppColors.shadowLevel2,
                ),
                child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 2),
              Text(
                'Report',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}