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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authActionsProvider.notifier).signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.loginFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    await ref.read(authActionsProvider.notifier).signInWithGoogle();
  }

  Future<void> _signInWithApple() async {
    await ref.read(authActionsProvider.notifier).signInWithApple();
  }

  void _forgotPassword() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        title: Text(
          AppStrings.resetPassword,
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: NeonTextField(
          controller: emailController,
          label: AppStrings.email,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel,
                style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.trim().isNotEmpty) {
                await ref.read(authActionsProvider.notifier).resetPassword(
                      email: emailController.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppStrings.resetPasswordSent)),
                  );
                }
              }
            },
            child: Text(AppStrings.confirm,
                style: GoogleFonts.outfit(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Gap(AppDimensions.spacing64),

                // SPARK logo
                Text(
                  AppStrings.appName.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neonPink,
                    letterSpacing: 6,
                    shadows: AppTheme.neonTextShadow(
                      color: AppColors.neonPink,
                      blurRadius: 16,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .shimmer(
                      delay: 600.ms,
                      duration: 1500.ms,
                      color: AppColors.neonPink.withValues(alpha: 0.3),
                    ),

                const Gap(AppDimensions.spacing48),

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
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                const Gap(AppDimensions.spacing16),

                // Password
                NeonTextField(
                  controller: _passwordController,
                  label: AppStrings.password,
                  hint: AppStrings.password,
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _signIn(),
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
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                const Gap(AppDimensions.spacing12),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _forgotPassword,
                    child: Text(
                      AppStrings.forgotPassword,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const Gap(AppDimensions.spacing32),

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: NeonButton(
                    label: AppStrings.login,
                    onPressed: _signIn,
                    isLoading: _isLoading,
                  ),
                ),

                const Gap(AppDimensions.spacing32),

                // Divider "lub"
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.divider),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingM,
                      ),
                      child: Text(
                        'lub',
                        style: GoogleFonts.outfit(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColors.divider),
                    ),
                  ],
                ),

                const Gap(AppDimensions.spacing24),

                // Google sign in
                _SocialButton(
                  label: AppStrings.continueWithGoogle,
                  icon: Icons.g_mobiledata,
                  onTap: _signInWithGoogle,
                ),

                const Gap(AppDimensions.spacing12),

                // Apple sign in
                _SocialButton(
                  label: AppStrings.continueWithApple,
                  icon: Icons.apple,
                  onTap: _signInWithApple,
                ),

                const Gap(AppDimensions.spacing40),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${AppStrings.noAccount} ',
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(RoutePaths.register),
                      child: Text(
                        AppStrings.register,
                        style: GoogleFonts.outfit(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: AppDimensions.buttonHeight,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: AppDimensions.iconL),
            const SizedBox(width: AppDimensions.spacing8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
