import 'package:flutter/foundation.dart'; // ValueNotifier
import 'package:flutter/material.dart';
import '../../widgets/civic_bottom_nav.dart';
import 'citizen_home_screen.dart';
import 'create_complaint_screen.dart';
import 'leaderboard_screen.dart';
import 'reward_history_screen.dart';

/// Host screen for the citizen side: shows one of the tab pages above a
/// persistent bottom nav bar. "Report" in the bar opens the create
/// complaint screen on top instead of being a tab.
class CitizenShellScreen extends StatefulWidget {
  const CitizenShellScreen({super.key});

  @override
  State<CitizenShellScreen> createState() => _CitizenShellScreenState();
}

class _CitizenShellScreenState extends State<CitizenShellScreen> {
  int _index = 0;

  // Bumped after a complaint is filed so the Home tab reloads its list.
  final ValueNotifier<int> _homeRefresh = ValueNotifier<int>(0);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Order must match CivicBottomNav: 0 = Home, 1 = Rewards, 2 = Leaderboard
    _pages = [
      CitizenHomeScreen(
        refreshTrigger: _homeRefresh,
        onOpenRewards: () => setState(() => _index = 1),
      ),
      const RewardsHistoryScreen(),
      const LeaderboardScreen(),
    ];
  }

  @override
  void dispose() {
    _homeRefresh.dispose();
    super.dispose();
  }

  Future<void> _openReport() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateComplaintScreen()),
    );
    if (!mounted) return;
    // After filing (or backing out), land on Home with a fresh list.
    _homeRefresh.value++;
    setState(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps each tab's state (scroll position, loaded data)
      // alive while switching between tabs.
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: CivicBottomNav(
        currentIndex: _index,
        onTabSelected: (i) => setState(() => _index = i),
        onReportTap: _openReport,
      ),
    );
  }
}