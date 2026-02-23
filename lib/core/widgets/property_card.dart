import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/property.dart';
import '../../services/property_service.dart';
import '../../providers/property_provider.dart';
import '../constants/app_colors.dart';
import '../utils/format_utils.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final bool isFeatured;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    return isFeatured
        ? _FeaturedCard(property: property, onTap: onTap)
        : _GridCard(property: property, onTap: onTap);
  }
}

// ── Featured Card ─────────────────────────────────────────────────────────────
class _FeaturedCard extends ConsumerStatefulWidget {
  final Property property;
  final VoidCallback onTap;
  const _FeaturedCard({required this.property, required this.onTap});

  @override
  ConsumerState<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends ConsumerState<_FeaturedCard> {
  bool _saved = false;
  bool _loading = false;

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
    if (_loading) return;
    setState(() => _loading = true);
    try {
      if (_saved) {
        await PropertyService.instance.unsaveProperty(widget.property.id);
      } else {
        await PropertyService.instance.saveProperty(widget.property.id);
      }
      setState(() => _saved = !_saved);
      ref.invalidate(savedPropertiesProvider);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  Image.network(
                    p.imageUrls.isNotEmpty
                        ? p.imageUrls.first
                        : 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800',
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 170,
                      decoration: const BoxDecoration(color: AppColors.surfaceAlt),
                      child: const Icon(Icons.home_outlined,
                          size: 48, color: AppColors.textHint),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Badge(
                          label: p.listingType,
                          color: p.listingType == 'Rent'
                              ? AppColors.rent
                              : AppColors.buy,
                        ),
                        GestureDetector(
                          onTap: _toggleSave,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: _loading
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : Icon(
                                    _saved
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: _saved ? Colors.red : AppColors.textSecondary,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        FormatUtils.formatPrice(p.price),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        FormatUtils.priceSuffix(p.listingType),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (p.isVerified)
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded,
                                color: AppColors.verified, size: 15),
                            const SizedBox(width: 3),
                            Text('Verified',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.verified,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${p.locality}, ${p.city}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _InfoChip(label: FormatUtils.bhkLabel(p.bhk)),
                      if (p.area != null) ...[
                        const SizedBox(width: 6),
                        _InfoChip(label: '${p.area!.toInt()} sq.ft'),
                      ],
                      if (p.floor != null) ...[
                        const SizedBox(width: 6),
                        _InfoChip(label: p.floor!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grid Card ─────────────────────────────────────────────────────────────────
class _GridCard extends ConsumerStatefulWidget {
  final Property property;
  final VoidCallback onTap;
  const _GridCard({required this.property, required this.onTap});

  @override
  ConsumerState<_GridCard> createState() => _GridCardState();
}

class _GridCardState extends ConsumerState<_GridCard> {
  bool _saved = false;
  bool _loading = false;

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
    if (_loading) return;
    setState(() => _loading = true);
    try {
      if (_saved) {
        await PropertyService.instance.unsaveProperty(widget.property.id);
      } else {
        await PropertyService.instance.saveProperty(widget.property.id);
      }
      setState(() => _saved = !_saved);
      ref.invalidate(savedPropertiesProvider);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                        : 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=400',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      decoration: const BoxDecoration(color: AppColors.surfaceAlt),
                      child: const Icon(Icons.home_outlined,
                          color: AppColors.textHint),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _Badge(
                      label: p.listingType,
                      color: p.listingType == 'Rent'
                          ? AppColors.rent
                          : AppColors.buy,
                      small: true,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: _toggleSave,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: _loading
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : Icon(
                                _saved
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 14,
                                color: _saved ? Colors.red : AppColors.textSecondary,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        FormatUtils.formatPrice(p.price),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        FormatUtils.priceSuffix(p.listingType),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (p.isVerified) ...[
                        const Spacer(),
                        const Icon(Icons.verified_rounded,
                            color: AppColors.verified, size: 13),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: AppColors.textSecondary),
                      Expanded(
                        child: Text(
                          '${p.locality}, ${p.city}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${FormatUtils.bhkLabel(p.bhk)}${p.area != null ? ' · ${p.area!.toInt()} sq.ft' : ''}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;
  const _Badge({required this.label, required this.color, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 10,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: small ? 9 : 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
