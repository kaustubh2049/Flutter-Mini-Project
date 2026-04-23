import 'package:supabase_flutter/supabase_flutter.dart';

import 'property_service.dart';

class PlanInfo {
  final String type;
  final String label;
  final int? listingLimit;

  const PlanInfo({
    required this.type,
    required this.label,
    required this.listingLimit,
  });

  bool get isUnlimited => listingLimit == null;
}

class PlanUsage {
  final PlanInfo plan;
  final int activeListingCount;

  const PlanUsage({
    required this.plan,
    required this.activeListingCount,
  });

  bool get canCreateMore {
    final limit = plan.listingLimit;
    if (limit == null) return true;
    return activeListingCount < limit;
  }

  int get remainingListings {
    final limit = plan.listingLimit;
    if (limit == null) return -1;
    final remaining = limit - activeListingCount;
    return remaining < 0 ? 0 : remaining;
  }
}

class MonetizationService {
  MonetizationService._();
  static final instance = MonetizationService._();

  final SupabaseClient _db = Supabase.instance.client;

  static const Map<String, PlanInfo> _plans = {
    'free': PlanInfo(type: 'free', label: 'Free', listingLimit: 3),
    'pro': PlanInfo(type: 'pro', label: 'Pro', listingLimit: 25),
    'elite': PlanInfo(type: 'elite', label: 'Elite', listingLimit: null),
  };

  PlanInfo getPlanInfo(String? planType) {
    final normalized = _normalizePlan(planType);
    return _plans[normalized]!;
  }

  Future<String> getCurrentPlanType() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return 'free';

    try {
      final row = await _db
          .from('profiles')
          .select('plan_type')
          .eq('id', uid)
          .maybeSingle();

      return _normalizePlan(row?['plan_type']?.toString());
    } on PostgrestException catch (e) {
      if (_isMissingColumnError(e, 'plan_type')) {
        return 'free';
      }
      rethrow;
    }
  }

  Future<PlanUsage> getPlanUsage() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      return PlanUsage(plan: _plans['free']!, activeListingCount: 0);
    }

    final planType = await getCurrentPlanType();
    final activeListings = await _db
        .from('properties')
        .select('id')
        .eq('owner_id', uid)
        .eq('is_active', true);

    return PlanUsage(
      plan: getPlanInfo(planType),
      activeListingCount: (activeListings as List).length,
    );
  }

  Future<bool> canCreateListing() async {
    final usage = await getPlanUsage();
    return usage.canCreateMore;
  }

  Future<void> boostListing(
    String propertyId, {
    Duration duration = const Duration(days: 7),
  }) async {
    await PropertyService.instance
        .boostProperty(propertyId, duration: duration);
  }

  Future<String> createBoostPaymentIntentPlaceholder({
    required String propertyId,
  }) async {
    return 'TODO: integrate payment gateway for property $propertyId';
  }

  String _normalizePlan(String? planType) {
    final normalized = (planType ?? 'free').toLowerCase();
    if (_plans.containsKey(normalized)) return normalized;
    return 'free';
  }

  bool _isMissingColumnError(PostgrestException error, String columnName) {
    final details =
        '${error.message} ${error.details ?? ''} ${error.hint ?? ''}'
            .toLowerCase();
    return details.contains('column') &&
        details.contains(columnName.toLowerCase());
  }
}
