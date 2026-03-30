import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/core/router/app_router.dart';
import 'package:spark/core/theme/app_theme.dart';
import 'package:spark/shared/widgets/neon_button.dart';

class AgeGateScreen extends ConsumerStatefulWidget {
  const AgeGateScreen({super.key});

  @override
  ConsumerState<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends ConsumerState<AgeGateScreen> {
  int _selectedDay = 1;
  int _selectedMonth = 1;
  int _selectedYear = 2000;

  DateTime get _selectedDate =>
      DateTime(_selectedYear, _selectedMonth, _selectedDay);

  int _daysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _onConfirm() {
    final age = _calculateAge(_selectedDate);
    if (age < 18) {
      _showUnderageDialog();
    } else {
      context.go(RoutePaths.login, extra: _selectedDate);
    }
  }

  void _showUnderageDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          side: const BorderSide(color: AppColors.error, width: 1),
        ),
        title: Text(
          AppStrings.ageGateTitle,
          style: GoogleFonts.outfit(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          AppStrings.ageGateDenied,
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppStrings.ok,
              style: GoogleFonts.outfit(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFFFF5F7),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding,
            ),
            child: Column(
              children: [
                const Gap(AppDimensions.spacing64),

                // Logo
                Image.network(
                  'https://fildemavidnskmhcyqin.supabase.co/storage/v1/object/public/APP%20images/spark%20logo.png',
                  height: 70,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ).animate().fadeIn(duration: 400.ms),
                const Gap(24),

                // Title
                Text(
                  'Czy masz ukończone\n18 lat?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.2, end: 0, duration: 600.ms),

                const Gap(AppDimensions.spacing12),

                Text(
                  AppStrings.ageGateSubtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                const Gap(AppDimensions.spacing40),

                // Date picker
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusXL),
                    border: Border.all(
                      color: AppColors.neonPink.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Day
                      Expanded(
                        child: _DateDropdown(
                          label: 'Dzień',
                          value: _selectedDay,
                          items: List.generate(
                            _daysInMonth(_selectedMonth, _selectedYear),
                            (i) => i + 1,
                          ),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedDay = v);
                          },
                        ),
                      ),
                      const Gap(AppDimensions.spacing8),
                      // Month
                      Expanded(
                        child: _DateDropdown(
                          label: 'Miesiąc',
                          value: _selectedMonth,
                          items: List.generate(12, (i) => i + 1),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _selectedMonth = v;
                                final maxDay =
                                    _daysInMonth(_selectedMonth, _selectedYear);
                                if (_selectedDay > maxDay) {
                                  _selectedDay = maxDay;
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const Gap(AppDimensions.spacing8),
                      // Year
                      Expanded(
                        child: _DateDropdown(
                          label: 'Rok',
                          value: _selectedYear,
                          items: List.generate(
                            DateTime.now().year - 1920 + 1,
                            (i) => DateTime.now().year - i,
                          ),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _selectedYear = v;
                                final maxDay =
                                    _daysInMonth(_selectedMonth, _selectedYear);
                                if (_selectedDay > maxDay) {
                                  _selectedDay = maxDay;
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(
                        begin: 0.1, end: 0, delay: 400.ms, duration: 600.ms),

                const Gap(AppDimensions.spacing32),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  child: NeonButton(
                    label: AppStrings.confirm,
                    onPressed: _onConfirm,
                  ),
                ),

                const Gap(AppDimensions.spacing40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Date Dropdown Helper ──

class _DateDropdown extends StatelessWidget {
  final String label;
  final int value;
  final List<int> items;
  final ValueChanged<int?> onChanged;

  const _DateDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const Gap(4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: AppColors.neonPink.withValues(alpha: 0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.neonPink, size: 20),
              items: items
                  .map((v) => DropdownMenuItem<int>(
                        value: v,
                        child: Text(v.toString()),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
