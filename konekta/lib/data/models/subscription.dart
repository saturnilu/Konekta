class SubscriptionPlan {
  final int id;
  final String name;
  final num? price;
  final String? currency;
  final int? durationMonths;
  final String? description;
  final List<String> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    this.price,
    this.currency,
    this.durationMonths,
    this.description,
    this.features = const [],
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    num? _n(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(v.toString());
    }
    return SubscriptionPlan(
      id: (json['plan_id'] is num ? (json['plan_id'] as num).toInt() : null) ??
          (json['id'] is num ? (json['id'] as num).toInt() : int.tryParse('${json['id'] ?? 0}') ?? 0),
      name: (json['plan_name'] ?? json['name'] ?? '') as String,
      price: _n(json['price'] ?? json['price_idr']),
      currency: (json['currency'] ?? 'IDR') as String?,
      durationMonths: (json['duration_months'] is num) ? (json['duration_months'] as num).toInt() : null,
      description: json['description'] as String?,
      features: ((json['features'] as List?)?.map((e) => e.toString()).toList()) ?? const [],
    );
  }
}

class Subscription {
  final int? id;
  final int? planId;
  final String? planName;
  final String? status;
  final String? startedAt;
  final String? expiresAt;
  final bool autoRenew;
  final bool isActive;

  Subscription({
    this.id,
    this.planId,
    this.planName,
    this.status,
    this.startedAt,
    this.expiresAt,
    this.autoRenew = false,
    this.isActive = false,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final statusVal = (json['status'] ?? '').toString().toLowerCase();
    return Subscription(
      id: (json['id'] is num) ? (json['id'] as num).toInt() : int.tryParse('${json['id']}'),
      planId: (json['plan_id'] is num) ? (json['plan_id'] as num).toInt() : int.tryParse('${json['plan_id']}'),
      planName: (json['plan_name'] ?? json['plan_code']) as String?,
      status: json['status'] as String?,
      startedAt: json['started_at'] as String?,
      expiresAt: json['expires_at'] as String?,
      autoRenew: (json['auto_renew'] ?? false) == true,
      isActive: statusVal == 'active' || statusVal == 'trialing',
    );
  }
}

class UserSubscription {
  final int? id;
  final int? userId;
  final SubscriptionPlan? plan;
  final String? status;
  final String? startedAt;
  final String? expiresAt;
  final bool autoRenew;
  final bool isActive;

  UserSubscription({
    this.id,
    this.userId,
    this.plan,
    this.status,
    this.startedAt,
    this.expiresAt,
    this.autoRenew = false,
    this.isActive = false,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    final statusVal = (json['status'] ?? '').toString().toLowerCase();
    return UserSubscription(
      id: (json['id'] is num) ? (json['id'] as num).toInt() : int.tryParse('${json['id']}'),
      userId: (json['user_id'] is num) ? (json['user_id'] as num).toInt() : int.tryParse('${json['user_id']}'),
      plan: json['plan'] is Map
          ? SubscriptionPlan.fromJson(Map<String, dynamic>.from(json['plan'] as Map))
          : null,
      status: json['status'] as String?,
      startedAt: json['started_at'] as String?,
      expiresAt: json['expires_at'] as String?,
      autoRenew: (json['auto_renew'] ?? false) == true,
      isActive: statusVal == 'active' || statusVal == 'trialing',
    );
  }

  /// Convenience alias for `plan?.name` so screens can read
  /// `subscription.planName` without going through the nested `plan` object.
  String? get planName => plan?.name;
}
