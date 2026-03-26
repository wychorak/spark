import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/core/theme/app_theme.dart';
import 'package:spark/core/router/app_router.dart';
import 'package:spark/shared/providers/profile_provider.dart';
import 'package:spark/shared/widgets/neon_button.dart';

/// Provider for audio player used in Spotify preview
final _audioPlayerProvider = Provider.autoDispose<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

final _isPlayingProvider = StateProvider.autoDispose<bool>((ref) => false);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonPink),
          ),
          error: (_, __) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
            child: Column(
              children: [
                const Gap(AppDimensions.spacing8),
                _TopBar(),
                const Gap(AppDimensions.spacing24),
                _ProfileCard(screenWidth: size.width, profile: null),
                const Gap(AppDimensions.spacing24),
                const _StatsRow(isPremium: false),
                const Gap(AppDimensions.spacing32),
                const _ActionButtons(),
                const Gap(AppDimensions.spacing48),
              ],
            ),
          ),
          data: (profile) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
            child: Column(
              children: [
                const Gap(AppDimensions.spacing8),
                _TopBar(),
                const Gap(AppDimensions.spacing24),
                _ProfileCard(screenWidth: size.width, profile: profile),
                const Gap(AppDimensions.spacing24),
                _StatsRow(isPremium: profile?.isPremium ?? false),
                const Gap(AppDimensions.spacing24),
                _SpotifySection(
                  trackName: profile?.spotifyTrackName,
                  artist: profile?.spotifyArtist,
                ),
                const Gap(AppDimensions.spacing32),
                const _ActionButtons(),
                const Gap(AppDimensions.spacing48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top Bar ──

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppStrings.profileTitle,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            shadows: AppTheme.neonTextShadow(color: AppColors.neonPink),
          ),
        ),
        GestureDetector(
          onTap: () => context.pushNamed(RouteNames.settings),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondary,
              size: AppDimensions.iconM,
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: AppDimensions.animNormal));
  }
}

// ── Profile Card ──

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.screenWidth, required this.profile});
  final double screenWidth;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final cardWidth = screenWidth - AppDimensions.screenPadding * 2;
    final cardHeight = cardWidth * 1.2;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.discoveryCardBorderRadius),
        border: Border.all(
          color: AppColors.neonPink.withValues(alpha: 0.4),
          width: AppDimensions.neonBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonPinkGlow,
            blurRadius: AppDimensions.neonBlurLarge,
            spreadRadius: AppDimensions.neonSpreadSmall,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.discoveryCardBorderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Photo ──
            profile != null && profile!.photoUrls.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: profile!.photoUrls.first,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (_, __) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.neonPink),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.person, size: 120, color: AppColors.textHint),
                      ),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, size: 120, color: AppColors.textHint),
                    ),
                  ),
            // ── Edit overlay button ──
            Positioned(
              top: AppDimensions.paddingM,
              right: AppDimensions.paddingM,
              child: GestureDetector(
                onTap: () => context.pushNamed(RouteNames.editProfile),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.neonPink.withValues(alpha: 0.6),
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.neonPink,
                    size: AppDimensions.iconM,
                  ),
                ),
              ),
            ),
            // ── Bottom gradient & info ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.transparent,
                      AppColors.black.withValues(alpha: 0.8),
                      AppColors.black.withValues(alpha: 0.95),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Name, Age, Verified ──
                    Row(
                      children: [
                        Text(
                          profile?.age != null
                              ? '${profile!.displayName}, ${profile!.age}'
                              : profile?.displayName ?? 'Użytkownik',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (profile?.isVerified == true) ...[
                          const Gap(AppDimensions.spacing8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.neonBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: AppColors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap(AppDimensions.spacing8),
                    // ── Mode Badges ──
                    Wrap(
                      spacing: AppDimensions.spacing8,
                      children: (profile?.modes.isNotEmpty == true
                              ? profile!.modes
                              : ['relationship'])
                          .map((mode) {
                        final color = AppColors.colorForMode(mode);
                        final label = _modeLabelPl(mode);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusRound),
                            border: Border.all(
                              color: color.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            label,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: AppDimensions.animSlow))
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  static String _modeLabelPl(String mode) {
    switch (mode) {
      case 'relationship':
        return AppStrings.onboardingModeRelationship;
      case 'friends':
        return AppStrings.onboardingModeFriends;
      case 'fwb':
        return AppStrings.onboardingModeFWB;
      default:
        return mode;
    }
  }
}

// ── Stats Row ──

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.isPremium});
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: isPremium ? '—' : '?',
            label: 'polubień',
            icon: Icons.favorite,
            color: AppColors.neonPink,
            isBlurred: !isPremium,
          ),
        ),
        const Gap(AppDimensions.spacing16),
        Expanded(
          child: _StatCard(
            value: isPremium ? '—' : '?',
            label: 'matchów',
            icon: Icons.local_fire_department,
            color: AppColors.neonOrange,
            isBlurred: !isPremium,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(
          delay: const Duration(milliseconds: 200),
          duration: const Duration(milliseconds: AppDimensions.animNormal),
        );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.isBlurred = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isBlurred;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.paddingM,
        horizontal: AppDimensions.paddingM,
      ),
      decoration: AppTheme.subtleNeonGlow(color: color),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: AppDimensions.iconL),
              const Gap(AppDimensions.spacing12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // ── Blur overlay for non-premium ──
          if (isBlurred)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: AppColors.transparent,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.lock_outline,
                      color: color.withValues(alpha: 0.8),
                      size: AppDimensions.iconM,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Spotify Section ──

class _SpotifySection extends ConsumerWidget {
  const _SpotifySection({this.trackName, this.artist});
  final String? trackName;
  final String? artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(_isPlayingProvider);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: AppTheme.subtleNeonGlow(
        color: const Color(0xFF1DB954), // Spotify green
      ),
      child: Row(
        children: [
          // ── Spotify icon ──
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              color: Color(0xFF1DB954),
              size: AppDimensions.iconL,
            ),
          ),
          const Gap(AppDimensions.spacing12),
          // ── Track info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Moj hymn',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1DB954),
                    letterSpacing: 1.2,
                  ),
                ),
                const Gap(AppDimensions.spacing2),
                Text(
                  trackName ?? 'Dodaj swój hymn',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: trackName != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Gap(AppDimensions.spacing8),
          // ── Play button ──
          GestureDetector(
            onTap: () {
              ref.read(_isPlayingProvider.notifier).state = !isPlaying;
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF1DB954),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppColors.black,
                size: AppDimensions.iconS,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: const Duration(milliseconds: 300),
          duration: const Duration(milliseconds: AppDimensions.animNormal),
        );
  }
}

// ── Action Buttons ──

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: NeonButton(
            label: AppStrings.profileEdit,
            icon: Icons.edit_outlined,
            onPressed: () => context.pushNamed(RouteNames.editProfile),
          ),
        ),
        const Gap(AppDimensions.spacing16),
        SizedBox(
          width: double.infinity,
          child: NeonOutlinedButton(
            label: 'Podglad profilu',
            icon: Icons.visibility_outlined,
            onPressed: () {
              // Navigate to profile preview showing what others see
              context.pushNamed(
                RouteNames.profileView,
                pathParameters: {'id': 'me'},
              );
            },
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(
          delay: const Duration(milliseconds: 400),
          duration: const Duration(milliseconds: AppDimensions.animNormal),
        );
  }
}
