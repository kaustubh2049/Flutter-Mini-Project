import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/property_provider.dart';
import '../../services/property_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The Add Property flow is a 3-page PageView:
//   Page 0 — Basic Details  (title, listing type, property type, BHK)
//   Page 1 — Price & Space  (price, area, floor, possession date)
//   Page 2 — Location       (locality, city, state, description, amenities)
//   Page 3 — Photos         (up to 8 images via image_picker) + Submit
// ─────────────────────────────────────────────────────────────────────────────

class AddPropertyScreen extends ConsumerStatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  // ── Page 0 ----------------------------------------------------------------
  final _titleCtrl = TextEditingController();
  String _listingType = 'Rent'; // 'Rent' | 'Buy'
  String _propertyType = 'Apartment';
  String? _bhk;

  // ── Page 1 ----------------------------------------------------------------
  final _priceCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  DateTime? _possession;

  // ── Page 2 ----------------------------------------------------------------
  final _localityCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Mumbai');
  final _stateCtrl = TextEditingController(text: 'Maharashtra');
  final _descCtrl = TextEditingController();
  final _selectedAmenities = <String>{};

  // ── Page 3 ----------------------------------------------------------------
  final _images = <File>[];
  bool _submitting = false;

  static const _propertyTypes = [
    'Apartment',
    'House',
    'Villa',
    'Plot',
    'Commercial',
    'PG'
  ];
  static const _bhkOptions = ['1', '2', '3', '4', '5+'];
  static const _amenityOptions = [
    'Parking',
    'Security',
    'Lift',
    'Power Backup',
    'Gym',
    'Swimming Pool',
    'Club House',
    'Garden',
    'WiFi',
    'Furnished',
    'Semi Furnished',
    'Modular Kitchen',
    'CCTV',
    'Intercom',
    'Gated Community',
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _areaCtrl.dispose();
    _floorCtrl.dispose();
    _localityCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Navigation helpers ────────────────────────────────────────────────────
  bool _validatePage() {
    if (_page == 0) {
      if (_titleCtrl.text.trim().isEmpty) {
        _snack('Please enter a property title');
        return false;
      }
      return true;
    }
    if (_page == 1) {
      if (_priceCtrl.text.trim().isEmpty) {
        _snack('Please enter the price');
        return false;
      }
      return true;
    }
    if (_page == 2) {
      if (_localityCtrl.text.trim().isEmpty || _cityCtrl.text.trim().isEmpty) {
        _snack('Please enter locality and city');
        return false;
      }
      return true;
    }
    return true;
  }

  void _next() {
    if (!_validatePage()) return;
    if (_page < 3) {
      setState(() => _page++);
      _pageCtrl.animateToPage(
        _page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _back() {
    if (_page > 0) {
      setState(() => _page--);
      _pageCtrl.animateToPage(
        _page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // ── Pick images ───────────────────────────────────────────────────────────
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final result = await picker.pickMultiImage(imageQuality: 75);
    if (result.isNotEmpty) {
      setState(() {
        for (final x in result) {
          if (_images.length < 8) _images.add(File(x.path));
        }
      });
    }
  }

  void _removeImage(int index) => setState(() => _images.removeAt(index));

  // ── Submit listing ────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_images.isEmpty) {
      _snack('Please add at least one photo');
      return;
    }
    setState(() => _submitting = true);

    try {
      await PropertyService.instance.addProperty(
        title: _titleCtrl.text.trim(),
        type: _propertyType,
        listingType: _listingType,
        price: double.parse(_priceCtrl.text.trim().replaceAll(',', '')),
        bhk: _bhk != null ? int.tryParse(_bhk!.replaceAll('+', '')) : null,
        area: _areaCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_areaCtrl.text.trim()),
        locality: _localityCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        floor: _floorCtrl.text.trim().isEmpty ? null : _floorCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        amenities: _selectedAmenities.toList(),
        images: _images,
      );

      // Invalidate feed so home screen refreshes
      ref.invalidate(homeFeedProvider);
      ref.invalidate(myListingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text('Property listed successfully!', style: GoogleFonts.inter()),
            ]),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      setState(() => _submitting = false);
      _snack('Error: ${e.toString()}');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const steps = ['Details', 'Price & Space', 'Location', 'Photos'];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ── App Bar ─────────────────────────────────────────────
              _buildAppBar(),

              // ── Step Progress ────────────────────────────────────────
              _buildProgress(steps),

              // ── Pages ────────────────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPage0(),
                    _buildPage1(),
                    _buildPage2(),
                    _buildPage3(),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Bottom Button ────────────────────────────────────────────────
        bottomNavigationBar: _buildBottomAction(steps),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textPrimary),
            ),
          ),
          Text(
            'List Your Property',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(List<String> steps) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP ${_page + 1} OF ${steps.length}  •  ${steps[_page].toUpperCase()}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                '${((_page + 1) / steps.length * 100).round()}%',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(steps.length, (i) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 5,
                  margin: EdgeInsets.only(right: i < steps.length - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color:
                        i <= _page ? AppColors.primary : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE 0 — Basic Details
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPage0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader('Basic Details', 'Tell us about your property'),
          const SizedBox(height: 28),

          // Listing Type Toggle
          _FieldLabel('Listing Type'),
          const SizedBox(height: 10),
          _ToggleRow(
            options: const ['Rent', 'Buy'],
            selected: _listingType,
            onSelect: (v) => setState(() => _listingType = v),
          ),
          const SizedBox(height: 20),

          // Property Type
          _FieldLabel('Property Type'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _propertyTypes.map((t) {
              final active = _propertyType == t;
              return GestureDetector(
                onTap: () => setState(() => _propertyType = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    t,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // BHK (skip for plots, commercial, PG)
          if (!['Plot', 'Commercial'].contains(_propertyType)) ...[
            _FieldLabel('BHK Configuration'),
            const SizedBox(height: 10),
            Row(
              children: _bhkOptions.map((b) {
                final active = _bhk == b;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _bhk = b),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            active ? AppColors.primary : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$b BHK',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                active ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Title
          _FieldLabel('Property Title'),
          const SizedBox(height: 8),
          _InputField(
            controller: _titleCtrl,
            hint: 'e.g. 2 BHK Sea-View Flat in Mahim',
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE 1 — Price & Space
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader('Price & Space', 'Set your price and property size'),
          const SizedBox(height: 28),

          // Price
          _FieldLabel(
              _listingType == 'Rent' ? 'Monthly Rent (₹)' : 'Total Price (₹)'),
          const SizedBox(height: 8),
          _InputField(
            controller: _priceCtrl,
            hint: _listingType == 'Rent' ? '25,000' : '75,00,000',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 8),
          if (_priceCtrl.text.isNotEmpty)
            Text(
              _formatPriceLabel(_priceCtrl.text),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 20),

          // Area + Floor side by side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Carpet Area'),
                    const SizedBox(height: 8),
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        _InputField(
                          controller: _areaCtrl,
                          hint: '1100',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          suffixPadding: 52,
                        ),
                        const Positioned(
                          right: 12,
                          child: Text(
                            'sq.ft',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Floor / Total'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _floorCtrl,
                      hint: '3rd of 10',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Possession date
          _FieldLabel('Possession Date'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                builder: (c, child) => Theme(
                  data: Theme.of(c).copyWith(
                    colorScheme:
                        const ColorScheme.light(primary: AppColors.primary),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _possession = picked);
            },
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _possession != null
                          ? '${_possession!.day}/${_possession!.month}/${_possession!.year}'
                          : 'Select possession date',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _possession != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE 2 — Location & Amenities
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader('Location', 'Where is the property located?'),
          const SizedBox(height: 28),
          _FieldLabel('Locality / Area'),
          const SizedBox(height: 8),
          _InputField(
              controller: _localityCtrl, hint: 'e.g. Mahim, Bandra, Worli'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('City'),
                    const SizedBox(height: 8),
                    _InputField(controller: _cityCtrl, hint: 'Mumbai'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('State'),
                    const SizedBox(height: 8),
                    _InputField(controller: _stateCtrl, hint: 'Maharashtra'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _FieldLabel('Description'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _descCtrl,
              minLines: 4,
              maxLines: 6,
              style:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText:
                    'Describe your property — views, special features, nearby landmarks...',
                hintStyle:
                    GoogleFonts.inter(fontSize: 13, color: AppColors.textHint),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _FieldLabel('Amenities'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _amenityOptions.map((a) {
              final active = _selectedAmenities.contains(a);
              return GestureDetector(
                onTap: () => setState(() {
                  if (active) {
                    _selectedAmenities.remove(a);
                  } else {
                    _selectedAmenities.add(a);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    a,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:
                          active ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE 3 — Photos
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader('Property Photos',
              'Add up to 8 photos — good photos get 5× more enquiries'),
          const SizedBox(height: 24),

          // Upload grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _images.length < 8 ? _images.length + 1 : 8,
            itemBuilder: (_, i) {
              if (i == _images.length) {
                // Add button
                return GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined,
                            size: 30, color: AppColors.textSecondary),
                        const SizedBox(height: 4),
                        Text(
                          'Add Photo',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_images[i], fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(i),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  if (i == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Cover',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          if (_images.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'At least 1 photo is required to post your listing.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom Action Button
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomAction(List<String> steps) {
    final isLastPage = _page == steps.length - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider))),
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: _submitting ? null : (isLastPage ? _submit : _next),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastPage ? 'Post Listing' : 'Continue',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastPage
                          ? Icons.check_circle_outline
                          : Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared helpers
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style:
              GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _formatPriceLabel(String raw) {
    final n = int.tryParse(raw.replaceAll(',', '')) ?? 0;
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)} L';
    if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(1)} K';
    return '₹$n';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _ToggleRow({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.map((opt) {
          final active = selected == opt;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    opt,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary.withOpacity(0.85),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final double? suffixPadding;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.suffixPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint),
          border: InputBorder.none,
          contentPadding: EdgeInsets.fromLTRB(14, 0, suffixPadding ?? 14, 0),
          isCollapsed: false,
        ),
      ),
    );
  }
}
