import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:spark/core/constants/app_colors.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlan = 0; // 0 = weekly, 1 = monthly
  bool _isLoading = false;
  bool _isPurchasing = false;
  Offerings? _offerings;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
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
        _showSnackBar('Zakupy przywrocone!');
        Navigator.pop(context, true);
      } else {
        _showSnackBar('Nie znaleziono aktywnych subskrypcji.');
      }
    } catch (e) {
      _showSnackBar('Blad przywracania: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                'Odblokuj wszystkie funkcje',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
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
                              'Rozpocznij',
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
                onTap: () => launchUrl(Uri.parse('mailto:sparksupport@gmail.com')),
                child: Text(
                  'Pomoc: sparksupport@gmail.com',
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
                    onPressed: () {},
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
                    onPressed: () {},
                    child: Text(
                      'Polityka prywatnosci',
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
  final bool isSelected;
  final VoidCallback onTap;

  const _PriceCard({
    required this.title,
    required this.price,
    required this.period,
    this.badge,
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
          ],
        ),
      ),
    );
  }
}
