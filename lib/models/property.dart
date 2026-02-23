class Property {
  final String id;
  final String? ownerId;   // Supabase auth user id of the poster
  final String title;
  final String type;
  final String listingType; // 'Rent' | 'Buy'
  final int? bhk;
  final double price;
  final double? area;
  final String locality;
  final String city;
  final String? state;
  final String? floor;
  final String? description;
  final List<String> amenities;
  final List<String> imageUrls;
  final String ownerName;
  final String ownerPhone;
  final bool isVerified;
  final bool isFeatured;
  final bool isActive;
  final DateTime postedAt;

  const Property({
    required this.id,
    this.ownerId,
    required this.title,
    required this.type,
    required this.listingType,
    this.bhk,
    required this.price,
    this.area,
    required this.locality,
    required this.city,
    this.state,
    this.floor,
    this.description,
    this.amenities = const [],
    this.imageUrls = const [],
    required this.ownerName,
    required this.ownerPhone,
    this.isVerified = false,
    this.isFeatured = false,
    this.isActive = true,
    required this.postedAt,
  });

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'] ?? '',
      ownerId: map['owner_id'],
      title: map['title'] ?? '',
      type: map['type'] ?? 'Apartment',
      listingType: map['listing_type'] ?? 'Rent',
      bhk: map['bhk'],
      price: (map['price'] as num).toDouble(),
      area: map['area'] != null ? (map['area'] as num).toDouble() : null,
      locality: map['locality'] ?? '',
      city: map['city'] ?? '',
      state: map['state'],
      floor: map['floor'],
      description: map['description'],
      amenities: List<String>.from(map['amenities'] ?? []),
      imageUrls: List<String>.from(map['image_urls'] ?? []),
      ownerName: map['owner_name'] ?? '',
      ownerPhone: map['owner_phone'] ?? '',
      isVerified: map['is_verified'] ?? false,
      isFeatured: map['is_featured'] ?? false,
      isActive: map['is_active'] ?? true,
      postedAt: DateTime.parse(
        map['posted_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

// ─── Mock Data (replace with Supabase query once listings are posted) ──────────
final List<Property> mockFeaturedProperties = [
  Property(
    id: 'f1',
    title: '3 BHK Premium Apartment',
    type: 'Apartment',
    listingType: 'Rent',
    bhk: 3,
    price: 55000,
    area: 1680,
    locality: 'Koramangala',
    city: 'Bangalore',
    floor: '7th of 12',
    description:
        'Stunning 3 BHK with modular kitchen, gym access, and covered parking in the heart of Koramangala.',
    amenities: ['Gym', 'Parking', 'Security', 'Power Backup', 'Swimming Pool'],
    imageUrls: [
      'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&q=80',
    ],
    ownerName: 'Rahul Sharma',
    ownerPhone: '9876543210',
    isVerified: true,
    isFeatured: true,
    postedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Property(
    id: 'f2',
    title: '4 BHK Luxury Villa',
    type: 'Villa',
    listingType: 'Buy',
    bhk: 4,
    price: 8500000,
    area: 3200,
    locality: 'Whitefield',
    city: 'Bangalore',
    floor: 'Ground + 1',
    description:
        'Spacious villa with private garden, modular kitchen, and premium fittings.',
    amenities: ['Garden', 'Parking', 'Security', 'Club House'],
    imageUrls: [
      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80',
    ],
    ownerName: 'Priya Reddy',
    ownerPhone: '9845678901',
    isVerified: true,
    isFeatured: true,
    postedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Property(
    id: 'f3',
    title: '2 BHK Sea-View Flat',
    type: 'Apartment',
    listingType: 'Rent',
    bhk: 2,
    price: 45000,
    area: 1100,
    locality: 'Bandra West',
    city: 'Mumbai',
    floor: '9th of 14',
    amenities: ['Sea View', 'Parking', 'Security'],
    imageUrls: [
      'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&q=80',
    ],
    ownerName: 'Arjun Mehta',
    ownerPhone: '9988776655',
    isVerified: true,
    isFeatured: true,
    postedAt: DateTime.now().subtract(const Duration(hours: 12)),
  ),
];

final List<Property> mockRecentProperties = [
  Property(
    id: 'r1',
    title: '2 BHK Apartment',
    type: 'Apartment',
    listingType: 'Rent',
    bhk: 2,
    price: 22000,
    area: 950,
    locality: 'HSR Layout',
    city: 'Bangalore',
    floor: '3rd of 6',
    amenities: ['Parking', 'Security'],
    imageUrls: [
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&q=80',
    ],
    ownerName: 'Amit Kumar',
    ownerPhone: '9123456789',
    isVerified: false,
    postedAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  Property(
    id: 'r2',
    title: '1 BHK Studio',
    type: 'Apartment',
    listingType: 'Rent',
    bhk: 1,
    price: 12000,
    area: 550,
    locality: 'Indiranagar',
    city: 'Bangalore',
    floor: '2nd of 4',
    amenities: ['Furnished', 'WiFi'],
    imageUrls: [
      'https://images.unsplash.com/photo-1536376072261-38c75010e6c9?w=800&q=80',
    ],
    ownerName: 'Suresh Nair',
    ownerPhone: '9234567890',
    isVerified: true,
    postedAt: DateTime.now().subtract(const Duration(hours: 8)),
  ),
  Property(
    id: 'r3',
    title: '3 BHK Builder Floor',
    type: 'House',
    listingType: 'Buy',
    bhk: 3,
    price: 5500000,
    area: 1600,
    locality: 'Sector 62',
    city: 'Noida',
    floor: 'Ground',
    amenities: ['Parking', 'Garden'],
    imageUrls: [
      'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800&q=80',
    ],
    ownerName: 'Deepak Gupta',
    ownerPhone: '9345678901',
    isVerified: true,
    postedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Property(
    id: 'r4',
    title: 'PG for Girls',
    type: 'PG',
    listingType: 'Rent',
    bhk: null,
    price: 8000,
    area: null,
    locality: 'Marathahalli',
    city: 'Bangalore',
    floor: '1st of 3',
    amenities: ['Meals Included', 'WiFi', 'Security'],
    imageUrls: [
      'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=800&q=80',
    ],
    ownerName: 'Kavitha Rao',
    ownerPhone: '9456789012',
    isVerified: false,
    postedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
];
