import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/shared/widgets/neon_button.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlan = 0; // 0 = monthly, 1 = yearly

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding),
          child: Column(
            children: [
              const Gap(8),
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                ),
              ),
              const Gap(8),

              // Animated crown
              _AnimatedCrown(),
              const Gap(16),

              // Title
              Text(
                AppStrings.paywallTitle,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ).createShader(
                        const Rect.fromLTWH(0, 0, 250, 40)),
                  shadows: [
                    const Shadow(
                      color: Color(0x88FFD700),
                      blurRadius: 20,
                    ),
                    const Shadow(
                      color: Color(0x44FFA500),
                      blurRadius: 40,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: -0.2),

              const Gap(4),
              Text(
                AppStrings.paywallSubtitle,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

              const Gap(32),

              // Feature comparison
              _FeatureComparison(),
              const Gap(32),

              // Price cards
              _PriceCardSection(
                selectedPlan: _selectedPlan,
                onPlanSelected: (i) => setState(() => _selectedPlan = i),
              ),
              const Gap(32),

              // Subscribe button
              SizedBox(
                width: double.infinity,
                child: NeonButton(
                  label: 'Rozpocznij',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Przekierowanie do płatności...'),
                        backgroundColor: AppColors.surfaceLight,
                      ),
                    );
                  },
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  glowColor: const Color(0xFFFFD700),
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 500.ms).slideY(begin: 0.2),

              const Gap(16),

              // Restore purchases
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Przywracanie zakupów...'),
                      backgroundColor: AppColors.surfaceLight,
                    ),
                  );
                },
                child: Text(
                  AppStrings.paywallRestore,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.textSecondary,
                  ),
                ),
              ),
              const Gap(24),

              // Terms
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      AppStrings.settingsTerms,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                  Text('  |  ',
                      style: TextStyle(
                          color: AppColors.textHint, fontSize: 11)),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      AppStrings.settingsPrivacyPolicy,
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

// ─── Animated Crown ─────────────────────────────────────────

class _AnimatedCrown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
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
    )
        .animate(
          onPlay: (c) => c.repeat(reverse: true),
        )
        .moveY(begin: 0, end: -8, duration: 1500.ms, curve: Curves.easeInOut)
        .then()
        .shimmer(
          duration: 2000.ms,
          color: const Color(0x44FFD700),
        );
  }
}

// ─── Feature Comparison ─────────────────────────────────────

class _FeatureComparison extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      ('Nieograniczone polubienia', false, true),
      ('Kto Cię polubił', false, true),
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
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Header
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
          // Rows
          ...features.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: i < features.length - 1
                    ? const Border(
                        bottom: BorderSide(color: AppColors.divider))
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
                        color: f.$3
                            ? const Color(0xFFFFD700)
                            : AppColors.error,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: (200 + i * 60).ms, duration: 400.ms);
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

  const _PriceCardSection({
    required this.selectedPlan,
    required this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Monthly
        Expanded(
          child: _PriceCard(
            title: AppStrings.paywallMonthly,
            price: '49,99 zł',
            period: '/miesiąc',
            isSelected: selectedPlan == 0,
            onTap: () => onPlanSelected(0),
          ),
        ),
        const Gap(12),
        // Yearly
        Expanded(
          child: _PriceCard(
            title: AppStrings.paywallYearly,
            price: '29,99 zł',
            period: '/miesiąc',
            badge: 'Oszczędzasz 40%',
            isSelected: selectedPlan == 1,
            onTap: () => onPlanSelected(1),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms, duration: 500.ms).slideY(begin: 0.15);
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
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A0A2E),
                    Color(0xFF0D0520),
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.card,
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD700)
                : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: Color(0x33FFD700),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusRound),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
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
                color: isSelected
                    ? AppColors.white
                    : AppColors.textSecondary,
              ),
            ),
            const Gap(8),
            Text(
              price,
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? const Color(0xFFFFD700)
                    : AppColors.textPrimary,
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
