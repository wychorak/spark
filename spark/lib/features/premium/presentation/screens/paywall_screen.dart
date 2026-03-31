import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/services/analytics_service.dart';
import 'package:spark/shared/providers/profile_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int _selectedPlan = 0; // 0 = weekly, 1 = monthly
  bool _isLoading = false;
  bool _isPurchasing = false;
  Offerings? _offerings;
  String? _error;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.track('paywall_viewed');
    _loadOfferings();
    _syncPremiumFromRevenueCat();
  }

  Future<void> _loadOfferings() async {
    setState(() => _isLoading = true);
    try {
      final offerings = await Purchases.getOfferings();
      if (mounted) {
        setState(() {
          _offerings = offerings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _purchase() async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);

    try {
      final offering = _offerings?.current;
      if (offering == null) {
        _showSnackBar('Brak dostepnych ofert. Sprobuj ponownie pozniej.');
        setState(() => _isPurchasing = false);
        return;
      }

      final packages = offering.availablePackages;
      Package? selectedPackage;

      if (_selectedPlan == 0) {
        // Weekly
        selectedPackage = packages.firstWhere(
          (p) => p.packageType == PackageType.weekly,
          orElse: () => packages.first,
        );
      } else {
        // Monthly
        selectedPackage = packages.firstWhere(
          (p) => p.packageType == PackageType.monthly,
          orElse: () => packages.last,
        );
      }

      final result = await Purchases.purchasePackage(selectedPackage);
      final isPremium = result.customerInfo.entitlements.all['premium']?.isActive ?? false;

      if (isPremium && mounted) {
        await _syncPremiumStatus(
          true,
          selectedPackage: selectedPackage,
          customerInfo: result.customerInfo,
          transactionIdentifier: result.storeTransaction.transactionIdentifier,
          purchasedProductId: result.storeTransaction.productIdentifier,
        );
        await AnalyticsService.instance.track(
          'premium_purchase_success',
          properties: {
            'plan': _selectedPlan == 0 ? 'weekly' : 'monthly',
          },
        );
        _showSnackBar('Spark Premium aktywowany!');
        Navigator.pop(context, true);
      }
    } on PurchasesErrorCode catch (e) {
      if (e != PurchasesErrorCode.purchaseCancelledError) {
        _showSnackBar('Blad zakupu: $e');
      }
    } catch (e) {
      _showSnackBar('Blad: $e');
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isPremium = customerInfo.entitlements.all['premium']?.isActive ?? false;
      if (isPremium && mounted) {
        await _syncPremiumStatus(true, customerInfo: customerInfo);
        await AnalyticsService.instance.track('premium_restore_success');
        _showSnackBar('Zakupy przywrocone!');
        Navigator.pop(context, true);
      } else {
        await _syncPremiumStatus(false);
        _showSnackBar('Nie znaleziono aktywnych subskrypcji.');
      }
    } catch (e) {
      _showSnackBar('Blad przywracania: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncPremiumFromRevenueCat() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isPremium =
          customerInfo.entitlements.all['premium']?.isActive ?? false;
      await _syncPremiumStatus(isPremium, customerInfo: customerInfo);
    } catch (_) {}
  }

  String _planFromPackage(Package? selectedPackage) {
    final packageType = selectedPackage?.packageType;
    if (packageType == PackageType.weekly) return 'weekly';
    if (packageType == PackageType.annual) return 'yearly';
    return _selectedPlan == 0 ? 'weekly' : 'monthly';
  }

  String _planFromCustomerInfo(CustomerInfo customerInfo) {
    for (final productId in customerInfo.activeSubscriptions) {
      final normalized = productId.toLowerCase();
      if (normalized.contains('week')) return 'weekly';
      if (normalized.contains('year') || normalized.contains('annual')) {
        return 'yearly';
      }
    }
    return _selectedPlan == 0 ? 'weekly' : 'monthly';
  }

  DateTime _estimatedExpiryForPlan(String plan) {
    switch (plan) {
      case 'weekly':
        return DateTime.now().add(const Duration(days: 7));
      case 'yearly':
        return DateTime.now().add(const Duration(days: 365));
      default:
        return DateTime.now().add(const Duration(days: 30));
    }
  }

  DateTime _expiryFromCustomerInfo(CustomerInfo customerInfo, String productId) {
    final entitlement = customerInfo.entitlements.all['premium'];
    final rawExpiration = entitlement?.expirationDate ??
        customerInfo.allExpirationDates[productId] ??
        customerInfo.latestExpirationDate;

    if (rawExpiration != null) {
      return DateTime.tryParse(rawExpiration)?.toUtc() ??
          _estimatedExpiryForPlan(_planFromCustomerInfo(customerInfo));
    }

    return _estimatedExpiryForPlan(_planFromCustomerInfo(customerInfo));
  }

  String _statusFromCustomerInfo(CustomerInfo customerInfo) {
    final entitlement = customerInfo.entitlements.all['premium'];
    if (entitlement == null) return 'expired';
    if (entitlement.billingIssueDetectedAt != null) return 'billing_issue';
    if (entitlement.isActive && !entitlement.willRenew) return 'grace_period';
    if (entitlement.isActive) return 'active';
    return 'expired';
  }

  Future<void> _syncPremiumStatus(
    bool isPremium, {
    Package? selectedPackage,
    CustomerInfo? customerInfo,
    String? transactionIdentifier,
    String? purchasedProductId,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final client = Supabase.instance.client;

      if (isPremium) {
        final plan = customerInfo != null
            ? _planFromCustomerInfo(customerInfo)
            : _planFromPackage(selectedPackage);
        final productId = purchasedProductId ??
            selectedPackage?.storeProduct.identifier ??
            ((customerInfo != null && customerInfo.activeSubscriptions.isNotEmpty)
                ? customerInfo.activeSubscriptions.first
                : 'spark_$plan');
        final expiresAt = customerInfo != null
            ? _expiryFromCustomerInfo(customerInfo, productId)
            : _estimatedExpiryForPlan(plan);
        final status = customerInfo != null
            ? _statusFromCustomerInfo(customerInfo)
            : 'active';
        final autoRenew = customerInfo?.entitlements.all['premium']?.willRenew ?? true;
        final environment =
            customerInfo?.entitlements.all['premium']?.isSandbox == true
                ? 'sandbox'
                : 'production';

        await client.rpc(
          'fn_sync_premium_subscription',
          params: {
            'p_plan': plan,
            'p_store_product_id': productId,
            'p_expires_at': expiresAt.toIso8601String(),
            'p_store_transaction_id': transactionIdentifier,
            'p_provider': 'revenuecat',
            'p_entitlement_id': 'premium',
            'p_status': status,
            'p_auto_renew': autoRenew,
            'p_environment': environment,
          },
        );
      } else {
        await client.rpc(
          'fn_set_premium_inactive',
          params: {'p_status': 'expired'},
        );
      }

      await client.from('user_profiles').update({'is_premium': isPremium}).eq('id', userId);
      ref.invalidate(profileByIdProvider(userId));
    } catch (_) {}
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Gap(8),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                ),
              ),
              const Gap(8),

              // Crown icon
              const _CrownIcon(),
              const Gap(16),

              // Title
              Text(
                'Spark Premium',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ).createShader(const Rect.fromLTWH(0, 0, 250, 40)),
                ),
              ),
              const Gap(4),
              Text(
                'Więcej dopasowań, większa widoczność i mniej przypadkowych strat.',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(20),
              const _BenefitPills(),
              if (_error != null) ...[
                const Gap(12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDA4AF)),
                  ),
                  child: Text(
                    'Nie udało się załadować ofert. Sprawdź konfigurację płatności i spróbuj ponownie.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const Gap(32),

              // Feature comparison
              const _FeatureComparison(),
              const Gap(32),

              // Price cards
              _PriceCardSection(
                selectedPlan: _selectedPlan,
                onPlanSelected: (i) => setState(() => _selectedPlan = i),
                offerings: _offerings,
              ),
              const Gap(16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: Color(0xFFE6A800),
                      size: 18,
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        'Anulujesz kiedy chcesz. Zakup przywrócisz z poziomu konta.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(32),

              // Subscribe button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isPurchasing ? null : _purchase,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: _isPurchasing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _selectedPlan == 0
                                  ? 'Odblokuj na tydzień'
                                  : 'Odblokuj na miesiąc',
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const Gap(16),
              const _PaywallFaq(),
              const Gap(12),

              // Restore purchases
              TextButton(
                onPressed: _isLoading ? null : _restorePurchases,
                child: Text(
                  'Przywroc zakupy',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.textSecondary,
                  ),
                ),
              ),
              const Gap(16),

              // Support email
              GestureDetector(
                onTap: () => launchUrl(Uri.parse('mailto:sparksupportpolska@gmail.com')),
                child: Text(
                  'Pomoc: sparksupportpolska@gmail.com',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ),
              const Gap(12),

              // Terms
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse('https://wychorak.github.io/spark/terms.html'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(
                      'Regulamin',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                  Text('  |  ',
                      style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse('https://wychorak.github.io/spark/privacy-policy.html'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(
                      'Polityka prywatności',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Crown Icon ─────────────────────────────────────────────

class _CrownIcon extends StatelessWidget {
  const _CrownIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Color(0x33FFD700),
            Colors.transparent,
          ],
        ),
      ),
      child: const Icon(
        Icons.workspace_premium_rounded,
        size: 56,
        color: Color(0xFFFFD700),
      ),
    );
  }
}

class _BenefitPills extends StatelessWidget {
  const _BenefitPills();

  @override
  Widget build(BuildContext context) {
    const items = [
      'Zobacz kto Cię lubi',
      'Cofnij przypadkowy swipe',
      'Boost i więcej zasięgu',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            item,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Feature Comparison ─────────────────────────────────────

class _FeatureComparison extends StatelessWidget {
  const _FeatureComparison();

  @override
  Widget build(BuildContext context) {
    const features = [
      ('Nieograniczone Smash', false, true),
      ('Kto Cie polubil', false, true),
      ('Super Like 10/mc', false, true),
      ('Cofnij swipe', false, true),
      ('Zaawansowane filtry', false, true),
      ('Potwierdzenia przeczytania', false, true),
      ('Boost profilu', false, true),
      ('Brak reklam', false, true),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Funkcja',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Free',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ).createShader(bounds),
                      child: Text(
                        'Premium',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...features.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: i < features.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.divider))
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      f.$1,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Icon(
                        f.$2 ? Icons.check_rounded : Icons.close_rounded,
                        color: f.$2 ? AppColors.success : AppColors.error,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Icon(
                        f.$3 ? Icons.check_rounded : Icons.close_rounded,
                        color: f.$3 ? const Color(0xFFFFD700) : AppColors.error,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Price Cards ────────────────────────────────────────────

class _PriceCardSection extends StatelessWidget {
  final int selectedPlan;
  final ValueChanged<int> onPlanSelected;
  final Offerings? offerings;

  const _PriceCardSection({
    required this.selectedPlan,
    required this.onPlanSelected,
    this.offerings,
  });

  @override
  Widget build(BuildContext context) {
    // Try to get prices from RevenueCat, fall back to defaults
    String weeklyPrice = '29 PLN';
    String monthlyPrice = '49 PLN';

    final current = offerings?.current;
    if (current != null) {
      for (final pkg in current.availablePackages) {
        if (pkg.packageType == PackageType.weekly) {
          weeklyPrice = pkg.storeProduct.priceString;
        } else if (pkg.packageType == PackageType.monthly) {
          monthlyPrice = pkg.storeProduct.priceString;
        }
      }
    }

    return Row(
      children: [
        Expanded(
          child: _PriceCard(
            title: 'Tygodniowo',
            price: weeklyPrice,
            period: '/tydzien',
            caption: 'Na szybki start',
            isSelected: selectedPlan == 0,
            onTap: () => onPlanSelected(0),
          ),
        ),
        const Gap(12),
        Expanded(
          child: _PriceCard(
            title: 'Miesiecznie',
            price: monthlyPrice,
            period: '/miesiac',
            badge: 'Najlepsza wartosc',
            caption: 'Najczesciej wybierany plan',
            isSelected: selectedPlan == 1,
            onTap: () => onPlanSelected(1),
          ),
        ),
      ],
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? badge;
  final String? caption;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriceCard({
    required this.title,
    required this.price,
    required this.period,
    this.badge,
    this.caption,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? const Color(0xFFFFF8E1) : AppColors.card,
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Gap(10),
            ],
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const Gap(8),
            Text(
              price,
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: isSelected ? const Color(0xFFE6A800) : AppColors.textPrimary,
              ),
            ),
            Text(
              period,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (caption != null) ...[
              const Gap(8),
              Text(
                caption!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaywallFaq extends StatelessWidget {
  const _PaywallFaq();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jak działa subskrypcja?',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(8),
          Text(
            'Premium odnawia się automatycznie zgodnie z wybranym planem. Możesz anulować w ustawieniach sklepu i przywrócić zakup w dowolnym momencie.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
