import '../../core/api_client.dart';
import '../models/subscription.dart';

class SubscriptionRepository {
  final ApiClient _api;
  SubscriptionRepository(this._api);

  Future<List<SubscriptionPlan>> listPlans() async {
    final res = await _api.get('/subscriptions/plans');
    if (res == null) return const [];
    final raw = (res is List)
        ? res
        : ((res as Map)['items'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => SubscriptionPlan.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Returns the current brand subscription (with denormalized plan_name).
  /// `null` if the user has no subscription yet.
  Future<Subscription?> current() async {
    try {
      final res = await _api.get('/subscriptions/me');
      if (res == null) return null;
      final map = (res is Map) ? Map<String, dynamic>.from(res) : null;
      if (map == null) return null;
      return Subscription.fromJson(map);
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  Future<Subscription> subscribe(int planId) async {
    final res = await _api.post('/subscriptions/subscribe', {'plan_id': planId});
    return Subscription.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<Subscription> cancel() async {
    final res = await _api.post('/subscriptions/cancel', const {});
    return Subscription.fromJson(Map<String, dynamic>.from(res as Map));
  }

  // ── Aliases ────────────────────────────────────────────────────────────
  // Older screens (e.g. subscription_screen.dart) call these names.
  // They are kept here as thin wrappers so the screen-level code keeps
  // compiling even if a future refactor renames the canonical method.

  /// Alias of [listPlans].
  Future<List<SubscriptionPlan>> plans() => listPlans();

  /// Alias of [current]. Kept for screens that prefer the noun `me`.
  Future<Subscription?> me() => current();

  /// Variant of [me] that deserializes the full nested `UserSubscription`
  /// (with the `plan` sub-object). The profile screens need the nested
  /// `plan.name` / `plan.price` fields, while the brand onboarding flow
  /// only needs the denormalized [Subscription] summary.
  Future<UserSubscription?> meDetailed() async {
    try {
      final res = await _api.get('/subscriptions/me');
      if (res == null) return null;
      final map = (res is Map) ? Map<String, dynamic>.from(res) : null;
      if (map == null) return null;
      // Backend may return either shape (with or without nested `plan`).
      // If the nested plan is absent, build a synthetic one from the
      // denormalized fields so the typed model still parses.
      if (map['plan'] is! Map && (map['plan_name'] != null || map['plan_id'] != null)) {
        map['plan'] = {
          'id': map['plan_id'],
          'name': map['plan_name'] ?? map['name'] ?? 'Plan',
          'price': map['price'] ?? 0,
          'currency': map['currency'] ?? 'IDR',
          'interval': map['interval'] ?? 'monthly',
          'features': map['features'] is List ? map['features'] : const [],
        };
      }
      return UserSubscription.fromJson(map);
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  /// Alias of [subscribe]. The brand onboarding flow calls this `checkout`.
  Future<Subscription> checkout(int planId) => subscribe(planId);
}
