import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/core/theme/app_theme.dart';
import 'package:spark/shared/widgets/neon_button.dart';

// ── Verification Step ──

enum _VerificationStep { instructions, camera, processing, result }

final _stepProvider = StateProvider.autoDispose<_VerificationStep>(
  (ref) => _VerificationStep.instructions,
);

final _verificationSuccessProvider = StateProvider.autoDispose<bool>((ref) => true);

class PhotoVerificationScreen extends ConsumerWidget {
  const PhotoVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(_stepProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppStrings.photoVerificationTitle,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: AppDimensions.animNormal),
          child: switch (step) {
            _VerificationStep.instructions => const _InstructionsStep(
                key: ValueKey('instructions'),
              ),
            _VerificationStep.camera => const _CameraStep(
                key: ValueKey('camera'),
              ),
            _VerificationStep.processing => const _ProcessingStep(
                key: ValueKey('processing'),
              ),
            _VerificationStep.result => const _ResultStep(
                key: ValueKey('result'),
              ),
          },
        ),
      ),
    );
  }
}

// ── Step 1: Instructions ──

class _InstructionsStep extends ConsumerWidget {
  const _InstructionsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: Column(
        children: [
          const Spacer(flex: 1),
          // ── Pose example icon ──
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.neonPink.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonPinkGlow,
                  blurRadius: AppDimensions.neonBlurLarge,
                  spreadRadius: AppDimensions.neonSpreadMedium,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceLight,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.face,
                    size: 80,
                    color: AppColors.neonPink.withValues(alpha: 0.6),
                  ),
                  // Gesture indicator - hand peace sign
                  Positioned(
                    bottom: 30,
                    right: 30,
                    child: Icon(
                      Icons.back_hand_outlined,
                      size: 36,
                      color: AppColors.neonBlue,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: const Duration(milliseconds: AppDimensions.animSlow))
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),

          const Gap(AppDimensions.spacing40),

          Text(
            'Zrob selfie w podanej pozie',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              shadows: AppTheme.neonTextShadow(color: AppColors.neonPink),
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: AppDimensions.animNormal),
              ),

          const Gap(AppDimensions.spacing16),

