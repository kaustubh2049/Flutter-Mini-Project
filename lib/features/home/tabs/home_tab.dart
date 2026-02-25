import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';

import '../../../models/property.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/property_provider.dart';
import '../../../services/property_service.dart';
import '../../../core/utils/format_utils.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  int _activeCategoryIndex = 0;
  final _searchCtrl = TextEditingController();
  String? _currentCity; // track so we can invalidate family provider correctly

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
    final locationAsync = ref.watch(locationProvider);

    // Update city whenever location resolves
    locationAsync.whenData((loc) => _currentCity = loc.city);

    return Column(
      children: [
        // ── Sticky Header + Search ──────────────────────────────────────
        _buildHeader(locationAsync),
        _buildSearchBar(),

        // ── Scrollable Body ─────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(locationProvider);
              // Invalidate feed by current city (family provider needs param)
              ref.invalidate(homeFeedProvider(_currentCity));
              ref.invalidate(featuredProvider);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                _buildCategories(),
                _buildFeaturedSection(),
                _buildNewListings(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(AsyncValue locationAsync) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    color: AppColors.accent, size: 24),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Your Location',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    locationAsync.when(
                      data: (loc) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            loc.display,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.expand_more,
                              size: 16, color: AppColors.textSecondary),
                        ],
                      ),
                      loading: () => Text(
                        'Detecting…',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint,
                        ),
                      ),
                      error: (_, __) => Text(
                        'Mahim, Mumbai',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Stack(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.notifications_outlined,
                    color: AppColors.textPrimary, size: 24),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.accent, shape: BoxShape.circle),
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
                    fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search city, locality or builder',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textHint),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Container(width: 1, height: 24, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: () {},
                child: const Icon(Icons.tune,
                    color: AppColors.textPrimary, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category chips ─────────────────────────────────────────────────────────
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
                  Icon(_catIcon(cat.$1),
                      size: 18,
                      color: isActive
                          ? Colors.white
                          : AppColors.textPrimary.withOpacity(0.75)),
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

  // ── Featured Section ────────────────────────────────────────────────────────
  Widget _buildFeaturedSection() {
    final featuredAsync = ref.watch(featuredProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Featured',
                  style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text('View All',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent)),
            ],
          ),
        ),
        featuredAsync.when(
          data: (props) {
            if (props.isEmpty) {
              return _buildFeaturedFallbackCard();
            }
            return SizedBox(
              height: 268,
              child: PageView.builder(
                padEnds: false,
                controller: PageController(viewportFraction: 0.9),
                itemCount: props.length,
                itemBuilder: (_, i) => Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 16 : 8,
                    right: i == props.length - 1 ? 16 : 8,
                  ),
                  child: _PropertyFeaturedCard(property: props[i]),
                ),
              ),
            );
          },
          loading: () => _buildFeaturedFallbackCard(),
          error: (_, __) => _buildFeaturedFallbackCard(),
        ),
      ],
    );
  }

  // Fallback when Supabase has no data yet
  Widget _buildFeaturedFallbackCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: _StaticFeaturedCard(
        imageUrl:
            'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&q=80',
        price: '₹1.2 Cr',
        title: 'DLF The Camellias',
        location: 'Sector 42, Gurgaon',
        badge: 'FEATURED',
      ),
    );
  }

  // ── New Listings ────────────────────────────────────────────────────────────
  Widget _buildNewListings() {
    final locationAsync = ref.watch(locationProvider);
    final city = locationAsync.valueOrNull?.city;
    final feedAsync = ref.watch(homeFeedProvider(city));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Properties Near You',
                  style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text('See All',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent)),
            ],
          ),
        ),
        feedAsync.when(
          data: (props) {
            if (props.isEmpty) return _buildMockListings();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: props
                    .take(12)
                    .map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _PropertyListItem(property: p),
                        ))
                    .toList(),
              ),
            );
          },
          loading: () => _buildMockListings(),
          error: (_, __) => _buildMockListings(),
        ),
      ],
    );
  }

  // Mock listings shown while loading or when Supabase is empty
  Widget _buildMockListings() {
    final mocks = [
      _MockListing(
        imageUrl:
            'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400&q=80',
        price: '₹95 L',
        spec: '3 BHK • 1850 sq.ft',
        location: 'Mahim, Mumbai',
        badge: 'New',
        badgeColor: AppColors.primary,
        tags: ['Ready to Move', 'Furnished'],
      ),
      _MockListing(
        imageUrl:
            'https://images.unsplash.com/photo-1536376072261-38c75010e6c9?w=400&q=80',
        price: '₹1.5 Cr',
        spec: '4 BHK • 2400 sq.ft',
        location: 'Bandra West, Mumbai',
        badge: 'Verified',
        badgeColor: AppColors.success,
        tags: ['Under Construction'],
      ),
      _MockListing(
        imageUrl:
            'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=400&q=80',
        price: '₹45 L',
        spec: '2 BHK • 1100 sq.ft',
        location: 'Worli, Mumbai',
        badge: null,
        badgeColor: null,
        tags: ['Resale'],
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: mocks
            .map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _MockListingItem(listing: m),
                ))
            .toList(),
      ),
    );
  }
}

// ── Property Featured Card (real data) ───────────────────────────────────────
class _PropertyFeaturedCard extends ConsumerStatefulWidget {
  final Property property;
  const _PropertyFeaturedCard({required this.property});

  @override
  ConsumerState<_PropertyFeaturedCard> createState() =>
      _PropertyFeaturedCardState();
}

