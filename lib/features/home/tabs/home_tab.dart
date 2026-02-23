import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _activeCategoryIndex = 0;
  final _searchCtrl = TextEditingController();

  static const _categories = [
    ('apartment', 'Real Estate'),
    ('home', 'House'),
    ('storefront', 'Commercial'),
    ('villa', 'Plots'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Sticky Header + Search ─────────────────────────────────────
        _buildHeader(),
        _buildSearchBar(),

        // ── Scrollable Body ────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              _buildCategories(),
              _buildFeaturedSection(),
              _buildRecentlyViewed(),
              _buildNewListings(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          // Location
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.accent, size: 24),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Location',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Gurgaon, India',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.expand_more,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Notification
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search city, locality or builder',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 24,
              color: AppColors.border,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: () {},
                child: const Icon(
                  Icons.tune,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Chips ─────────────────────────────────────────────────────────
  Widget _buildCategories() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final isActive = _activeCategoryIndex == i;
          final cat = _categories[i];
          return GestureDetector(
            onTap: () => setState(() => _activeCategoryIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(100),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _catIcon(cat.$1),
                    size: 18,
                    color: isActive
                        ? Colors.white
                        : AppColors.textPrimary.withOpacity(0.75),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.$2,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? Colors.white
                          : AppColors.textPrimary.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _catIcon(String name) {
    switch (name) {
      case 'apartment':
        return Icons.apartment_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'storefront':
        return Icons.storefront_rounded;
      case 'villa':
        return Icons.villa_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  // ── Featured Section (full-width card with overlay) ────────────────────────
  Widget _buildFeaturedSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Featured Card
          _FeaturedCard(
            imageUrl:
                'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&q=80',
            price: '₹1.2 Cr',
            title: 'DLF The Camellias',
            location: 'Sector 42, Gurgaon',
          ),
        ],
      ),
    );
  }

  // ── Recently Viewed Carousel ───────────────────────────────────────────────
  Widget _buildRecentlyViewed() {
    const cards = [
      _RecentCard(
        imageUrl:
            'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=400&q=80',
        price: '₹85 L',
        title: '3 BHK Apartment',
        location: 'Sec 56, Gurgaon',
      ),
      _RecentCard(
        imageUrl:
            'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=400&q=80',
        price: '₹2.5 Cr',
        title: '4 BHK Villa',
        location: 'Golf Course Rd',
      ),
      _RecentCard(
        imageUrl:
            'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=400&q=80',
        price: '₹65 L',
        title: '2 BHK Flat',
        location: 'Sohna Road',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            'Recently Viewed',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) => cards[i],
          ),
        ),
      ],
    );
  }

  // ── New Listings Vertical List ─────────────────────────────────────────────
  Widget _buildNewListings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New Listings',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Sort by ',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Newest',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.sort,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Listing items
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: const [
              _ListingItem(
                imageUrl:
                    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400&q=80',
                price: '₹95 L',
                spec: '3 BHK • 1850 sq.ft',
                location: 'Emaar Palm Gardens, Sec 83',
                badge: 'New',
                badgeColor: AppColors.primary,
                tags: ['Ready to Move', 'Furnished'],
              ),
              SizedBox(height: 14),
              _ListingItem(
                imageUrl:
                    'https://images.unsplash.com/photo-1536376072261-38c75010e6c9?w=400&q=80',
                price: '₹1.5 Cr',
                spec: '4 BHK • 2400 sq.ft',
                location: 'Godrej Meridien, Sec 106',
                badge: 'Verified',
                badgeColor: AppColors.success,
                tags: ['Under Construction'],
              ),
              SizedBox(height: 14),
              _ListingItem(
                imageUrl:
                    'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=400&q=80',
                price: '₹45 L',
                spec: '2 BHK • 1100 sq.ft',
                location: 'Tulip Violet, Sec 69',
                badge: null,
                badgeColor: null,
                tags: ['Resale'],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Featured Card ─────────────────────────────────────────────────────────────
class _FeaturedCard extends StatefulWidget {
  final String imageUrl;
  final String price;
  final String title;
  final String location;

  const _FeaturedCard({
    required this.imageUrl,
    required this.price,
    required this.title,
    required this.location,
  });

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 256,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceAlt,
                child: const Icon(Icons.home, size: 60, color: AppColors.textHint),
              ),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),

            // Premium badge (top left)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PREMIUM',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),

            // Save button (top right)
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => setState(() => _saved = !_saved),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),

            // Bottom info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.price,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.88),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          widget.location,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recently Viewed Card ──────────────────────────────────────────────────────
class _RecentCard extends StatelessWidget {
  final String imageUrl;
  final String price;
  final String title;
  final String location;

  const _RecentCard({
    required this.imageUrl,
    required this.price,
    required this.title,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: Image.network(
              imageUrl,
              height: 120,
              width: 190,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                color: AppColors.surfaceAlt,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: AppColors.textHint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── New Listing Row Item ──────────────────────────────────────────────────────
class _ListingItem extends StatefulWidget {
  final String imageUrl;
  final String price;
  final String spec;
  final String location;
  final String? badge;
  final Color? badgeColor;
  final List<String> tags;

  const _ListingItem({
    required this.imageUrl,
    required this.price,
    required this.spec,
    required this.location,
    required this.badge,
    required this.badgeColor,
    required this.tags,
  });

  @override
  State<_ListingItem> createState() => _ListingItemState();
}

class _ListingItemState extends State<_ListingItem> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.network(
                  widget.imageUrl,
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 110,
                    height: 110,
                    color: AppColors.surfaceAlt,
                  ),
                ),
                if (widget.badge != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.badge!,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.price,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _saved = !_saved),
                      child: Icon(
                        _saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: _saved
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.spec,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.location,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: widget.tags
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            t,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
