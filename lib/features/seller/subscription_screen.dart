import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/monetization_service.dart';
import '../../providers/monetization_provider.dart';
import '../../providers/wallet_provider.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isLoading = false;

  Future<void> _upgrade(PlanInfo plan) async {
    setState(() => _isLoading = true);
    try {
      await MonetizationService.instance.upgradePlan(plan.type);
      
      // Give Supabase a moment to propagate the change
      await Future.delayed(const Duration(milliseconds: 500));
      
      ref.invalidate(planUsageProvider);
      ref.invalidate(walletBalanceProvider);
      ref.invalidate(walletTransactionsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upgraded to ${plan.label} successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = MonetizationService.instance.getAllPlans();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Upgrade Plan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your plan 🚀',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a plan that fits your listing needs',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            ...plans.map((plan) => _PlanCard(
                  plan: plan,
                  isLoading: _isLoading,
                  onUpgrade: () => _upgrade(plan),
                )),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PlanInfo plan;
  final bool isLoading;
  final VoidCallback onUpgrade;

  const _PlanCard({
    required this.plan,
    required this.isLoading,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final isElite = plan.type == 'elite';
    final accentColor = isElite ? AppColors.accent : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isElite ? AppColors.accent.withOpacity(0.5) : AppColors.divider,
          width: isElite ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isElite)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'MOST POPULAR',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${plan.price.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FeatureRow(
            icon: Icons.home_work_outlined,
            text: plan.listingLimit == null
                ? 'Unlimited Property Listings'
                : 'Up to ${plan.listingLimit} Listings',
          ),
          _FeatureRow(
            icon: Icons.trending_up,
            text: isElite ? 'Elite Priority (Top of Search)' : 'Pro Boost (Above Free)',
          ),
          const _FeatureRow(
            icon: Icons.verified_user_outlined,
            text: 'Premium Badge on Profile',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Upgrade Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.success),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        ],
      ),
    );
  }
}
