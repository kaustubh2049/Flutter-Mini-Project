import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/monetization_service.dart';

final monetizationServiceProvider =
    Provider<MonetizationService>((ref) => MonetizationService.instance);

final planUsageProvider = FutureProvider<PlanUsage>(
  (ref) => ref.read(monetizationServiceProvider).getPlanUsage(),
);