          Text(
            AppStrings.photoVerificationSubtitle,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: AppDimensions.animNormal),
              ),

          const Gap(AppDimensions.spacing24),

          // ── Tips ──
          ..._buildTips()
              .animate()
              .fadeIn(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: AppDimensions.animNormal),
              ),

          const Spacer(flex: 2),

          SizedBox(
            width: double.infinity,
            child: NeonButton(
              label: 'Rozpocznij weryfikacje',
              icon: Icons.camera_alt_outlined,
              onPressed: () {
                ref.read(_stepProvider.notifier).state = _VerificationStep.camera;
              },
            ),
          ),

          const Gap(AppDimensions.spacing32),
        ],
      ),
    );
  }

  List<Widget> _buildTips() {
    final tips = [
      'Upewnij sie, ze twarz jest dobrze oswietlona',
      'Zdejmij okulary przeciwsloneczne',
      'Odwzoruj pokazana poze',
    ];

    return tips.map((tip) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppColors.neonPink.withValues(alpha: 0.7),
              size: AppDimensions.iconS,
            ),
            const Gap(AppDimensions.spacing12),
            Expanded(
              child: Text(
                tip,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

// ── Step 2: Camera ──

class _CameraStep extends ConsumerWidget {
  const _CameraStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Camera preview placeholder ──
              Container(
                width: double.infinity,
                color: const Color(0xFF0A0A0A),
                child: const Center(
                  child: Icon(
                    Icons.videocam,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                ),
              ),
              // ── Face outline overlay ──
              CustomPaint(
                size: Size(size.width, size.width * 1.3),
                painter: _FaceOverlayPainter(),
              ),
              // ── Pose indicator ──
              Positioned(
                top: AppDimensions.spacing32,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                    vertical: AppDimensions.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                    border: Border.all(
                      color: AppColors.neonPink.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.back_hand_outlined,
                        color: AppColors.neonBlue,
                        size: AppDimensions.iconS,
                      ),
                      const Gap(AppDimensions.spacing8),
                      Text(
                        'Pokaz znak pokoju',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(
                      duration: const Duration(seconds: 2),
                      color: AppColors.neonPink.withValues(alpha: 0.3),
                    ),
              ),
            ],
          ),
        ),

        // ── Capture button ──
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXL),
          color: AppColors.background,
          child: Center(
            child: GestureDetector(
              onTap: () {
                ref.read(_stepProvider.notifier).state =
                    _VerificationStep.processing;
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.neonPink, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonPinkGlow,
                      blurRadius: AppDimensions.neonBlurMedium,
                      spreadRadius: AppDimensions.neonSpreadSmall,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neonPink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Face overlay painter ──

class _FaceOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 20);
    final ovalWidth = size.width * 0.55;
    final ovalHeight = ovalWidth * 1.35;

    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // Darkened area outside face outline
    final backgroundPath = Path()..addRect(Offset.zero & size);
    final ovalPath = Path()..addOval(ovalRect);
    final combinedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      ovalPath,
    );

    canvas.drawPath(
      combinedPath,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    // Neon face outline
    final borderPaint = Paint()
      ..color = AppColors.neonPink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawOval(ovalRect, borderPaint);

    // Glow effect
    final glowPaint = Paint()
      ..color = AppColors.neonPink.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawOval(ovalRect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Step 3: Processing ──

class _ProcessingStep extends ConsumerStatefulWidget {
  const _ProcessingStep({super.key});

  @override
  ConsumerState<_ProcessingStep> createState() => _ProcessingStepState();
}

class _ProcessingStepState extends ConsumerState<_ProcessingStep> {
  @override
  void initState() {
    super.initState();
    // Simulate processing delay
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        ref.read(_stepProvider.notifier).state = _VerificationStep.result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Animated loading ring ──
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.neonPink,
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(duration: const Duration(seconds: 2)),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceLight,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonPinkGlow,
                        blurRadius: AppDimensions.neonBlurMedium,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.face_retouching_natural,
                    color: AppColors.neonPink,
                    size: 40,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: const Duration(milliseconds: AppDimensions.animSlow)),

          const Gap(AppDimensions.spacing40),

          Text(
            'Weryfikujemy...',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              shadows: AppTheme.neonTextShadow(color: AppColors.neonPink),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn()
              .then()
              .shimmer(
                duration: const Duration(seconds: 2),
                color: AppColors.neonPink.withValues(alpha: 0.4),
              ),

          const Gap(AppDimensions.spacing16),

          Text(
            'To moze potrwac chwile',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 4: Result ──

class _ResultStep extends ConsumerWidget {
  const _ResultStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final success = ref.watch(_verificationSuccessProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: Column(
        children: [
          const Spacer(flex: 2),

          if (success) ...[
            // ── Success ──
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonGreenGlow,
                    blurRadius: AppDimensions.neonBlurLarge,
                    spreadRadius: AppDimensions.neonSpreadMedium,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 72,
              ),
            )
                .animate()
                .fadeIn(duration: const Duration(milliseconds: AppDimensions.animSlow))
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),

            const Gap(AppDimensions.spacing32),

            Text(
              'Zweryfikowano!',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
                shadows: AppTheme.neonTextShadow(color: AppColors.neonGreen),
              ),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 300)),

            const Gap(AppDimensions.spacing12),

            Text(
              'Twoj profil zostal pomyslnie zweryfikowany. Teraz inni uzytkownicy beda widziec badge weryfikacji.',
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 400)),

            // ── Confetti-like dots ──
            const Gap(AppDimensions.spacing24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final colors = [
                  AppColors.neonPink,
                  AppColors.neonGreen,
                  AppColors.neonBlue,
                  AppColors.neonOrange,
                  AppColors.neonPurple,
                ];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors[i],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors[i].withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                )
                    .animate(
                      delay: Duration(milliseconds: 400 + i * 100),
                    )
                    .fadeIn()
                    .scale(begin: const Offset(0, 0), end: const Offset(1, 1))
                    .then()
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 0, end: -8, duration: Duration(milliseconds: 600 + i * 100));
              }),
            ),
          ] else ...[
            // ── Failure ──
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.error,
                size: 72,
              ),
            )
                .animate()
                .fadeIn(duration: const Duration(milliseconds: AppDimensions.animSlow))
                .shake(delay: const Duration(milliseconds: 300)),

            const Gap(AppDimensions.spacing32),

            Text(
              'Sprobuj ponownie',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 300)),

            const Gap(AppDimensions.spacing12),

            Text(
              AppStrings.photoVerificationFailed,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 400)),
          ],

          const Spacer(flex: 3),

          SizedBox(
            width: double.infinity,
            child: NeonButton(
              label: success ? 'Gotowe' : AppStrings.retry,
              icon: success ? Icons.check : Icons.refresh,
              onPressed: () {
                if (success) {
                  context.pop();
                } else {
                  ref.read(_stepProvider.notifier).state =
                      _VerificationStep.instructions;
                }
              },
              gradient: success
                  ? AppColors.neonGreenGradient
                  : AppColors.primaryGradient,
              glowColor: success ? AppColors.neonGreen : AppColors.neonPink,
            ),
          ),

          const Gap(AppDimensions.spacing32),
        ],
      ),
    );
  }
}
