import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../models/verification_request.dart';
import '../../providers/verification_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(allVerificationRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Text(
                'No verification requests found.',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            );
          }

          final pendingCount = requests.where((r) => r.status == VerificationStatus.pending).length;
          final approvedCount = requests.where((r) => r.status == VerificationStatus.approved).length;
          final rejectedCount = requests.where((r) => r.status == VerificationStatus.rejected).length;

          return RefreshIndicator(
            onRefresh: () => ref.refresh(allVerificationRequestsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _AdminHeader(
                    total: requests.length,
                    pending: pendingCount,
                    approved: approvedCount,
                    rejected: rejectedCount,
                  );
                }
                final request = requests[index - 1];
                return _RequestCard(request: request);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: $err'),
        ),
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  const _AdminHeader({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Overview',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatItem(label: 'Total', count: total, color: AppColors.primary),
              const SizedBox(width: 12),
              _StatItem(label: 'Pending', count: pending, color: AppColors.warning),
              const SizedBox(width: 12),
              _StatItem(label: 'Approved', count: approved, color: AppColors.success),
              const SizedBox(width: 12),
              _StatItem(label: 'Rejected', count: rejected, color: AppColors.error),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final VerificationRequest request;
  const _RequestCard({required this.request});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _updating = false;

  Future<void> _updateStatus(VerificationStatus status) async {
    setState(() => _updating = true);
    try {
      await ref.read(verificationServiceProvider).updateRequestStatus(
            requestId: widget.request.id,
            status: status,
            propertyId: widget.request.propertyId,
            userId: widget.request.userId,
          );
      ref.invalidate(allVerificationRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${status.name}'),
            backgroundColor: status == VerificationStatus.approved
                ? AppColors.success
                : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final isPending = r.status == VerificationStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.documentType,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'User ID: ${r.userId}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (r.propertyId != null)
                        Text(
                          'Property ID: ${r.propertyId}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                _StatusBadge(status: r.status),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          
          // Document Preview
          _DocumentPreview(url: r.documentUrl),
          
          if (isPending)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _updating ? null : () => _updateStatus(VerificationStatus.rejected),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updating ? null : () => _updateStatus(VerificationStatus.approved),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _updating 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final VerificationStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case VerificationStatus.approved:
        color = AppColors.success;
        break;
      case VerificationStatus.rejected:
        color = AppColors.error;
        break;
      default:
        color = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  final String url;
  const _DocumentPreview({required this.url});

  bool get isImage {
    final lower = url.toLowerCase();
    return lower.contains('.jpg') || lower.contains('.jpeg') || lower.contains('.png') || lower.contains('token');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceAlt,
      child: isImage
          ? InkWell(
              onTap: () => _launchURL(url),
              child: Image.network(
                url,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _PdfPlaceholder(url: url),
              ),
            )
          : _PdfPlaceholder(url: url),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _PdfPlaceholder extends StatelessWidget {
  final String url;
  const _PdfPlaceholder({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf_rounded, size: 40, color: AppColors.error),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _launchURL(url),
            child: const Text('View Document'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
