import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inquiry.dart';
import '../models/property.dart';
import 'storage_service.dart';

class PropertyService {
  PropertyService._();
  static final instance = PropertyService._();

  final _db = Supabase.instance.client;
  final _storage = StorageService.instance;

  // ── Fetch home feed (excludes own listings) ──────────────────────────────
  Future<List<Property>> fetchFeed({
    String? listingType, // 'Rent' | 'Buy' | null = both
    String? city,
    int limit = 30,
  }) async {
    final uid = _db.auth.currentUser?.id;

    var query = _db.from('properties').select('*, owner:profiles(plan_type)').eq('is_active', true);

    // Exclude own posts
    if (uid != null) {
      query = query.neq('owner_id', uid);
    }

    if (listingType != null) {
      query = query.eq('listing_type', listingType);
    }

    if (city != null && city.isNotEmpty) {
      query = query.ilike('city', '%$city%');
    }

    final data = await query
        .order('is_boosted', ascending: false)
        .order('posted_at', ascending: false)
        .limit(limit);

    final properties = (data as List).map((m) => Property.fromMap(m)).toList();
    _sortByPlanPriority(properties);
    return properties;
  }

  // ── Fetch featured (is_featured = true, exclude own) ────────────────────
  Future<List<Property>> fetchFeatured() async {
    final uid = _db.auth.currentUser?.id;

    var query = _db
        .from('properties')
        .select('*, owner:profiles(plan_type)')
        .eq('is_featured', true)
        .eq('is_active', true);

    if (uid != null) query = query.neq('owner_id', uid);

    final data = await query
        .order('is_boosted', ascending: false)
        .order('posted_at', ascending: false)
        .limit(8);
    final properties = (data as List).map((m) => Property.fromMap(m)).toList();
    _sortByPlanPriority(properties);
    return properties.take(5).toList();
  }

