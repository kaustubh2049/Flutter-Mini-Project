import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/verification_request.dart';
import '../services/verification_service.dart';

final verificationServiceProvider =
    Provider<VerificationService>((ref) => VerificationService.instance);

final myVerificationRequestsProvider =
    FutureProvider<List<VerificationRequest>>(
  (ref) => ref.read(verificationServiceProvider).fetchMyRequests(),
);

final allVerificationRequestsProvider =
    FutureProvider<List<VerificationRequest>>(
  (ref) => ref.read(verificationServiceProvider).fetchAllRequests(),
);
