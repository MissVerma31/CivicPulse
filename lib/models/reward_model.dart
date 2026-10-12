// Confirmed from RewardHistoryResponse schema:
// { id, points, reason, complaintId, complaintTitle, createdAt }
// `reason` values seen so far: "COMPLAINT_VERIFIED" (example in Swagger).
// Other reasons likely exist (e.g. complaint resolved/closed) -- update
// this list if you spot more in actual API responses.
enum RewardReason {
  complaintVerified,
  complaintResolved,
  complaintClosed,
  unknown,
}

RewardReason rewardReasonFromString(String? value) {
  switch (value) {
    case 'COMPLAINT_VERIFIED':
      return RewardReason.complaintVerified;
    case 'COMPLAINT_RESOLVED':
      return RewardReason.complaintResolved;
    case 'COMPLAINT_CLOSED':
      return RewardReason.complaintClosed;
    default:
      return RewardReason.unknown;
  }
}

class RewardHistoryItem {
  final int id;
  final int points;
  final RewardReason reason;
  final int complaintId;
  final String complaintTitle;
  final DateTime? createdAt;

  RewardHistoryItem({
    required this.id,
    required this.points,
    required this.reason,
    required this.complaintId,
    required this.complaintTitle,
    this.createdAt,
  });

  factory RewardHistoryItem.fromJson(Map<String, dynamic> json) {
    return RewardHistoryItem(
      id: json['id'] as int,
      points: json['points'] as int,
      reason: rewardReasonFromString(json['reason'] as String?),
      complaintId: json['complaintId'] as int,
      complaintTitle: json['complaintTitle'] ?? '',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
    );
  }

  /// Human-readable label for the reward reason, used directly in UI
  /// (e.g. RewardsHistoryScreen's list tiles).
  String get readableReason {
    switch (reason) {
      case RewardReason.complaintVerified:
        return 'Complaint Verified';
      case RewardReason.complaintResolved:
        return 'Complaint Resolved';
      case RewardReason.complaintClosed:
        return 'Complaint Closed';
      case RewardReason.unknown:
        return 'Reward Earned';
    }
  }
}

// Confirmed from LeaderboardResponse schema: { rank, name, reputationPoints, city }
// Note: GET /api/leaderboard returns a plain array, NOT paginated
// (unlike /api/users/me/rewards, which uses PageRewardHistoryResponse).
class LeaderboardEntry {
  final int rank;
  final String name;
  final int reputationPoints;
  final String city;

  LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.reputationPoints,
    required this.city,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      name: json['name'] ?? '',
      reputationPoints: json['reputationPoints'] as int,
      city: json['city'] ?? '',
    );
  }
}