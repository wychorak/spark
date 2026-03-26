import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/core/theme/app_theme.dart';
import 'package:spark/shared/widgets/neon_button.dart';

class MatchScreen extends StatefulWidget {
  final String myPhotoUrl;
  final String matchPhotoUrl;
  final String matchName;
  final VoidCallback onSendMessage;
  final VoidCallback onContinueBrowsing;

  const MatchScreen({
    super.key,
    this.myPhotoUrl =
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
    this.matchPhotoUrl =
        'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=300',
    this.matchName = 'Kasia',
    required this.onSendMessage,
    required this.onContinueBrowsing,
  });

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _borderGlowController;
  final Random _random = Random();
  late List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _borderGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Generate confetti particles
    _particles = List.generate(60, (_) {
      return _ConfettiParticle(
        x: _random.nextDouble(),
        y: -_random.nextDouble() * 0.3,
        speedX: (_random.nextDouble() - 0.5) * 0.3,
        speedY: 0.3 + _random.nextDouble() * 0.5,
        size: 4 + _random.nextDouble() * 8,
        color: [
          AppColors.primary,
          AppColors.warning,
          AppColors.neonPurple,
          AppColors.neonBlue,
          AppColors.success,
          AppColors.modeFWB,
        ][_random.nextInt(6)],
        rotation: _random.nextDouble() * pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
      );
    });

    _confettiController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _borderGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background: Y2K neon starburst gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF2A0030),
                  Color(0xFF150018),
                  AppColors.black,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Starburst rays
          ...List.generate(12, (i) {
            final angle = (i / 12) * pi * 2;
            return Positioned.fill(
              child: Transform.rotate(
                angle: angle,
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 2,
                    height: size.height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
                .animate(
                  onPlay: (c) => c.repeat(),
                )
                .fadeIn(duration: 800.ms, delay: (i * 60).ms)
                .then()
                .shimmer(
                  duration: 2000.ms,
                  color: AppColors.primary.withValues(alpha: 0.1),
                );
          }),

          // Confetti particles
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, _) {
              return CustomPaint(
                size: size,
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _confettiController.value,
                ),
              );
            },
          ),

          // Main content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // "To Match!" title
                Text(
                  'To Match!',
                  style: GoogleFonts.outfit(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    shadows: [
                      ...AppTheme.neonTextShadow(
                          color: AppColors.primary, blurRadius: 30),
                      const Shadow(
                        color: AppColors.neonPurple,
                        blurRadius: 60,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut),

                const Gap(8),

                Text(
                  'Ty i ${widget.matchName} pasujecie do siebie!',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                const Gap(40),

                // Profile photos side by side
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HolographicAvatar(
                      imageUrl: widget.myPhotoUrl,
                      glowController: _borderGlowController,
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .slideX(begin: -0.5, end: 0, duration: 600.ms, curve: Curves.easeOutBack),
                    const Gap(24),
                    // Heart icon between
                    Icon(
                      Icons.favorite_rounded,
                      color: AppColors.primary,
                      size: 36,
                    )
                        .animate(
                          onPlay: (c) => c.repeat(),
                        )
                        .fadeIn(delay: 500.ms)
                        .then()
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.3, 1.3),
                          duration: 600.ms,
                        )
                        .then()
                        .scale(
                          begin: const Offset(1.3, 1.3),
                          end: const Offset(1, 1),
                          duration: 600.ms,
                        ),
                    const Gap(24),
                    _HolographicAvatar(
                      imageUrl: widget.matchPhotoUrl,
                      glowController: _borderGlowController,
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .slideX(begin: 0.5, end: 0, duration: 600.ms, curve: Curves.easeOutBack),
                  ],
                ),

                const Spacer(flex: 2),

                // Send message button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingXL),
                  child: NeonButton(
                    label: AppStrings.matchesSendMessage,
                    onPressed: widget.onSendMessage,
                    icon: Icons.chat_bubble_rounded,
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 500.ms).slideY(begin: 0.3),

                const Gap(16),

                // Continue browsing
                TextButton(
                  onPressed: widget.onContinueBrowsing,
                  child: Text(
                    'Kontynuuj przeglądanie',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textSecondary,
                    ),
                  ),
                ).animate().fadeIn(delay: 900.ms, duration: 500.ms),

                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Holographic Avatar ─────────────────────────────────────

class _HolographicAvatar extends StatelessWidget {
  final String imageUrl;
  final AnimationController glowController;

  const _HolographicAvatar({
    required this.imageUrl,
    required this.glowController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowController,
      builder: (context, child) {
        final hue = glowController.value * 360;
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: HSLColor.fromAHSL(1, hue, 1, 0.6).toColor(),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: HSLColor.fromAHSL(0.5, hue, 1, 0.5).toColor(),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: HSLColor.fromAHSL(0.25, (hue + 180) % 360, 1, 0.5)
                    .toColor(),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: 114,
          height: 114,
          placeholder: (_, __) => Container(
            color: AppColors.surfaceLight,
            child: const Icon(Icons.person, color: AppColors.textHint, size: 40),
          ),
        ),
      ),
    );
  }
}

// ─── Confetti ───────────────────────────────────────────────

class _ConfettiParticle {
  double x;
  double y;
  final double speedX;
  final double speedY;
  final double size;
  final Color color;
  double rotation;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final x = (p.x + p.speedX * progress) * size.width;
      final y = (p.y + p.speedY * progress) * size.height;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      if (y < 0 || y > size.height) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotationSpeed * progress * 20);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