class _PropertyFeaturedCardState extends ConsumerState<_PropertyFeaturedCard> {
  bool _saved = false;
  bool _saveLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final s = await PropertyService.instance.isSaved(widget.property.id);
    if (mounted) setState(() => _saved = s);
  }

  Future<void> _toggleSave() async {
    if (_saveLoading) return;
    setState(() => _saveLoading = true);
    try {
      if (_saved) {
        await PropertyService.instance.unsaveProperty(widget.property.id);
      } else {
        await PropertyService.instance.saveProperty(widget.property.id);
      }
      setState(() => _saved = !_saved);
      ref.invalidate(savedPropertiesProvider);
      ref.invalidate(savedIdsProvider);
    } finally {
      if (mounted) setState(() => _saveLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    final img = p.imageUrls.isNotEmpty ? p.imageUrls.first : null;

    return GestureDetector(
        onTap: () => context.push('/property-detail', extra: p),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 256,
            child: Stack(
              fit: StackFit.expand,
              children: [
                img != null
                    ? Image.network(img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
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
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.listingType.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                if (p.isVerified)
                  Positioned(
                    top: 12,
                    left: 80,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '✓ VERIFIED',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: _toggleSave,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _saved
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _saved ? Colors.red : Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
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
                          FormatUtils.formatPrice(p.price),
                          style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p.title,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.88)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 14, color: Colors.white60),
                            const SizedBox(width: 3),
                            Text(
                              '${p.locality}, ${p.city}',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: Colors.white60),
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
        ));
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceAlt,
        child: const Icon(Icons.home, size: 60, color: AppColors.textHint),
      );
}

// ── Static featured card (fallback) ──────────────────────────────────────────
class _StaticFeaturedCard extends StatefulWidget {
  final String imageUrl;
  final String price;
  final String title;
  final String location;
  final String badge;

  const _StaticFeaturedCard({
    required this.imageUrl,
    required this.price,
    required this.title,
    required this.location,
    required this.badge,
  });

  @override
  State<_StaticFeaturedCard> createState() => _StaticFeaturedCardState();
}

class _StaticFeaturedCardState extends State<_StaticFeaturedCard> {
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
            Image.network(widget.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: AppColors.surfaceAlt)),
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
                  widget.badge,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
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
                    _saved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
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
                    Text(widget.price,
                        style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 3),
                    Text(widget.title,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.88))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Colors.white60),
                        const SizedBox(width: 3),
                        Text(widget.location,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.white60)),
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

// ── Real Listing Item (from Supabase) ─────────────────────────────────────────
class _PropertyListItem extends ConsumerStatefulWidget {
  final Property property;
  const _PropertyListItem({required this.property});

  @override
  ConsumerState<_PropertyListItem> createState() => _PropertyListItemState();
}

class _PropertyListItemState extends ConsumerState<_PropertyListItem> {
  bool _saved = false;
  bool _saveLoading = false;
  bool _interested = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final s = await PropertyService.instance.isSaved(widget.property.id);
    if (mounted) setState(() => _saved = s);
  }

  Future<void> _toggleSave() async {
    if (_saveLoading) return;
    setState(() => _saveLoading = true);
    try {
      if (_saved) {
        await PropertyService.instance.unsaveProperty(widget.property.id);
      } else {
        await PropertyService.instance.saveProperty(widget.property.id);
      }
      setState(() => _saved = !_saved);
      ref.invalidate(savedPropertiesProvider);
      ref.invalidate(savedIdsProvider);
    } finally {
      if (mounted) setState(() => _saveLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    final img = p.imageUrls.isNotEmpty ? p.imageUrls.first : null;

    return GestureDetector(
        onTap: () => context.push('/property-detail', extra: p),
        child: Container(
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
                    img != null
                        ? Image.network(img,
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 110,
                                height: 110,
                                color: AppColors.surfaceAlt))
                        : Container(
                            width: 110,
                            height: 110,
                            color: AppColors.surfaceAlt,
                            child: const Icon(Icons.home,
                                size: 40, color: AppColors.textHint)),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.listingType == 'Rent'
                              ? AppColors.rent
                              : AppColors.buy,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.listingType,
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
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            FormatUtils.formatPrice(p.price),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleSave,
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
                      FormatUtils.bhkLabel(p.bhk),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.locality}, ${p.city}',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // I'm Interested button
                    GestureDetector(
                      onTap: _interested
                          ? null
                          : () async {
                              try {
                                final uid = Supabase.instance.client.auth.currentUser?.id;
                                if (uid == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please login to express interest'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }

                                await PropertyService.instance.expressInterest(p.id);
                                if (mounted) {
                                  setState(() => _interested = true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Interest sent to ${p.ownerName}!'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _interested
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: _interested
                                ? AppColors.success
                                : AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _interested ? '✓ Interested' : "I'm Interested",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _interested
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

// ─── Mock data holders & widgets ─────────────────────────────────────────────
class _MockListing {
  final String imageUrl, price, spec, location;
  final String? badge;
  final Color? badgeColor;
  final List<String> tags;

  const _MockListing({
    required this.imageUrl,
    required this.price,
    required this.spec,
    required this.location,
    this.badge,
    this.badgeColor,
    required this.tags,
  });
}

class _MockListingItem extends StatefulWidget {
  final _MockListing listing;
  const _MockListingItem({required this.listing});

  @override
  State<_MockListingItem> createState() => _MockListingItemState();
}

class _MockListingItemState extends State<_MockListingItem> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.listing;
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.network(m.imageUrl,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        width: 110, height: 110, color: AppColors.surfaceAlt)),
                if (m.badge != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: m.badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        m.badge!,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(m.price,
                          style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _saved = !_saved),
                      child: Icon(
                        _saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color:
                            _saved ? AppColors.accent : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(m.spec,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary.withOpacity(0.75))),
                const SizedBox(height: 2),
                Text(m.location,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: m.tags
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(t,
                                style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary)),
                          ))
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
