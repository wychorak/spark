import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/core/router/app_router.dart';
import 'package:spark/shared/providers/auth_provider.dart';
import 'package:spark/core/utils/error_helpers.dart';
import 'package:spark/features/notifications/notification_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showEmailLogin = false;

  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _floatController.dispose();
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

      final user = Supabase.instance.client.auth.currentUser;
      if (!mounted) return;

      if (user == null) {
        final authState = ref.read(authActionsProvider);
        final errMsg = authState.maybeWhen(
          error: (e, _) => friendlyAuthError(e),
          orElse: () => AppStrings.loginFailed,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      try {
        final profile = await Supabase.instance.client
            .from('user_profiles')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();
        if (!mounted) return;
        if (profile != null) {
          await NotificationService.instance.init();
          context.go(RoutePaths.home);
        } else {
          context.go(RoutePaths.onboarding);
        }
      } catch (_) {
        if (mounted) context.go(RoutePaths.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyAuthError(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    await ref.read(authActionsProvider.notifier).signInWithApple();
  }

  void _forgotPassword() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF5F7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          AppStrings.resetPassword,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2D2D3A),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: AppStrings.email,
            labelStyle: GoogleFonts.outfit(color: const Color(0xFF8E8E9A)),
            prefixIcon:
                const Icon(Icons.email_outlined, color: Color(0xFFFF85B3)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFFD6E8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFFD6E8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF85B3), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel,
                style: GoogleFonts.outfit(color: const Color(0xFF8E8E9A))),
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFC),
      body: Stack(
        children: [
          // Decorative cherry blossom blobs
          ..._buildBlossoms(size),

          // Floating petals
          ..._buildFloatingPetals(size),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  Gap(size.height * 0.08),

                  // Cherry blossom branch decoration (abstract)
                  _buildBranchDecoration(),

                  const Gap(12),

                  // Spark logo
                  Image.network(
                    Supabase.instance.client.storage
                        .from('APP images')
                        .getPublicUrl('spark logo.png'),
                    height: 90,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Text(
                      'Spark',
                      style: GoogleFonts.dancingScript(
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF85B3),
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFF85B3).withValues(alpha: 0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                      ),

                  const Gap(6),

                  // Subtitle
                  Text(
                    'Gdzie iskry łączą serca',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8E8E9A),
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

                  const Gap(36),

                  // Glassmorphism card
                  _buildGlassCard(context),

                  const Gap(24),

                  // Footer security text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 14, color: const Color(0xFFB0B0BA)),
                      const Gap(6),
                      Text(
                        'Twoje dane są bezpieczne i chronione',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFFB0B0BA),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

                  const Gap(40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchDecoration() {
    return SizedBox(
      width: 120,
      height: 60,
      child: Stack(
        children: [
          // Branch line
          Positioned(
            left: 20,
            top: 30,
            child: Container(
              width: 80,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF85B3).withValues(alpha: 0.2),
                    const Color(0xFFFF85B3).withValues(alpha: 0.6),
                    const Color(0xFFFF85B3).withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // Blossom circles on branch
          Positioned(
            left: 15,
            top: 18,
            child: _blossomDot(14, 0.7),
          ),
          Positioned(
            left: 40,
            top: 22,
            child: _blossomDot(10, 0.5),
          ),
          Positioned(
            left: 55,
            top: 14,
            child: _blossomDot(16, 0.6),
          ),
          Positioned(
            left: 78,
            top: 20,
            child: _blossomDot(12, 0.8),
          ),
          Positioned(
            left: 95,
            top: 26,
            child: _blossomDot(8, 0.4),
          ),
          // Small leaf-like accent
          Positioned(
            left: 30,
            top: 34,
            child: _blossomDot(6, 0.3),
          ),
          Positioned(
            left: 70,
            top: 36,
            child: _blossomDot(7, 0.35),
          ),
        ],
      ),
    );
  }

  Widget _blossomDot(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFFFB3D1).withValues(alpha: opacity),
            const Color(0xFFFF85B3).withValues(alpha: opacity * 0.5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF85B3).withValues(alpha: opacity * 0.3),
            blurRadius: size,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFFD6E8).withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF85B3).withValues(alpha: 0.08),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showEmailLogin ? _buildEmailForm() : _buildMainOptions(),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 600.ms)
        .slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 500.ms);
  }

  Widget _buildMainOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Apple button
        _CherryButton(
          label: 'Kontynuuj z Apple',
          icon: Icons.apple,
          onTap: _signInWithApple,
          isPrimary: false,
        ),

        const Gap(12),

        // Email button
        _CherryButton(
          label: 'Kontynuuj e-mailem',
          icon: Icons.email_outlined,
          onTap: () => setState(() => _showEmailLogin = true),
          isPrimary: false,
        ),

        const Gap(24),

        // Divider LUB
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: const Color(0xFFFFD6E8).withValues(alpha: 0.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'LUB',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB0B0BA),
                  letterSpacing: 2,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: const Color(0xFFFFD6E8).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),

        const Gap(24),

        // Create account button (pink gradient)
        _CherryButton(
          label: 'Utwórz konto',
          icon: Icons.person_add_outlined,
          onTap: () => context.push(RoutePaths.register),
          isPrimary: true,
        ),

        const Gap(20),

        // Already have account link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Masz już konto? ',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF8E8E9A),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _showEmailLogin = true),
              child: Text(
                'Zaloguj się',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF85B3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back arrow
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => setState(() => _showEmailLogin = false),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: Color(0xFF8E8E9A),
              ),
            ),
          ),

          const Gap(8),

          Text(
            'Zaloguj się',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D2D3A),
            ),
          ),

          const Gap(24),

          // Email
          _CherryTextField(
            controller: _emailController,
            label: AppStrings.email,
            icon: Icons.email_outlined,
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
          ),

          const Gap(14),

          // Password
          _CherryTextField(
            controller: _passwordController,
            label: AppStrings.password,
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _signIn(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFFB0B0BA),
                size: 20,
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
          ),

          const Gap(10),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _forgotPassword,
              child: Text(
                AppStrings.forgotPassword,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFFFF85B3),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const Gap(24),

          // Login button
          _CherryButton(
            label: AppStrings.login,
            icon: Icons.login_rounded,
            onTap: _signIn,
            isPrimary: true,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBlossoms(Size size) {
    final blossoms = <_BlossomData>[
      _BlossomData(-30, -20, 120, 0.15),
      _BlossomData(size.width - 60, -40, 140, 0.12),
      _BlossomData(-50, size.height * 0.3, 100, 0.1),
      _BlossomData(size.width - 30, size.height * 0.5, 90, 0.13),
      _BlossomData(size.width * 0.3, size.height - 60, 110, 0.1),
      _BlossomData(size.width * 0.7, size.height * 0.15, 70, 0.08),
    ];

    return blossoms.map((b) {
      return Positioned(
        left: b.x,
        top: b.y,
        child: Container(
          width: b.size,
          height: b.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFFB3D1).withValues(alpha: b.opacity),
                const Color(0xFFFF85B3).withValues(alpha: b.opacity * 0.3),
                const Color(0xFFFF85B3).withValues(alpha: 0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildFloatingPetals(Size size) {
    final rng = Random(42);
    return List.generate(8, (i) {
      final startX = rng.nextDouble() * size.width;
      final startY = rng.nextDouble() * size.height;
      final petalSize = 6.0 + rng.nextDouble() * 10;
      final delay = (i * 400).ms;

      return Positioned(
        left: startX,
        top: startY,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final t = (_floatController.value + i * 0.125) % 1.0;
            final dy = sin(t * 2 * pi) * 12;
            final dx = cos(t * 2 * pi * 0.7) * 6;
            final rotation = t * 2 * pi;
            return Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.rotate(
                angle: rotation,
                child: child,
              ),
            );
          },
          child: Container(
            width: petalSize,
            height: petalSize * 1.4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(petalSize),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFB3D1).withValues(alpha: 0.6),
                  const Color(0xFFFF85B3).withValues(alpha: 0.3),
                ],
              ),
            ),
          ).animate().fadeIn(delay: delay, duration: 1000.ms),
        ),
      );
    });
  }
}

class _BlossomData {
  final double x, y, size, opacity;
  const _BlossomData(this.x, this.y, this.size, this.opacity);
}

class _CherryButton extends StatelessWidget {
  const _CherryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isPrimary,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFFFF85B3), Color(0xFFFF6DA0)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isPrimary ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(
                  color: const Color(0xFFFFD6E8),
                  width: 1.5,
                ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF85B3).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    isPrimary ? Colors.white : const Color(0xFF2D2D3A),
                  ),
                ),
              )
            else ...[
              Icon(
                icon,
                color: isPrimary ? Colors.white : const Color(0xFF2D2D3A),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: isPrimary ? Colors.white : const Color(0xFF2D2D3A),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CherryTextField extends StatelessWidget {
  const _CherryTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: GoogleFonts.outfit(
        fontSize: 15,
        color: const Color(0xFF2D2D3A),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(
          color: const Color(0xFF8E8E9A),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFFF85B3), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFFFF5F7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFD6E8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFD6E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF85B3), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF3B30)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 2),
        ),
      ),
    );
  }
}
