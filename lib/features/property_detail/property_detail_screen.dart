import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../models/property.dart';
import '../../providers/property_provider.dart';
import '../../services/property_service.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final Property property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  bool _isSaved = false;
  bool _saveLoading = false;
  bool _visitRequested = false;
  bool _visitLoading = false;
  bool _interested = false;
  bool _interestedLoading = false;


  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final s = await PropertyService.instance.isSaved(widget.property.id);
    final v =
        await PropertyService.instance.isVisitRequested(widget.property.id);
    final i = await PropertyService.instance.isInterested(widget.property.id);
    if (mounted)
      setState(() {
        _isSaved = s;
        _visitRequested = v;
        _interested = i;
      });
  }


  Future<void> _toggleSave() async {
    if (_saveLoading) return;
    setState(() => _saveLoading = true);
    try {
      if (_isSaved) {
        await PropertyService.instance.unsaveProperty(widget.property.id);
      } else {
        await PropertyService.instance.saveProperty(widget.property.id);
      }
      setState(() => _isSaved = !_isSaved);
      ref.invalidate(savedPropertiesProvider);
      ref.invalidate(savedIdsProvider);
    } finally {
      if (mounted) setState(() => _saveLoading = false);
    }
  }

  Future<void> _launchPhone() async {
    final uri = Uri(scheme: 'tel', path: widget.property.ownerPhone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp() async {
    final phone = widget.property.ownerPhone.replaceAll(RegExp(r'\D'), '');
    final msg = Uri.encodeComponent(
        'Hi, I saw your property "${widget.property.title}" on PropVista and I\'m interested.');
    final uri = Uri.parse('https://wa.me/91$phone?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _scheduleVisit() async {
    if (_visitLoading || _visitRequested) return;

    // 1. Pick Date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    if (pickedDate == null) return;

    // 2. Pick Time
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 11, minute: 0),
    );

    if (pickedTime == null) return;

    final DateTime appointmentAt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() => _visitLoading = true);
    try {
      await PropertyService.instance
          .requestVisit(widget.property.id, appointmentAt: appointmentAt);
      if (mounted) {
        setState(() => _visitRequested = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Visit scheduled for ${_formatDate(appointmentAt)} at ${_formatTime(pickedTime)}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong. Try again.',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _visitLoading = false);
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }


  Future<void> _expressInterest() async {
    if (_interestedLoading || _interested) return;
    setState(() => _interestedLoading = true);
    try {
      await PropertyService.instance.expressInterest(widget.property.id);
      if (mounted) {
        setState(() => _interested = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Interest sent to ${widget.property.ownerName}!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong. Try again.',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _interestedLoading = false);
    }
  }


  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    final images = p.imageUrls.isNotEmpty
        ? p.imageUrls
        : ['https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800'];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // ── Scrollable content ──────────────────────────────────────
            CustomScrollView(
              slivers: [
                // Image carousel as sliver header
                SliverToBoxAdapter(child: _buildCarousel(images)),
                SliverToBoxAdapter(child: _buildBody(p)),
                // Space for bottom bar
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

            // ── Top navigation bar ──────────────────────────────────────
            _buildTopBar(),

            // ── Bottom action bar ───────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
            _CircleButton(
              icon: _saveLoading
                  ? Icons.hourglass_empty_rounded
                  : _isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
              iconColor: _isSaved ? AppColors.accent : AppColors.textPrimary,
              onTap: _toggleSave,
            ),
          ],
        ),
      ),
    );
  }

  // ── Image carousel ────────────────────────────────────────────────────────
  Widget _buildCarousel(List<String> images) {
    return Stack(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => Image.network(
              images[i],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceAlt,
                child: const Icon(Icons.home_outlined,
                    size: 64, color: AppColors.textHint),
              ),
            ),
          ),
        ),
        // Counter badge
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentPage + 1}/${images.length}',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
        ),
        // Dot indicators
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  images.length,
                  (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _currentPage ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? AppColors.primary
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )),
            ),
          ),
      ],
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody(Property p) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHeaderSection(p),
          _buildDivider(),
          _buildAboutSection(p),
          if (p.amenities.isNotEmpty) ...[
            _buildDivider(),
            _buildAmenitiesSection(p),
          ],
          _buildDivider(),
          _buildOwnerSection(p),
          _buildDivider(),
          _buildDetailsSection(p),
        ],
      ),
    );
  }

  // ── Price & basic info ────────────────────────────────────────────────────
  Widget _buildHeaderSection(Property p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges row
          Row(
            children: [
              _Badge(
                label: p.listingType,
                color: p.listingType == 'Rent' ? AppColors.rent : AppColors.buy,
              ),
              if (p.isVerified) ...[
                const SizedBox(width: 8),
                _Badge(
                  label: '✓ Verified',
                  color: AppColors.success,
                ),
              ],
              const Spacer(),
              Text(
                FormatUtils.timeAgo(p.postedAt),
                style:
                    GoogleFonts.inter(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                FormatUtils.formatPrice(p.price),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              if (p.listingType == 'Rent')
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    '/ month',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Title
          Text(
            p.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Sub-info chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoChip(
                icon: Icons.location_on_outlined,
                label: '${p.locality}, ${p.city}',
              ),
              if (p.bhk != null)
                _InfoChip(
                  icon: Icons.bed_outlined,
                  label: FormatUtils.bhkLabel(p.bhk),
                ),
              if (p.area != null)
                _InfoChip(
                  icon: Icons.straighten_outlined,
                  label: '${p.area!.toInt()} sq.ft',
                ),
              _InfoChip(
                icon: Icons.home_outlined,
                label: p.type,
              ),
              if (p.floor != null)
                _InfoChip(
                  icon: Icons.layers_outlined,
                  label: 'Floor: ${p.floor}',
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── About ─────────────────────────────────────────────────────────────────
  Widget _buildAboutSection(Property p) {
    if (p.description == null || p.description!.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('About this property'),
          const SizedBox(height: 10),
          Text(
            p.description!,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.65,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Amenities ─────────────────────────────────────────────────────────────
  Widget _buildAmenitiesSection(Property p) {
    final iconMap = {
      'wifi': Icons.wifi_rounded,
      'parking': Icons.local_parking_rounded,
      'pool': Icons.pool_rounded,
      'gym': Icons.fitness_center_rounded,
      'security': Icons.security_rounded,
      'balcony': Icons.balcony_rounded,
      'ac': Icons.ac_unit_rounded,
      'lift': Icons.elevator_rounded,
      'club house': Icons.hotel_rounded,
      'garden': Icons.park_rounded,
      'power backup': Icons.bolt_rounded,
      'cctv': Icons.videocam_rounded,
      'gas pipeline': Icons.local_fire_department_rounded,
      'visitor parking': Icons.local_parking_rounded,
      'play area': Icons.child_friendly_rounded,
    };

    const maxVisible = 8;
    final amenities = p.amenities;
    final visible = amenities.take(maxVisible - 1).toList();
    final extraCount = amenities.length - visible.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Amenities'),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 8,
            childAspectRatio: 0.8,
            children: [
              ...visible.map((a) => _AmenityItem(
                    label: a,
                    icon:
                        iconMap[a.toLowerCase()] ?? Icons.check_circle_outline,
                  )),
              if (extraCount > 0)
                _AmenityItem(
                  label: '+$extraCount more',
                  icon: Icons.add_circle_outline,
                  isMore: true,
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Owner ─────────────────────────────────────────────────────────────────
  Widget _buildOwnerSection(Property p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Listed by'),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  p.ownerName.isNotEmpty ? p.ownerName[0].toUpperCase() : 'U',
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.ownerName.isNotEmpty ? p.ownerName : 'Owner',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Property Owner',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Additional details ────────────────────────────────────────────────────
  Widget _buildDetailsSection(Property p) {
    final items = <(String, String)>[
      ('Type', p.type),
      ('Listing', p.listingType),
      if (p.city.isNotEmpty) ('City', p.city),
      if (p.state != null && p.state!.isNotEmpty) ('State', p.state!),
      if (p.area != null) ('Area', '${p.area!.toInt()} sq.ft'),
      if (p.floor != null && p.floor!.isNotEmpty) ('Floor', p.floor!),
      ('Posted', FormatUtils.timeAgo(p.postedAt)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Property Details'),
          const SizedBox(height: 14),
          ...items.map((e) => _DetailRow(label: e.$1, value: e.$2)),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.divider,
        indent: 20,
        endIndent: 20,
      );

  // ── Bottom action bar ─────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              // Call
              _ActionIconButton(
                icon: Icons.call_rounded,
                color: AppColors.textPrimary,
                background: AppColors.surfaceAlt,
                onTap: _launchPhone,
              ),
              const SizedBox(width: 10),
              // WhatsApp
              _ActionIconButton(
                icon: Icons.chat_rounded,
                color: const Color(0xFF25D366),
                background: const Color(0xFF25D366).withOpacity(0.1),
                onTap: _launchWhatsApp,
              ),
              const SizedBox(width: 10),
              // Interested
              _ActionIconButton(
                icon: _interested ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _interested ? Colors.red : AppColors.textPrimary,
                background: _interested ? Colors.red.withOpacity(0.1) : AppColors.surfaceAlt,
                onTap: _expressInterest,
                isLoading: _interestedLoading,
              ),
              const SizedBox(width: 10),
              // Schedule Visit
              Expanded(
                child: GestureDetector(
                  onTap: _visitRequested ? null : _scheduleVisit,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: _visitRequested
                          ? AppColors.success
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _visitLoading
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _visitRequested
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.calendar_today_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _visitRequested
                                    ? 'Visit Scheduled'
                                    : 'Schedule Visit',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable small widgets ────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _AmenityItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isMore;

  const _AmenityItem({
    required this.label,
    required this.icon,
    this.isMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isMore ? AppColors.surfaceAlt : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 22,
            color: isMore ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;
  final bool isLoading;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                ),
              )
            : Icon(icon, color: color, size: 22),
      ),
    );
  }
}

