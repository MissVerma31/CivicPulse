import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/notification_store.dart';
import '../../core/storage/token_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../models/auth_models.dart';
import '../../models/complaint_model.dart';
import '../../repositories/auth_repo.dart';
import '../../repositories/complaint_repo.dart';
import '../../repositories/reward_repo.dart';
import '../../widgets/sla_badge.dart';
import '../auth/role_selection_screen.dart';
import 'complaint_details_screen.dart';
import 'notification_screen.dart';
import 'reward_history_screen.dart';
import 'package:flutter/foundation.dart';
import '../../widgets/badge_progress.dart';

class CitizenHomeScreen extends StatefulWidget {

  final ValueListenable<int>? refreshTrigger;


  final VoidCallback? onOpenRewards;

  const CitizenHomeScreen({super.key, this.refreshTrigger, this.onOpenRewards});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  late final ComplaintRepository _complaintRepository;
  late final RewardRepository _rewardRepository;
  List<ComplaintResponse> _complaints = [];
  UserResponse? _currentUser;
  List<String>? _badges;
  bool _isLoading = true;
  String? _error;
  List<ComplaintResponse> _feed = [];
  bool _isFeedLoading = true;

  Timer? _pollTimer;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    _complaintRepository = ComplaintRepository(DioClient.createDio());
    _rewardRepository = RewardRepository(DioClient.createDio());
    widget.refreshTrigger?.addListener(_onRefreshTrigger);
    _loadComplaints();
    _loadProfile();
    _loadBadges();
    _loadFeed();
    // Live tracking: quietly re-check complaints every 25 seconds.
    _pollTimer = Timer.periodic(const Duration(seconds: 25), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    widget.refreshTrigger?.removeListener(_onRefreshTrigger);
    super.dispose();
  }

  void _onRefreshTrigger() {
    _loadComplaints();
    _loadProfile();
    _loadBadges();
  }

  Future<void> _poll() async {
    if (_polling || _isLoading) return;
    _polling = true;
    try {
      await _loadComplaints(silent: true);
    } finally {
      _polling = false;
    }
  }

  Future<void> _loadProfile() async {
    try {
      final authRepo = AuthRepository(DioClient.createDio());
      final user = await authRepo.getCurrentUser();
      if (mounted) setState(() => _currentUser = user);
    } catch (_) {
      // non-critical — profile card just won't show if this fails
    }
  }

  Future<void> _loadBadges() async {
    try {
      final badges = await _rewardRepository.getMyBadges();
      if (mounted) setState(() => _badges = badges);
    } catch (_) {
      // non-critical — badges section just won't show if this fails
    }
  }

