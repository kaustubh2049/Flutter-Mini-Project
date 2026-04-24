import 'package:supabase_flutter/supabase_flutter.dart';

class Review {
  final String id;
  final String propertyId;
  final String userId;
  final int rating;
  final String? comment;
  final String userName;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.userName,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    // userName comes from the joined profiles table
    final profile = map['profiles'] as Map<String, dynamic>?;
    return Review(
      id: map['id'].toString(),
      propertyId: map['property_id'] ?? '',
      userId: map['user_id'] ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment'],
      userName: profile?['name'] ?? 'Anonymous',
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class ReviewService {
  ReviewService._();
  static final instance = ReviewService._();

  final _db = Supabase.instance.client;

  /// Fetch all reviews for a property, newest first
  Future<List<Review>> fetchReviews(String propertyId) async {
    final data = await _db
        .from('property_reviews')
        .select('*, profiles(name)')
        .eq('property_id', propertyId)
        .order('created_at', ascending: false);

    return (data as List).map((m) => Review.fromMap(m)).toList();
  }

  /// Calculate average rating for a property
  Future<double> getAverageRating(String propertyId) async {
    final reviews = await fetchReviews(propertyId);
    if (reviews.isEmpty) return 0;
    final total = reviews.fold<int>(0, (sum, r) => sum + r.rating);
    return total / reviews.length;
  }

  /// Submit a review (one review per user per property)
  Future<void> addReview({
    required String propertyId,
    required int rating,
    String? comment,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    // Check if user already reviewed
    final existing = await _db
        .from('property_reviews')
        .select('id')
        .eq('property_id', propertyId)
        .eq('user_id', uid)
        .maybeSingle();

    if (existing != null) {
      // Update existing review
      await _db.from('property_reviews').update({
        'rating': rating,
        'comment': comment,
      }).eq('id', existing['id']);
    } else {
      // Insert new review
      await _db.from('property_reviews').insert({
        'property_id': propertyId,
        'user_id': uid,
        'rating': rating,
        'comment': comment,
      });
    }
  }

  /// Check if current user already reviewed this property
  Future<bool> hasReviewed(String propertyId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return false;
    final result = await _db
        .from('property_reviews')
        .select('id')
        .eq('property_id', propertyId)
        .eq('user_id', uid)
        .maybeSingle();
    return result != null;
  }
}
