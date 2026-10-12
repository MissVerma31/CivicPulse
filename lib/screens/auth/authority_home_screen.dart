import 'package:flutter/foundation.dart'; // ValueNotifier
import 'package:flutter/material.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/token_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../models/complaint_model.dart';
import '../../repositories/complaint_repo.dart';
import '../citizen/complaint_details_screen.dart';
import 'role_selection_screen.dart';
import '../../widgets/sla_badge.dart';

/// "WATER_SUPPLY" -> "Water Supply"
String _pretty(String? s) {
  if (s == null || s.isEmpty) return '';
  return s
      .split('_')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

class AuthorityHomeScreen extends StatefulWidget {
  const AuthorityHomeScreen({super.key});

  @override
  State<AuthorityHomeScreen> createState() => _AuthorityHomeScreenState();
}

class _AuthorityHomeScreenState extends State<AuthorityHomeScreen> {
  late final ComplaintRepository _repo;
  String? _department;

  // Bumped whenever something may have changed (e.g. a complaint was
  // verified in the details screen), so BOTH tabs reload together.
  final ValueNotifier<int> _refresh = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _repo = ComplaintRepository(DioClient.createDio());
    _loadDepartment();
  }

  @override
  void dispose() {
    _refresh.dispose();
    super.dispose();
  }

  Future<void> _loadDepartment() async {
    final d = await TokenStorage.getDepartment();
    if (mounted) setState(() => _department = d);
  }

  Future<void> _logout() async {
    await TokenStorage.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Authority Dashboard'),
              if (_department != null && _department!.isNotEmpty)
                Text(
                  _pretty(_department),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Department'),
              Tab(text: 'Assigned to me'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ComplaintTab(
              loader: _repo.getAuthorityComplaints,
              refresh: _refresh,
              emptyText: 'No complaints for your department yet',
            ),
            _ComplaintTab(
              loader: _repo.getAssignedToMe,
              refresh: _refresh,
              emptyText: 'Nothing assigned to you yet.\nVerify a complaint to take it up.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplaintTab extends StatefulWidget {
  final Future<List<ComplaintResponse>> Function() loader;
  final ValueNotifier<int> refresh;
  final String emptyText;

  const _ComplaintTab({
    required this.loader,
    required this.refresh,
    required this.emptyText,
  });

  @override
  State<_ComplaintTab> createState() => _ComplaintTabState();
}

class _ComplaintTabState extends State<_ComplaintTab>
    with AutomaticKeepAliveClientMixin {
  List<ComplaintResponse> _all = [];
  bool _isLoading = true;
  String? _error;
  ComplaintStatus? _filter; // null = All

  // Needs-action first: pending, then verified, in progress, ...
  static const _order = [
    ComplaintStatus.pendingVerification,
    ComplaintStatus.verified,
    ComplaintStatus.inProgress,
    ComplaintStatus.resolved,
    ComplaintStatus.closed,
    ComplaintStatus.rejected,
  ];

  static const _chips = <(String, ComplaintStatus?)>[
    ('All', null),
    ('Pending', ComplaintStatus.pendingVerification),
    ('Verified', ComplaintStatus.verified),
    ('In Progress', ComplaintStatus.inProgress),
    ('Resolved', ComplaintStatus.resolved),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.refresh.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.refresh.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await widget.loader();
      if (!mounted) return;
      setState(() => _all = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _count(ComplaintStatus? s) =>
      s == null ? _all.length : _all.where((c) => c.status == s).length;

  List<ComplaintResponse> get _visible {
    final list = _filter == null
        ? [..._all]
        : _all.where((c) => c.status == _filter).toList();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    list.sort((a, b) {
      final r = _order.indexOf(a.status).compareTo(_order.indexOf(b.status));
      if (r != 0) return r;
      return (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch); // newest first
    });
    return list;
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year}';
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, status) = _chips[i];
          return ChoiceChip(
            label: Text('$label (${_count(status)})'),
            selected: _filter == status,
            showCheckmark: false,
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            onSelected: (_) => setState(() => _filter = status),
          );
        },
      ),
    );
  }

  Widget _buildCard(ComplaintResponse c) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = [c.categoryName, c.ward]
        .where((s) => s != null && s.isNotEmpty)
        .join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ComplaintDetailsScreen(complaintId: c.id)),
          );

          widget.refresh.value++;
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      c.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: c.status.name),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(subtitle, style: textTheme.bodyMedium),
              ],
              if (c.citizenName != null && c.citizenName!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('Reported by ${c.citizenName}', style: textTheme.bodySmall),
              ],
              if (c.slaDeadline != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SlaBadge(complaint: c),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (c.priority != null && c.priority!.isNotEmpty) ...[
                    const Icon(Icons.flag_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(_pretty(c.priority), style: textTheme.bodySmall),
                    const SizedBox(width: 12),
                  ],
                  const Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('${c.upvoteCount}', style: textTheme.bodySmall),
                  const Spacer(),
                  Text(_formatDate(c.createdAt), style: textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin

    final visible = _visible;

    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? ListView(
              children: [
                const SizedBox(height: 100),
                Center(child: Text(_error!)),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: 140,
                    child: ElevatedButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ),
                ),
              ],
            )
                : visible.isEmpty
                ? ListView(
              children: [
                const SizedBox(height: 120),
                const Icon(Icons.inbox_outlined, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _all.isEmpty ? widget.emptyText : 'No complaints in this status',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: visible.length,
              itemBuilder: (context, index) => _buildCard(visible[index]),
            ),
          ),
        ),
      ],
    );
  }
}