import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/core/router/app_router.dart';
import 'package:spark/features/notifications/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _ringController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _ringScaleAnimation;
  late final Animation<double> _ringOpacityAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _ringScaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );
    _ringOpacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );

    Timer(const Duration(milliseconds: 2500), _navigate);
  }

  void _navigate() async {
    if (!mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await Supabase.instance.client
            .from('user_profiles')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();
        if (!mounted) return;
        if (profile != null) {
          // Init push notifications after confirmed auth
          NotificationService.instance.init().ignore();
          context.go(RoutePaths.home);
        } else {
          context.go(RoutePaths.onboarding);
        }
      } catch (_) {
        if (mounted) {
          NotificationService.instance.init().ignore();
          context.go(RoutePaths.home);
        }
      }
    } else {
      context.go(RoutePaths.ageGate);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Neon ring + logo
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Expanding ring
                  AnimatedBuilder(
                    animation: _ringController,
                    builder: (context, _) {
                      return Transform.scale(
                        scale: _ringScaleAnimation.value,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(
                                alpha: _ringOpacityAnimation.value,
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Second ring (offset timing)
                  AnimatedBuilder(
                    animation: _ringController,
                    builder: (context, _) {
                      final offset =
                          (_ringController.value + 0.5) % 1.0;
                      final scale = 0.5 + offset;
                      final opacity = 0.6 * (1.0 - offset);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary
                                  .withValues(alpha: opacity),
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // SPARK text with glow
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, _) {
                      return Text(
                        AppStrings.appName.toUpperCase(),
                        style: GoogleFonts.orbitron(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 8,
                          shadows: [
                            Shadow(
                              color: AppColors.primary.withValues(
                                alpha: 0.6 * _pulseAnimation.value,
                              ),
                              blurRadius: 16 * _pulseAnimation.value,
                            ),
                            Shadow(
                              color: AppColors.primary.withValues(
                                alpha: 0.3 * _pulseAnimation.value,
                              ),
                              blurRadius: 32 * _pulseAnimation.value,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 600.ms),

            const SizedBox(height: AppDimensions.spacing32),

            // Tagline
            Text(
              'Znajdź swoją iskrę',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                letterSpacing: 2,
              ),
            )
                .animate()
                .fadeIn(delay: 800.ms, duration: 1000.ms)
                .slideY(begin: 0.3, end: 0, delay: 800.ms, duration: 800.ms),
          ],
        ),
      ),
    );
  }
}
