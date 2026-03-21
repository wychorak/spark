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
import 'package:spark/shared/providers/auth_provider.dart';
import 'package:spark/shared/widgets/neon_button.dart';
import 'package:spark/shared/widgets/neon_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;

  // Password requirements state
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase =>
      _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _allRequirementsMet => _hasMinLength && _hasUppercase && _hasNumber;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Musisz zaakceptować regulamin i politykę prywatności.',
            style: GoogleFonts.outfit(),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authActionsProvider.notifier).signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) {
        context.go(RoutePaths.onboarding);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.registerFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(AppDimensions.spacing16),

                // Title
                Center(
                  child: Text(
                    AppStrings.register,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      shadows: AppTheme.neonTextShadow(
                        color: AppColors.neonPink,
                        blurRadius: 10,
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms),
                ),

                const Gap(AppDimensions.spacing40),

                // Email
                NeonTextField(
                  controller: _emailController,
                  label: AppStrings.email,
                  hint: AppStrings.email,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.emailRequired;
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value.trim())) {
                      return AppStrings.emailInvalid;
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

                const Gap(AppDimensions.spacing16),

                // Password
                NeonTextField(
                  controller: _passwordController,
                  label: AppStrings.password,
                  hint: AppStrings.password,
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textHint,
                      size: AppDimensions.iconS,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.passwordRequired;
                    }
                    if (value.length < 8) {
                      return AppStrings.passwordTooShort;
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                const Gap(AppDimensions.spacing12),

                // Password requirements
                _PasswordRequirement(
                  label: 'Minimum 8 znaków',
                  met: _hasMinLength,
                ),
                const Gap(AppDimensions.spacing4),
                _PasswordRequirement(
                  label: 'Jedna wielka litera',
                  met: _hasUppercase,
                ),
                const Gap(AppDimensions.spacing4),
                _PasswordRequirement(
                  label: 'Jedna cyfra',
                  met: _hasNumber,
                ),

                const Gap(AppDimensions.spacing16),

                // Confirm password
                NeonTextField(
                  controller: _confirmPasswordController,
                  label: AppStrings.confirmPassword,
                  hint: AppStrings.confirmPassword,
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textHint,
                      size: AppDimensions.iconS,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return AppStrings.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                const Gap(AppDimensions.spacing24),

                // Terms checkbox
                GestureDetector(
                  onTap: () =>
                      setState(() => _acceptedTerms = !_acceptedTerms),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _acceptedTerms
                              ? AppColors.primary
                              : AppColors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusXS),
                          border: Border.all(
                            color: _acceptedTerms
                                ? AppColors.primary
                                : AppColors.textHint,
                            width: 1.5,
                          ),
                        ),
                        child: _acceptedTerms
                            ? const Icon(Icons.check,
                                size: 16, color: AppColors.white)
                            : null,
                      ),
                      const SizedBox(width: AppDimensions.spacing12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Akceptuję ',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              TextSpan(
                                text: 'regulamin',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ' i '),
                              TextSpan(
                                text: 'politykę prywatności',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

                const Gap(AppDimensions.spacing32),

                // Register button
                SizedBox(
                  width: double.infinity,
                  child: NeonButton(
                    label: 'Utwórz konto',
                    onPressed: _signUp,
                    isLoading: _isLoading,
                    enabled: _acceptedTerms && _allRequirementsMet,
                  ),
                ),

                const Gap(AppDimensions.spacing24),

                // Already have account
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${AppStrings.haveAccount} ',
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          AppStrings.login,
                          style: GoogleFonts.outfit(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Gap(AppDimensions.spacing32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordRequirement extends StatelessWidget {
  const _PasswordRequirement({
    required this.label,
    required this.met,
  });

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: met ? AppColors.success : AppColors.textHint,
        ),
        const SizedBox(width: AppDimensions.spacing8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: met ? AppColors.success : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
