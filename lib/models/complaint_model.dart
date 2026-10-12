enum ComplaintStatus {
  pendingVerification,
  verified,
  inProgress,
  resolved,
  closed,
  rejected;

  static ComplaintStatus fromString(String s) {
    switch (s) {
      case 'PENDING_VERIFICATION': return ComplaintStatus.pendingVerification;
      case 'VERIFIED': return ComplaintStatus.verified;
      case 'IN_PROGRESS': return ComplaintStatus.inProgress;
      case 'RESOLVED': return ComplaintStatus.resolved;
      case 'CLOSED': return ComplaintStatus.closed;
      case 'REJECTED': return ComplaintStatus.rejected;
      default: throw Exception('Unknown status: $s');
    }
  }

  String get label {
    switch (this) {
      case ComplaintStatus.pendingVerification: return 'Pending Verification';
      case ComplaintStatus.verified: return 'Verified';
      case ComplaintStatus.inProgress: return 'In Progress';
      case ComplaintStatus.resolved: return 'Resolved';
      case ComplaintStatus.closed: return 'Closed';
      case ComplaintStatus.rejected: return 'Rejected';
    }
  }
}

class ComplaintCreateRequest {
  final String title;
  final String? description;
  final int categoryId;
  final String? photoUrl;
  final double latitude;
  final double longitude;
  final String? address;
  final String city;
  final String ward;

  ComplaintCreateRequest({
    required this.title,
    this.description,
    required this.categoryId,
    this.photoUrl,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.city,
    required this.ward,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    if (description != null) 'description': description,
    'categoryId': categoryId,
    if (photoUrl != null) 'photoUrl': photoUrl,
    'latitude': latitude,
    'longitude': longitude,
    if (address != null) 'address': address,
    'city': city,
    'ward': ward,
  };
}

class ComplaintResponse {
  final int id;
  final String title;
  final String? description;
  final String? categoryName;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? city;
  final String? ward;
  final String? department;
  final String? priority;
  final ComplaintStatus status;
  final String? citizenName;
  final String? assignedAuthorityName;
  final String? rejectionReason;
  final String? resolutionNote;
  final String? resolutionPhotoUrl;
  final DateTime? createdAt;
  final DateTime? verifiedAt;
  final DateTime? resolvedAt;
  final int upvoteCount;

  // SLA tracking. Both are OPTIONAL on purpose: they stay null until the
  // backend starts returning them, and the UI simply shows nothing then.
  // (Names as proposed to the backend team - confirm in Swagger.)
  final DateTime? slaDeadline;
  final bool? slaBreached;

  ComplaintResponse({
    required this.id,
    required this.title,
    this.description,
    this.categoryName,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.address,
    this.city,
    this.ward,
    this.department,
    this.priority,
    required this.status,
    this.citizenName,
    this.assignedAuthorityName,
    this.rejectionReason,
    this.resolutionNote,
    this.resolutionPhotoUrl,
    this.createdAt,
    this.verifiedAt,
    this.resolvedAt,
    this.upvoteCount = 0,
    this.slaDeadline,
    this.slaBreached,
  });

  factory ComplaintResponse.fromJson(Map<String, dynamic> json) {
    return ComplaintResponse(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      categoryName: json['categoryName'],
      photoUrl: json['photoUrl'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'],
      city: json['city'],
      ward: json['ward'],
      department: json['department'],
      priority: json['priority'],
      status: ComplaintStatus.fromString(json['status']),
      citizenName: json['citizenName'],
      assignedAuthorityName: json['assignedAuthorityName'],
      rejectionReason: json['rejectionReason'],
      resolutionNote: json['resolutionNote'],
      resolutionPhotoUrl: json['resolutionPhotoUrl'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      verifiedAt: json['verifiedAt'] != null ? DateTime.parse(json['verifiedAt']) : null,
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      upvoteCount: json['upvoteCount'] ?? 0,
      slaDeadline: json['slaDeadline'] != null
          ? DateTime.tryParse(json['slaDeadline'].toString())
          : null,
      slaBreached: json['slaBreached'] is bool ? json['slaBreached'] as bool : null,
    );
  }

  /// Still waiting on the authority (not resolved / closed / rejected).
  bool get isOpen =>
      status != ComplaintStatus.resolved &&
          status != ComplaintStatus.closed &&
          status != ComplaintStatus.rejected;

  /// Open complaint whose SLA deadline has passed (or the backend flagged it).
  bool get isSlaOverdue {
    if (!isOpen) return false;
    if (slaBreached == true) return true;
    final d = slaDeadline;
    return d != null && DateTime.now().isAfter(d);
  }

  /// Resolved/closed complaint that missed its SLA.
  bool get slaResolvedLate {
    if (isOpen || status == ComplaintStatus.rejected) return false;
    if (slaBreached == true) return true;
    final d = slaDeadline;
    final r = resolvedAt;
    return d != null && r != null && r.isAfter(d);
  }
}