  // ── Fetch seller's own listings ──────────────────────────────────────────
  Future<List<Property>> fetchMyListings() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];

    final data = await _db
        .from('properties')
        .select('*, owner:profiles(plan_type)')
        .eq('owner_id', uid)
        .order('posted_at', ascending: false);

    final properties = (data as List).map((m) => Property.fromMap(m)).toList();
    _sortByPlanPriority(properties);
    return properties;
  }

  Future<void> boostProperty(
    String propertyId, {
    Duration duration = const Duration(days: 7),
  }) async {
    final row = await _db
        .from('properties')
        .select('boost_expiry')
        .eq('id', propertyId)
        .maybeSingle();

    var start = DateTime.now();
    final currentExpiry = row?['boost_expiry'];
    if (currentExpiry != null) {
      final parsed = DateTime.tryParse(currentExpiry.toString());
      if (parsed != null && parsed.isAfter(start)) {
        start = parsed;
      }
    }

    await _db.from('properties').update({
      'is_boosted': true,
      'boost_expiry': start.add(duration).toIso8601String(),
    }).eq('id', propertyId);
  }

  Future<void> clearBoost(String propertyId) async {
    await _db.from('properties').update({
      'is_boosted': false,
      'boost_expiry': null,
    }).eq('id', propertyId);
  }

  void _sortByPlanPriority(List<Property> properties) {
    properties.sort((a, b) {
      // Priority: Elite (3) > Pro (2) > Free (1)
      final aPriority = _getPriority(a.ownerPlanType);
      final bPriority = _getPriority(b.ownerPlanType);
      
      if (bPriority != aPriority) {
        return bPriority.compareTo(aPriority); // Higher priority first
      }
      
      // Secondary sort: Recency
      return b.postedAt.compareTo(a.postedAt);
    });
  }

  int _getPriority(String planType) {
    switch (planType.toLowerCase()) {
      case 'elite': return 3;
      case 'pro': return 2;
      default: return 1;
    }
  }

  // ── Add a new property (with image upload) ───────────────────────────────
  Future<Property> addProperty({
    required String title,
    required String type,
    required String listingType,
    required double price,
    int? bhk,
    double? area,
    required String locality,
    required String city,
    String? state,
    String? floor,
    String? description,
    List<String> amenities = const [],
    List<File> images = const [],
    String? ownerName,
    String? ownerPhone,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    // Upload images first
    final imageUrls = <String>[];
    for (final file in images) {
      final url = await _storage.uploadPropertyImage(
        file: file,
        ownerUid: uid,
      );
      imageUrls.add(url);
    }

    final profile = await _db
        .from('profiles')
        .select('name, phone')
        .eq('id', uid)
        .maybeSingle();

    final row = {
      'owner_id': uid,
      'title': title,
      'type': type,
      'listing_type': listingType,
      'price': price,
      'bhk': bhk,
      'area': area,
      'locality': locality,
      'city': city,
      'state': state,
      'floor': floor,
      'description': description,
      'amenities': amenities,
      'image_urls': imageUrls,
      'owner_name': ownerName ?? profile?['name'] ?? '',
      'owner_phone': ownerPhone ?? profile?['phone'] ?? '',
      'is_active': true,
      'is_featured': false,
      'is_verified': false,
    };

    final result = await _db.from('properties').insert(row).select().single();

    return Property.fromMap(result);
  }

  // ── Deactivate / delete own listing ─────────────────────────────────────
  Future<void> deactivateProperty(String propertyId) async {
    await _db
        .from('properties')
        .update({'is_active': false}).eq('id', propertyId);
  }

  // ── Express interest ─────────────────────────────────────────────────────
  Future<void> expressInterest(String propertyId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;

    final profile = await _db
        .from('profiles')
        .select('name, phone, email')
        .eq('id', uid)
        .maybeSingle();

    await _db.from('property_interests').upsert({
      'property_id': propertyId,
      'user_id': uid,
      'user_name':
          profile?['name'] ?? _db.auth.currentUser?.userMetadata?['name'] ?? '',
      'user_phone': profile?['phone'] ?? '',
      'user_email': profile?['email'] ?? _db.auth.currentUser?.email ?? '',
    }, onConflict: 'property_id,user_id');
  }

  // ── Count interests on a property ────────────────────────────────────────
  Future<int> getInterestCount(String propertyId) async {
    final result = await _db
        .from('property_interests')
        .select('id')
        .eq('property_id', propertyId);
    return (result as List).length;
  }

  Future<bool> isInterested(String propertyId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return false;
    final result = await _db
        .from('property_interests')
        .select('id')
        .eq('property_id', propertyId)
        .eq('user_id', uid)
        .maybeSingle();
    return result != null;
  }

  // ── Request a visit (buyer side) ─────────────────────────────────────────
  Future<void> requestVisit(String propertyId,
      {DateTime? appointmentAt}) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;

    final profile = await _db
        .from('profiles')
        .select('name, phone, email')
        .eq('id', uid)
        .maybeSingle();

    await _db.from('visit_requests').upsert({
      'property_id': propertyId,
      'user_id': uid,
      'user_name':
          profile?['name'] ?? _db.auth.currentUser?.userMetadata?['name'] ?? '',
      'user_phone': profile?['phone'] ?? '',
      'user_email': profile?['email'] ?? _db.auth.currentUser?.email ?? '',
      'appointment_at': appointmentAt?.toIso8601String(),
    }, onConflict: 'property_id,user_id');
  }

  // ── Check if current user already requested a visit ──────────────────────
  Future<bool> isVisitRequested(String propertyId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return false;
    final result = await _db
        .from('visit_requests')
        .select('id')
        .eq('property_id', propertyId)
        .eq('user_id', uid)
        .maybeSingle();
    return result != null;
  }

  // ── Fetch all visit requests & interests for a property (seller view) ────
  Future<List<Inquiry>> fetchPropertyInquiries(String propertyId) async {
    final visitsData =
        await _db.from('visit_requests').select().eq('property_id', propertyId);

    final interestsData = await _db
        .from('property_interests')
        .select()
        .eq('property_id', propertyId);

    final visits = (visitsData as List)
        .map((m) => Inquiry.fromMap(m, InquiryType.visit))
        .toList();

    final interests = (interestsData as List)
        .map((m) => Inquiry.fromMap(m, InquiryType.interest))
        .toList();

    final all = [...visits, ...interests];
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return all;
  }

  // ── Save / bookmark a property ───────────────────────────────────────────
  Future<void> saveProperty(String propertyId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db.from('saved_properties').upsert({
      'user_id': uid,
      'property_id': propertyId,
    }, onConflict: 'user_id,property_id');
  }

  Future<void> unsaveProperty(String propertyId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db
        .from('saved_properties')
        .delete()
        .eq('user_id', uid)
        .eq('property_id', propertyId);
  }

  Future<bool> isSaved(String propertyId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return false;
    final result = await _db
        .from('saved_properties')
        .select('id')
        .eq('user_id', uid)
        .eq('property_id', propertyId)
        .maybeSingle();
    return result != null;
  }

  // ── Fetch all saved/bookmarked properties ────────────────────────────────
  Future<List<Property>> fetchSavedProperties() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];

    // Join saved_properties → properties
    final data = await _db
        .from('saved_properties')
        .select('properties(*, owner:profiles(plan_type))')
        .eq('user_id', uid)
        .order('saved_at', ascending: false);

    return (data as List)
        .map((row) =>
            Property.fromMap(row['properties'] as Map<String, dynamic>))
        .toList();
  }
}
