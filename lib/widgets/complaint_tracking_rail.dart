import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/complaint_model.dart';


class ComplaintTrackingRail extends StatelessWidget {
  final ComplaintStatus status;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? verifiedAt;
  final DateTime? resolvedAt;

  const ComplaintTrackingRail({
    super.key,
    required this.status,
    this.rejectionReason,
    this.createdAt,
    this.verifiedAt,
    this.resolvedAt,
  });

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // The backend has no "in progress" timestamp, so step 2 shows none.
  DateTime? _stepTime(int i) {
    switch (i) {
      case 0:
        return createdAt;
      case 1:
        return verifiedAt;
      case 3:
        return resolvedAt;
      default:
        return null;
    }
  }

  String _fmtTime(DateTime d) {
    final l = d.toLocal();
    final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final m = l.minute.toString().padLeft(2, '0');
    final ap = l.hour >= 12 ? 'PM' : 'AM';
    return '${l.day} ${_months[l.month - 1]}, $h:$m $ap';
  }

  static const _steps = ['Received', 'Verified', 'In Progress', 'Resolved'];

  int get _currentIndex {
    switch (status) {
      case ComplaintStatus.pendingVerification:
        return 0;
      case ComplaintStatus.verified:
        return 1;
      case ComplaintStatus.inProgress:
        return 2;
      case ComplaintStatus.resolved:
      case ComplaintStatus.closed:
        return 3;
      case ComplaintStatus.rejected:
        return -1; // handled separately below
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status == ComplaintStatus.rejected) {
      return _RejectedBanner(reason: rejectionReason);
    }

    final currentIndex = _currentIndex;
    final isClosed = status == ComplaintStatus.closed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(_steps.length * 2 - 1, (i) {
            if (i.isEven) {
              final stepIndex = i ~/ 2;
              final isFinalStepDone = stepIndex == 3 &&
                  (status == ComplaintStatus.resolved || status == ComplaintStatus.closed);
              final isComplete = stepIndex < currentIndex || isFinalStepDone;
              final isCurrent = stepIndex == currentIndex && !isFinalStepDone;
              return _StepNode(isComplete: isComplete, isCurrent: isCurrent);
            } else {
              final segmentIndex = i ~/ 2;
              final isComplete = segmentIndex < currentIndex;
              return Expanded(
                child: Container(
                  height: 2,
                  color: isComplete ? AppColors.secondary : AppColors.border,
                ),
              );
            }
          }),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _steps.asMap().entries.map((entry) {
            final i = entry.key;
            final label = entry.value;
            final isCurrent = i == currentIndex;
            final align = i == 0
                ? CrossAxisAlignment.start
                : i == _steps.length - 1
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.center;
            final textAlign = i == 0
                ? TextAlign.left
                : i == _steps.length - 1
                ? TextAlign.right
                : TextAlign.center;
            final time = _stepTime(i);
            return Expanded(
              child: Column(
                crossAxisAlignment: align,
                children: [
                  Text(
                    isClosed && i == 3 ? 'Closed' : label,
                    textAlign: textAlign,
                    style: GoogleFonts.publicSans(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                      color: isCurrent ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                  if (time != null)
                    Text(
                      _fmtTime(time),
                      textAlign: textAlign,
                      style: GoogleFonts.publicSans(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StepNode extends StatelessWidget {
  final bool isComplete;
  final bool isCurrent;
  const _StepNode({required this.isComplete, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    if (isComplete) {
      return Container(
        width: 24, height: 24,
        decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 15, color: Colors.white),
      );
    }
    if (isCurrent) {
      return Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 6, spreadRadius: 2),
          ],
        ),
      );
    }
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.textMuted, width: 2),
      ),
    );
  }
}

class _RejectedBanner extends StatelessWidget {
  final String? reason;
  const _RejectedBanner({this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_outlined, color: AppColors.errorColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complaint Rejected',
                  style: GoogleFonts.publicSans(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.errorColor,
                  ),
                ),
                if (reason != null && reason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reason!,
                    style: GoogleFonts.publicSans(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}