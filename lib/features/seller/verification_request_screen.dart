import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../models/property.dart';
import '../../models/verification_request.dart';
import '../../providers/property_provider.dart';
import '../../providers/verification_provider.dart';
import '../../services/verification_service.dart';

class VerificationRequestScreen extends ConsumerStatefulWidget {
  final String? initialPropertyId;

  const VerificationRequestScreen({
    super.key,
    this.initialPropertyId,
  });

  @override
  ConsumerState<VerificationRequestScreen> createState() =>
      _VerificationRequestScreenState();
}

class _VerificationRequestScreenState
    extends ConsumerState<VerificationRequestScreen> {
  static const String _profileTarget = '__profile__';

  String _selectedTarget = _profileTarget;
  String _selectedDocumentType = VerificationService.documentTypes.first;
  PlatformFile? _selectedFile;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPropertyId != null &&
        widget.initialPropertyId!.isNotEmpty) {
      _selectedTarget = widget.initialPropertyId!;
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _selectedFile = result.files.first);
  }

  Future<void> _submit() async {
    final file = _selectedFile;
    if (_submitting || file == null) {
      if (file == null) {
        _showSnack('Please pick a document first.', isError: true);
      }
      return;
    }

    setState(() => _submitting = true);

    try {
      final propertyId =
          _selectedTarget == _profileTarget ? null : _selectedTarget;

      await ref.read(verificationServiceProvider).submitVerificationRequest(
            documentType: _selectedDocumentType,
            file: file,
            propertyId: propertyId,
          );

      ref.invalidate(myVerificationRequestsProvider);
      ref.invalidate(homeFeedProvider);
      ref.invalidate(myListingsProvider);

      if (mounted) {
        setState(() => _selectedFile = null);
        _showSnack('Verification request submitted. Status: pending');
      }
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(myListingsProvider);
    final requestsAsync = ref.watch(myVerificationRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Request Verification',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildUploadCard(listingsAsync),
          const SizedBox(height: 16),
          _buildRequestsSection(requestsAsync),
        ],
      ),
    );
  }

  Widget _buildUploadCard(AsyncValue<List<Property>> listingsAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload verification document',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your request is created with pending status and can be approved later by admin.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Verification target',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          listingsAsync.when(
            data: (listings) {
              final items = <DropdownMenuItem<String>>[
                const DropdownMenuItem(
                  value: _profileTarget,
                  child: Text('Seller Profile'),
                ),
                ...listings.map(
                  (p) => DropdownMenuItem(
                    value: p.id,
                    child: Text('Property: ${p.title}'),
                  ),
                ),
              ];

              final hasSelectedTarget =
                  items.any((i) => i.value == _selectedTarget);
              final currentValue =
                  hasSelectedTarget ? _selectedTarget : _profileTarget;

              return DropdownButtonFormField<String>(
                value: currentValue,
                decoration: _fieldDecoration(),
                items: items,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedTarget = value);
                },
              );
            },
            loading: () =>
                const LinearProgressIndicator(color: AppColors.primary),
            error: (_, __) => DropdownButtonFormField<String>(
              value: _profileTarget,
              decoration: _fieldDecoration(),
              items: const [
                DropdownMenuItem(
                  value: _profileTarget,
                  child: Text('Seller Profile'),
                ),
              ],
              onChanged: (_) {},
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Document type',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedDocumentType,
            decoration: _fieldDecoration(),
            items: VerificationService.documentTypes
                .map((doc) => DropdownMenuItem(value: doc, child: Text(doc)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedDocumentType = value);
            },
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _pickDocument,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.upload_file_rounded,
                      color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedFile?.name ?? 'Choose file (PDF/JPG/PNG)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _selectedFile == null
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 46,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Submit Request',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsSection(
    AsyncValue<List<VerificationRequest>> requestsAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: requestsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => Text(
          'Could not load verification requests.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return Text(
              'No verification requests yet.',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My verification requests',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ...requests.map(_buildRequestTile),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestTile(VerificationRequest request) {
    final statusColor = _statusColor(request.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.documentType,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.status.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            request.propertyId == null
                ? 'Target: Seller profile'
                : 'Target: Property verification',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Submitted: ${_dateLabel(request.createdAt)}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
          if (request.status == VerificationStatus.rejected) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTarget = request.propertyId ?? _profileTarget;
                  _selectedDocumentType = request.documentType;
                });
              },
              child: Text(
                'Rejected. Re-upload document',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Color _statusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.approved:
        return AppColors.success;
      case VerificationStatus.rejected:
        return AppColors.error;
      case VerificationStatus.pending:
        return AppColors.warning;
    }
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      isDense: true,
    );
  }
}
