// Values below come from the Swagger enums. If the backend adds more,
// update these lists (kPriorities: only LOW was visible, verify the rest).
const kDepartments = [
  'SANITATION',
  'WATER_SUPPLY',
  'PUBLIC_WORKS',
  'STREET_LIGHT',
  'PUBLIC_SAFETY',
  'ANIMAL_CONTROL',
  'HEALTH',
  'REVENUE',
  'OTHER',
];

const kStatuses = [
  'PENDING_VERIFICATION',
  'VERIFIED',
  'IN_PROGRESS',
  'RESOLVED',
  'CLOSED',
  'REJECTED',
];

const kPriorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

class AdminStats {
  final int totalComplaints;
  final int resolved;
  final int pending;
  final int inProgress;
  final int rejected;
  final double avgResolutionTimeHours;
  final Map<String, int> categoryCounts;

  const AdminStats({
    required this.totalComplaints,
    required this.resolved,
    required this.pending,
    required this.inProgress,
    required this.rejected,
    required this.avgResolutionTimeHours,
    required this.categoryCounts,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
    totalComplaints: _int(j['totalComplaints']),
    resolved: _int(j['resolved']),
    pending: _int(j['pending']),
    inProgress: _int(j['inProgress']),
    rejected: _int(j['rejected']),
    avgResolutionTimeHours:
    (j['avgResolutionTimeHours'] as num?)?.toDouble() ?? 0,
    categoryCounts: ((j['categoryCounts'] as Map?) ?? {})
        .map((k, v) => MapEntry(k.toString(), _int(v))),
  );
}

class SlaRule {
  final int id;
  final int categoryId;
  final String categoryName;
  final String department;
  final String priority;
  final int durationHours;

  const SlaRule({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.department,
    required this.priority,
    required this.durationHours,
  });

  factory SlaRule.fromJson(Map<String, dynamic> j) {
    final c = (j['category'] as Map?) ?? {};
    return SlaRule(
      id: _int(j['id']),
      categoryId: _int(c['id']),
      categoryName: (c['name'] ?? '').toString(),
      department: (c['defaultDepartment'] ?? '').toString(),
      priority: (j['priority'] ?? '').toString(),
      durationHours: _int(j['durationHours']),
    );
  }
}

class CategoryOption {
  final int id;
  final String name;
  const CategoryOption(this.id, this.name);

  factory CategoryOption.fromJson(Map<String, dynamic> j) =>
      CategoryOption(_int(j['id']), (j['name'] ?? '').toString());
}

class AdminComplaint {
  final int id;
  final String title;
  final String description;
  final String categoryName;
  final String address;
  final String city;
  final String ward;
  final String department;
  final String priority;
  final String status;
  final String citizenName;
  final String assignedAuthorityName;
  final String rejectionReason;
  final String resolutionNote;
  final int upvoteCount;
  final DateTime? createdAt;

  const AdminComplaint({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryName,
    required this.address,
    required this.city,
    required this.ward,
    required this.department,
    required this.priority,
    required this.status,
    required this.citizenName,
    required this.assignedAuthorityName,
    required this.rejectionReason,
    required this.resolutionNote,
    required this.upvoteCount,
    required this.createdAt,
  });

  factory AdminComplaint.fromJson(Map<String, dynamic> j) {
    String s(String k) => (j[k] ?? '').toString();
    return AdminComplaint(
      id: _int(j['id']),
      title: s('title'),
      description: s('description'),
      categoryName: s('categoryName'),
      address: s('address'),
      city: s('city'),
      ward: s('ward'),
      department: s('department'),
      priority: s('priority'),
      status: s('status'),
      citizenName: s('citizenName'),
      assignedAuthorityName: s('assignedAuthorityName'),
      rejectionReason: s('rejectionReason'),
      resolutionNote: s('resolutionNote'),
      upvoteCount: _int(j['upvoteCount']),
      createdAt: DateTime.tryParse(s('createdAt'))?.toLocal(),
    );
  }
}

class AdminComplaintPage {
  final List<AdminComplaint> content;
  final int totalPages;
  final int totalElements;

  const AdminComplaintPage({
    required this.content,
    required this.totalPages,
    required this.totalElements,
  });

  factory AdminComplaintPage.fromJson(Map<String, dynamic> j) =>
      AdminComplaintPage(
        content: ((j['content'] as List?) ?? [])
            .map((e) => AdminComplaint.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        totalPages: _int(j['totalPages']),
        totalElements: _int(j['totalElements']),
      );
}