import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/complaint_model.dart';

/// Small pill showing where a complaint stands against its SLA:
///   - open, plenty of time  -> blue   "2d 4h left"
///   - open, < 6 hours left  -> amber  "3h 20m left"
///   - open, deadline passed -> red    "SLA overdue by 5h 10m"
///   - resolved in time      -> green  "Resolved within SLA"
///   - resolved late         -> amber  "Resolved late"
/// Renders nothing when the backend hasn't sent a deadline (yet), or for
/// rejected complaints.
class SlaBadge extends StatefulWidget {
  final ComplaintResponse complaint;
  const SlaBadge({super.key, required this.complaint});

  @override
  State<SlaBadge> createState() => _SlaBadgeState();
}

class _SlaBadgeState extends State<SlaBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Keep the countdown fresh while the screen stays open.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final a = d.abs();
    if (a.inDays >= 1) return '${a.inDays}d ${a.inHours % 24}h';
    if (a.inHours >= 1) return '${a.inHours}h ${a.inMinutes % 60}m';
    return '${a.inMinutes < 1 ? 1 : a.inMinutes}m';
  }

  (Color, Color, IconData, String) _resolve(ComplaintResponse c, DateTime deadline) {
    final red = AppColors.errorColor;

    if (c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.closed) {
      if (c.slaResolvedLate) {
        return (AppColors.pendingBg, AppColors.pendingText, Icons.history_toggle_off, 'Resolved late');
      }
      return (AppColors.resolvedBg, AppColors.resolvedText, Icons.verified_outlined, 'Resolved within SLA');
    }

    if (c.isSlaOverdue) {
      final over = DateTime.now().difference(deadline);
      final suffix = over.isNegative ? '' : ' by ${_fmt(over)}';
      return (red.withValues(alpha: 0.10), red, Icons.warning_amber_rounded, 'SLA overdue$suffix');
    }

    final remaining = deadline.difference(DateTime.now());
    if (remaining.inHours < 6) {
      return (AppColors.pendingBg, AppColors.pendingText, Icons.timer_outlined, '${_fmt(remaining)} left');
    }
    return (AppColors.noticeBg, AppColors.noticeText, Icons.timer_outlined, '${_fmt(remaining)} left');
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    final deadline = c.slaDeadline;
    if (deadline == null || c.status == ComplaintStatus.rejected) {
      return const SizedBox.shrink();
    }

    final (bg, fg, icon, label) = _resolve(c, deadline);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.publicSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}