  /// [silent] = background refresh: no spinner, and errors are ignored so
  /// the list on screen is never wiped by a failed poll.
  Future<void> _loadComplaints({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final page = await _complaintRepository.getMyComplaints(page: 0, size: 100);
      if (!mounted) return;
      final changed = NotificationStore.instance.checkComplaints(page.content);
      setState(() => _complaints = page.content);
      if (changed) {
        // A status change can also mean new points or a new badge.
        _loadProfile();
        _loadBadges();
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFeed() async {
    setState(() => _isFeedLoading = true);
    try {
      final page = await _complaintRepository.getAllComplaintsPublic(page: 0, size: 20);
      if (mounted) setState(() => _feed = page.content);
    } catch (_) {
      // non-critical — feed section just stays empty if this fails
    } finally {
      if (mounted) setState(() => _isFeedLoading = false);
    }
  }

  Future<void> _refreshAll() async {
    _loadProfile();
    _loadBadges();
    await _loadComplaints();
  }

  Future<void> _logout() async {
    await TokenStorage.clearToken();
    NotificationStore.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          (route) => false,
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openRewards() {
    if (widget.onOpenRewards != null) {
      widget.onOpenRewards!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RewardsHistoryScreen()),
      );
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year}';
  }

  // Relative time for the "footer" of each report card, per DESIGN.md's
  // "Card & Ticket Modules" spec ("relative time marker"). Falls back to
  // a plain date once something is more than a week old.
  String _relativeTime(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _formatDate(d);
  }

  IconData _iconForCategory(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('pothole') || n.contains('road')) return Icons.directions_car_filled_rounded;
    if (n.contains('light')) return Icons.lightbulb_outline_rounded;
    if (n.contains('garbage') || n.contains('sanitation') || n.contains('trash')) return Icons.delete_outline_rounded;
    if (n.contains('animal')) return Icons.pets_rounded;
    if (n.contains('water')) return Icons.water_drop_outlined;
    if (n.contains('tax') || n.contains('revenue')) return Icons.account_balance_outlined;
    return Icons.report_gmailerrorred_rounded;
  }

  // ---------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------

  Widget _buildTopBar() {
    final user = _currentUser;
    final initial = (user?.name.isNotEmpty == true) ? user!.name.characters.first.toUpperCase() : '?';
    final locationLine = [user?.ward, user?.city]
        .where((s) => s != null && s.isNotEmpty)
        .join(' • Ward ');
    // Produces "Ward <ward> • <city>" style if both present, per mockup's
    // top-bar subtitle -- built only from real profile fields.
    final subtitle = (user?.ward != null && user!.ward.isNotEmpty)
        ? 'Ward ${user.ward}${user.city.isNotEmpty ? ' • ${user.city}' : ''}'
        : (user?.city ?? '');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_moon_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CivicPulse', style: Theme.of(context).textTheme.titleLarge),
                if (subtitle.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          subtitle,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: NotificationStore.instance,
            builder: (context, _) {
              final n = NotificationStore.instance.unreadCount;
              return IconButton(
                tooltip: 'Notifications',
                onPressed: _openNotifications,
                icon: Badge(
                  isLabelVisible: n > 0,
                  label: Text('$n'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              );
            },
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: _logout,
            child: Tooltip(
              message: 'Logout',
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.secondary,
                child: Text(
                  initial,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Reputation pill (real data: currentUser.reputationPoints)
  // ---------------------------------------------------------------

  Widget _buildReputationCard() {
    final user = _currentUser!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openRewards,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: AppColors.tertiary, shape: BoxShape.circle),
                  child: const Icon(Icons.star_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Reputation points', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        '${user.reputationPoints}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.02 * 28,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Badges (real data: rewardRepository.getMyBadges)
  // ---------------------------------------------------------------

  Widget _buildBadgesCard() {
    final textTheme = Theme.of(context).textTheme;
    final badges = _badges ?? const <String>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.military_tech_rounded, size: 18, color: AppColors.tertiary),
                const SizedBox(width: 6),
                Text('Your badges', style: textTheme.titleLarge?.copyWith(fontSize: 15)),
              ],
            ),
            const SizedBox(height: 10),
            if (badges.isEmpty)
              Text(
                'Earn your first badge by reporting an issue',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: badges.map(_buildBadgeChip).toList(),
              ),
            const SizedBox(height: 14),
            BadgeProgress(
              submitted: _complaints.length,
              verified: _complaints
                  .where((c) =>
              c.status != ComplaintStatus.pendingVerification &&
                  c.status != ComplaintStatus.rejected)
                  .length,
              points: _currentUser?.reputationPoints ?? 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.military_tech_rounded, size: 16, color: AppColors.tertiary),
          const SizedBox(width: 6),
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Honest placeholder: there is no public/community complaints
  // endpoint. This card says so plainly instead of faking a feed.
  // ---------------------------------------------------------------

  Widget _buildCommunityFeedSection() {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Community feed', style: textTheme.titleLarge),
              Text('${_feed.length}', style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          if (_isFeedLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_feed.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No complaints filed yet in the community.',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
            )
          else
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _feed.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => SizedBox(
                  width: 240,
                  child: _buildComplaintCard(_feed[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // My reports (real data: complaintRepository.getMyComplaints)
  // ---------------------------------------------------------------

  Widget _buildComplaintCard(ComplaintResponse c) {
    final textTheme = Theme.of(context).textTheme;
    final hasPhoto = c.photoUrl != null && c.photoUrl!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ComplaintDetailsScreen(complaintId: c.id)),
          );
          _loadComplaints(silent: true);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasPhoto)
              Image.network(
                c.photoUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => const SizedBox.shrink(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 140,
                    color: AppColors.canvas,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header slot: category icon + ticket id, SLA pill.
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_iconForCategory(c.categoryName), size: 15, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '#${c.id}',
                        style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      SlaBadge(complaint: c),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          c.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: c.status.name),
                    ],
                  ),
                  if (c.description != null && c.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      c.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${c.upvoteCount}', style: textTheme.bodySmall),
                      const SizedBox(width: 12),
                      if (c.city != null && c.city!.isNotEmpty) ...[
                        const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(c.city!, overflow: TextOverflow.ellipsis, style: textTheme.bodySmall),
                        ),
                      ],
                      const Spacer(),
                      Text(_relativeTime(c.createdAt), style: textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _buildTopBar(),
              if (_currentUser != null) _buildReputationCard(),
              if (_badges != null) _buildBadgesCard(),
              _buildCommunityFeedSection(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My reports', style: Theme.of(context).textTheme.titleLarge),
                    Text('${_complaints.length}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 140,
                        child: ElevatedButton(onPressed: _loadComplaints, child: const Text('Retry')),
                      ),
                    ],
                  ),
                )
              else if (_complaints.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined, size: 56, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text('No complaints yet'),
                      const SizedBox(height: 4),
                      Text(
                        'Tap Report below to file your first complaint',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _complaints.map(_buildComplaintCard).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}