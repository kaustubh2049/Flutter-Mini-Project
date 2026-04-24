import 'package:supabase_flutter/supabase_flutter.dart';

import 'property_service.dart';
import 'wallet_service.dart';

class PlanInfo {
  final String type;
  final String label;
  final int? listingLimit;
  final double price;

  const PlanInfo({
    required this.type,
    required this.label,
    required this.listingLimit,
    required this.price,
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

  static const double BOOST_PRICE = 199.0;
  static const double VERIFICATION_PRICE = 200.0;

  static const Map<String, PlanInfo> _plans = {
    'free': PlanInfo(type: 'free', label: 'Free', listingLimit: 3, price: 0),
    'pro': PlanInfo(type: 'pro', label: 'Pro', listingLimit: 10, price: 499),
    'elite': PlanInfo(type: 'elite', label: 'Elite', listingLimit: null, price: 999),
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
    // 1. Deduct from wallet
    await WalletService.instance.deductMoney(BOOST_PRICE, 'boost');

    // 2. Perform boost
    await PropertyService.instance
        .boostProperty(propertyId, duration: duration);
  }

  Future<void> upgradePlan(String planType) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('Please log in');

    final plan = _plans[planType.toLowerCase()];
    if (plan == null) throw Exception('Invalid plan type');

    // 1. Deduct from wallet
    if (plan.price > 0) {
      await WalletService.instance.deductMoney(plan.price, 'subscription');
    }

    // 2. Upsert profile (Update if exists, Insert if missing)
    try {
      await _db.from('profiles').upsert({
        'id': uid,
        'email': _db.auth.currentUser?.email,
        'plan_type': plan.type,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Could not update your plan: $e');
    }
  }

  List<PlanInfo> getAllPlans() => _plans.values.where((p) => p.type != 'free').toList();

  Future<String> createBoostPaymentIntentPlaceholder({
    required String propertyId,
  }) async {
    return '₹$BOOST_PRICE will be deducted from your wallet';
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
