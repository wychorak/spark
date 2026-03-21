import 'package:flutter/cupertino.dart';
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
  DateTime _selectedDate = DateTime(2000, 1, 1);

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
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D0008),
              AppColors.background,
              Color(0xFF05000D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding,
            ),
            child: Column(
              children: [
                const Gap(AppDimensions.spacing64),

                // Title
                Text(
                  'Czy masz ukończone\n18 lat?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    shadows: AppTheme.neonTextShadow(
                      color: AppColors.neonPink,
                      blurRadius: 12,
                    ),
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
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusXL),
                      border: Border.all(
                        color: AppColors.neonPink.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: CupertinoTheme(
                      data: const CupertinoThemeData(
                        brightness: Brightness.dark,
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: _selectedDate,
                        minimumDate: DateTime(1920),
                        maximumDate: DateTime.now(),
                        dateOrder: DatePickerDateOrder.dmy,
                        onDateTimeChanged: (date) {
                          setState(() => _selectedDate = date);
                        },
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms)
                      .slideY(
                          begin: 0.1, end: 0, delay: 400.ms, duration: 600.ms),
                ),

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
