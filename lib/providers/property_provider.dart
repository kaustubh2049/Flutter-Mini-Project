import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/property.dart';
import '../services/property_service.dart';

// ── Home feed (excludes own, optionally filtered by city) ─────────────────────
final homeFeedProvider = FutureProvider.family<List<Property>, String?>(
  (ref, city) => PropertyService.instance.fetchFeed(city: city),
);

// ── Featured listings ─────────────────────────────────────────────────────────
final featuredProvider = FutureProvider<List<Property>>(
  (ref) => PropertyService.instance.fetchFeatured(),
);

// ── My listings (seller view) ─────────────────────────────────────────────────
final myListingsProvider = FutureProvider<List<Property>>(
  (ref) => PropertyService.instance.fetchMyListings(),
);

// ── Saved properties (buyer bookmarks) ────────────────────────────────────────
final savedPropertiesProvider = FutureProvider<List<Property>>(
  (ref) => PropertyService.instance.fetchSavedProperties(),
);

// ── Saved IDs set — fast lookup for bookmark icon state ──────────────────────
final savedIdsProvider = FutureProvider<Set<String>>(
  (ref) async {
    final saved = await PropertyService.instance.fetchSavedProperties();
    return saved.map((p) => p.id).toSet();
  },
);
