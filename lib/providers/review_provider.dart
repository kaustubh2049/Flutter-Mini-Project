import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/review_service.dart';

// ── Reviews for a property ─────────────────────────────────────────────────
final propertyReviewsProvider =
    FutureProvider.family<List<Review>, String>(
  (ref, propertyId) => ReviewService.instance.fetchReviews(propertyId),
);

// ── Average rating for a property ──────────────────────────────────────────
final averageRatingProvider = FutureProvider.family<double, String>(
  (ref, propertyId) => ReviewService.instance.getAverageRating(propertyId),
);
