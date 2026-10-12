import 'package:flutter/material.dart';
import '../../core/services/notification_store.dart';
import '../../core/theme/app_theme.dart';
import '../../models/complaint_model.dart';
import 'complaint_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _store = NotificationStore.instance;
  late final Set<AppNotification> _unreadAtOpen;

  @override
  void initState() {
    super.initState();
    _unreadAtOpen = _store.items.where((n) => !n.read).toSet();
    WidgetsBinding.instance.addPostFrameCallback((_) => _store.markAllRead());
  }

  IconData _icon(ComplaintStatus s) {
    switch (s) {
      case ComplaintStatus.verified:
        return Icons.verified_outlined;
      case ComplaintStatus.inProgress:
        return Icons.construction_outlined;
      case ComplaintStatus.resolved:
        return Icons.check_circle_outline;
      case ComplaintStatus.rejected:
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _color(ComplaintStatus s) {
    switch (s) {
      case ComplaintStatus.resolved:
        return AppColors.secondary;
      case ComplaintStatus.rejected:
        return AppColors.errorColor;
      default:
        return AppColors.primary;
    }
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final items = _store.items;
          if (items.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 150),
                Icon(Icons.notifications_none, size: 64, color: AppColors.textMuted),
                SizedBox(height: 16),
                Center(child: Text('No updates yet')),
                SizedBox(height: 4),
                Center(
                  child: Text(
                    'You will see changes to your complaints here',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final n = items[i];
              final isNew = _unreadAtOpen.contains(n);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ComplaintDetailsScreen(complaintId: n.complaintId),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_icon(n.status), color: _color(n.status)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.message,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: isNew ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(_ago(n.time), style: textTheme.bodySmall),
                            ],
                          ),
                        ),
                        if (isNew)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}