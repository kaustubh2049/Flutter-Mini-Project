import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../core/utils/format_utils.dart';
import '../../models/property.dart';
import '../../services/property_service.dart';
import 'tabs/home_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _currentIndex,
            children: const [
              HomeTab(),
              _SavedTab(),
              _InboxTab(),
              _ProfileTab(),
            ],
          ),
        ),
        // ── Centered FAB (docked into the notch) ──────────────────────
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/add-property'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 30),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 10,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_filled,
              iconOutline: Icons.home_outlined,
              label: 'Home',
              isActive: _currentIndex == 0,
              onTap: () => setState(() => _currentIndex = 0),
            ),
            _NavItem(
              icon: Icons.favorite_rounded,
              iconOutline: Icons.favorite_border_rounded,
              label: 'Saved',
              isActive: _currentIndex == 1,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            // Space for the notched FAB
            const Expanded(child: SizedBox()),
            _NavItem(
              icon: Icons.chat_bubble_rounded,
              iconOutline: Icons.chat_bubble_outline_rounded,
              label: 'Inbox',
              isActive: _currentIndex == 2,
              onTap: () => setState(() => _currentIndex = 2),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              iconOutline: Icons.person_outline_rounded,
              label: 'Profile',
              isActive: _currentIndex == 3,
              onTap: () => setState(() => _currentIndex = 3),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nav Item ─────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData iconOutline;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.iconOutline,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? icon : iconOutline,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Saved Tab ────────────────────────────────────────────────────────────────
class _SavedTab extends ConsumerWidget {
  const _SavedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedPropertiesProvider);

    return Column(
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            children: [
              Text(
                'Saved Properties',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              savedAsync.maybeWhen(
                data: (list) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${list.length}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                orElse: () => const SizedBox(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: savedAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text('Failed to load saved properties',
                      style: GoogleFonts.inter(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref.invalidate(savedPropertiesProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (properties) {
              if (properties.isEmpty) return _EmptySaved();
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(savedPropertiesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: properties.length,
                  itemBuilder: (context, i) {
                    final p = properties[i];
                    return _SavedPropertyCard(
                      property: p,
                      onUnsave: () async {
                        await PropertyService.instance.unsaveProperty(p.id);
                        ref.invalidate(savedPropertiesProvider);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptySaved extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border_rounded,
                size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('No saved properties yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 8),
          Text('Tap the ♡ on any listing to save it here',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              )),
        ],
      ),
    );
  }
}

class _SavedPropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onUnsave;
  const _SavedPropertyCard({required this.property, required this.onUnsave});

  @override
  Widget build(BuildContext context) {
    final p = property;
    return GestureDetector(
        onTap: () => context.push('/property-detail', extra: p),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    Image.network(
                      p.imageUrls.isNotEmpty
                          ? p.imageUrls.first
                          : 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800',
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        decoration:
                            const BoxDecoration(color: AppColors.surfaceAlt),
                        child: const Icon(Icons.home_outlined,
                            size: 48, color: AppColors.textHint),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.listingType == 'Rent'
                              ? AppColors.rent
                              : AppColors.buy,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(p.listingType,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: onUnsave,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 6)
                            ],
                          ),
                          child: const Icon(Icons.favorite_rounded,
                              color: Colors.red, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(FormatUtils.formatPrice(p.price),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            )),
                        Text(FormatUtils.priceSuffix(p.listingType),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            )),
                        const Spacer(),
                        if (p.isVerified)
                          Row(children: [
                            const Icon(Icons.verified_rounded,
                                color: AppColors.verified, size: 15),
                            const SizedBox(width: 3),
                            Text('Verified',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.verified,
                                  fontWeight: FontWeight.w600,
                                )),
                          ]),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(p.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text('${p.locality}, ${p.city}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(FormatUtils.bhkLabel(p.bhk),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              )),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

// ── Inbox Tab ────────────────────────────────────────────────────────────────
class _InboxTab extends StatelessWidget {
  const _InboxTab();

  @override
  Widget build(BuildContext context) =>
      _PlaceholderTab(icon: Icons.chat_bubble_outline_rounded, label: 'Inbox');
}

// ── Profile Tab ──────────────────────────────────────────────────────────────
class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['name'] as String? ?? 'User';
    final email = user?.email ?? '';
    final myListingsAsync = ref.watch(myListingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(name,
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(email,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 32),

          // ── My Estate (Seller View) ───────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Text('My Estate',
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
          const SizedBox(height: 12),
          myListingsAsync.when(
            data: (listings) {
              if (listings.isEmpty) {
                return _EmptyEstate(onAdd: () => context.push('/add-property'));
              }
              return Column(
                children:
                    listings.map((p) => _MyListingCard(property: p)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                _EmptyEstate(onAdd: () => context.push('/add-property')),
          ),
          const SizedBox(height: 28),

          // ── Menu ─────────────────────────────────────────────────────
          ..._menuItems.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  title: Text(item.title,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.textSecondary),
                  onTap: () {},
                ),
              )),
          const SizedBox(height: 8),

          // Logout
          GestureDetector(
            onTap: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Text('Sign Out',
                      style: GoogleFonts.inter(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── My Listing Card (seller sees their own property with interest count) ──────
class _MyListingCard extends StatelessWidget {
  final Property property;
  const _MyListingCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final p = property;
    final img = p.imageUrls.isNotEmpty ? p.imageUrls.first : null;

    return GestureDetector(
      onTap: () => context.push('/property-inquiries', extra: p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: img != null
                      ? Image.network(img,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              width: 90,
                              height: 90,
                              color: AppColors.surfaceAlt))
                      : Container(
                          width: 90,
                          height: 90,
                          color: AppColors.surfaceAlt,
                          child: const Icon(Icons.home,
                              color: AppColors.textHint)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(FormatUtils.formatPrice(p.price),
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('${p.locality}, ${p.city}',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: p.isActive
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              p.isActive ? 'Active' : 'Inactive',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: p.isActive
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              p.listingType,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // ── View Inquiries footer ──────────────────────────────────────
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 13, color: AppColors.accent),
                const SizedBox(width: 5),
                Text(
                  'View Visit Requests',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 11, color: AppColors.textHint),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty Estate CTA ──────────────────────────────────────────────────────────
class _EmptyEstate extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyEstate({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.12),
            style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.home_work_outlined,
              size: 40, color: AppColors.primary),
          const SizedBox(height: 10),
          Text("No listings yet",
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text("Tap the + button to list your property",
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('+ Add Property',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Menu items model ──────────────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final String title;
  final Color color;
  const _MenuItem(this.icon, this.title, this.color);
}

const _menuItems = [
  _MenuItem(Icons.person_outline_rounded, 'Edit Profile', Color(0xFF8B5CF6)),
  _MenuItem(Icons.help_outline_rounded, 'Help & Support', AppColors.success),
  _MenuItem(
      Icons.privacy_tip_outlined, 'Privacy Policy', AppColors.textSecondary),
];

// ── Placeholder Tab ───────────────────────────────────────────────────────────
class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PlaceholderTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 34),
          ),
          const SizedBox(height: 16),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text('🚧  Coming soon',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
