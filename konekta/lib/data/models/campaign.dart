// Safe parse helpers for MySQL DECIMAL/INT returned as String
num? _n(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}

int? _i(dynamic v) => _n(v)?.toInt();
double? _d(dynamic v) => _n(v)?.toDouble();

class Campaign {
  final int id;
  final int brandUserId;
  final String? brandName;
  final String? brandLogoUrl;
  final String title;
  final String? description;
  final String status;
  final num? budget;
  final num? rewardPerCreator;
  final int? targetViews;
  final int? targetLikes;
  final int? maxCreators;
  final int? approvedCount;
  final String? applicationStatus;
  final String? deliverables;
  final String? startDate;
  final String? endDate;
  final double? progress;
  final int? applicantsCount;
  final int? daysLeft;
  final bool isCompleted;
  final bool hasApplied;

  Campaign({
    required this.id,
    required this.brandUserId,
    this.brandName,
    this.brandLogoUrl,
    required this.title,
    this.description,
    required this.status,
    this.budget,
    this.rewardPerCreator,
    this.targetViews,
    this.targetLikes,
    this.maxCreators,
    this.approvedCount,
    this.applicationStatus,
    this.deliverables,
    this.startDate,
    this.endDate,
    this.progress,
    this.applicantsCount,
    this.daysLeft,
    this.isCompleted = false,
    this.hasApplied = false,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: _i(json['id']) ?? 0,
      brandUserId: _i(json['brand_user_id']) ?? 0,
      brandName: json['brand_name'] as String?,
      brandLogoUrl: json['brand_logo_url'] as String?,
      title: (json['title'] ?? '') as String,
      description: (json['brief'] ?? json['description']) as String?,
      status: (json['status'] ?? 'open') as String,
      budget: _n(json['budget']),
      rewardPerCreator: _n(json['reward_per_creator']),
      targetViews: _i(json['target_views']),
      targetLikes: _i(json['target_likes']),
      maxCreators: _i(json['max_creators']),
      approvedCount: _i(json['approved_count']),
      applicationStatus: json['application_status'] as String?,
      deliverables: json['deliverables'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] ?? json['deadline'] as String?,
      progress: _d(json['progress']),
      applicantsCount: _i(json['applicants_count']),
      daysLeft: _i(json['days_left']),
      isCompleted: (json['is_completed'] ?? false) == true,
      hasApplied: (json['has_applied'] ?? false) == true ||
          json['application_status'] != null,
    );
  }

  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isCompletedStatus => status == 'completed' || isCompleted;

  /// True if campaign has a slot limit AND it's been filled
  bool get isFull {
    final max = maxCreators ?? 0;
    if (max <= 0) return false;
    return (approvedCount ?? 0) >= max;
  }

  /// Remaining slots, null if unlimited
  int? get slotsLeft {
    final max = maxCreators ?? 0;
    if (max <= 0) return null;
    return (max - (approvedCount ?? 0)).clamp(0, max);
  }
}
