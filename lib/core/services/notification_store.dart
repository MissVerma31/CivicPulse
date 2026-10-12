import 'package:flutter/foundation.dart';
import '../../models/complaint_model.dart';

class AppNotification {
  final int complaintId;
  final String message;
  final ComplaintStatus status;
  final DateTime time;
  bool read;

  AppNotification({
    required this.complaintId,
    required this.message,
    required this.status,
    required this.time,
    this.read = false,
  });
}

class NotificationStore extends ChangeNotifier {
  NotificationStore._();
  static final NotificationStore instance = NotificationStore._();

  final Map<int, ComplaintStatus> _lastStatus = {};
  final List<AppNotification> _items = [];

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.read).length;

  static String? _messageFor(ComplaintResponse c) {
    switch (c.status) {
      case ComplaintStatus.verified:
        return 'Your complaint "${c.title}" was verified.';
      case ComplaintStatus.inProgress:
        return 'Work has started on "${c.title}".';
      case ComplaintStatus.resolved:
        return '"${c.title}" was marked resolved. Please review and close it.';
      case ComplaintStatus.rejected:
        final r = c.rejectionReason;
        return '"${c.title}" was rejected${(r != null && r.isNotEmpty) ? ': $r' : '.'}';
    // Closing is done by the citizen, so no notification for it.
      case ComplaintStatus.closed:
      case ComplaintStatus.pendingVerification:
        return null;
    }
  }
  /// Call right after a complaint is successfully created, so the citizen
  /// gets immediate confirmation instead of waiting for the next poll.
  void notifyFiled(ComplaintResponse c) {
    _items.insert(
      0,
      AppNotification(
        complaintId: c.id,
        message: 'Your complaint "${c.title}" was filed and is pending verification.',
        status: c.status,
        time: DateTime.now(),
      ),
    );
    // Seed the baseline so the next poll doesn't treat this as a "change".
    _lastStatus[c.id] = c.status;
    notifyListeners();
  }
  /// Returns true if at least one complaint changed status.
  bool checkComplaints(List<ComplaintResponse> complaints) {
    var changed = false;
    for (final c in complaints) {
      final prev = _lastStatus[c.id];
      if (prev != null && prev != c.status) {
        final msg = _messageFor(c);
        if (msg != null) {
          _items.insert(
            0,
            AppNotification(
              complaintId: c.id,
              message: msg,
              status: c.status,
              time: DateTime.now(),
            ),
          );
        }
        changed = true;
      }
      _lastStatus[c.id] = c.status;
    }
    if (changed) notifyListeners();
    return changed;
  }

  void markAllRead() {
    for (final n in _items) {
      n.read = true;
    }
    notifyListeners();
  }

  /// Call on logout so the next account starts clean.
  void clear() {
    _lastStatus.clear();
    _items.clear();
    notifyListeners();
  }
}