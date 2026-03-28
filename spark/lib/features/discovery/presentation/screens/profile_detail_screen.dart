import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spark/core/utils/web_audio.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/core/theme/app_theme.dart';


// ─── Profile Detail Screen ──────────────────────────────────

class ProfileDetailScreen extends StatefulWidget {
  final String name;
  final int age;
  final double distanceKm;
  final String mode;
  final List<String> photos;
  final String bio;
  final List<String> interests;
  final bool verified;
  final String? spotifyTrackName;
  final String? spotifyArtist;
  final String? spotifyPreviewUrl;

  const ProfileDetailScreen({
    super.key,
    required this.name,
    required this.age,
    required this.distanceKm,
    required this.mode,
    required this.photos,
    required this.bio,
    required this.interests,
    this.verified = false,
    this.spotifyTrackName,
    this.spotifyArtist,
    this.spotifyPreviewUrl,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final PageController _pageController = PageController();
  final WebAudio _audio = WebAudio();
  bool _isPlaying = false;

  @override
  void dispose() {
    _pageController.dispose();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _toggleSpotifyPlay() async {
    if (widget.spotifyPreviewUrl == null) {
      setState(() => _isPlaying = !_isPlaying);
      return;
    }
    try {
      if (_isPlaying) {
        await _audio.pause();
        setState(() => _isPlaying = false);
      } else {
        await _audio.play(widget.spotifyPreviewUrl!);
        setState(() => _isPlaying = true);
      }
    } catch (_) {
      setState(() => _isPlaying = false);
    }
  }

  void _showReportBlockSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Gap(24),
                ListTile(
                  leading:
                      const Icon(Icons.flag_rounded, color: AppColors.warning),
                  title: Text(
                    AppStrings.matchesReport,
                    style: GoogleFonts.outfit(color: AppColors.warning),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Profil został zgłoszony.')),
                    );
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.block_rounded, color: AppColors.error),
                  title: Text(
                    'Zablokuj',
                    style: GoogleFonts.outfit(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Profil został zablokowany.')),
                    );
                  },
                ),
                const Gap(8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    AppStrings.cancel,
                    style: GoogleFonts.outfit(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeColor = AppColors.colorForMode(widget.mode);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Photo Gallery ──
          SliverToBoxAdapter(
            child: Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.photos.length,
                    itemBuilder: (_, i) {
                      return CachedNetworkImage(
                        imageUrl: widget.photos[i],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.surfaceLight,
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceLight,
                          child: const Icon(Icons.broken_image_rounded,
                              size: 64, color: AppColors.textHint),
                        ),
                      );
                    },
                  ),
                ),

                // Gradient back button
                Positioned(
                  top: topPadding + 8,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.neonPinkGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonPinkGlow,
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.white, size: 22),
                    ),
                  ),
                ),

                // Page indicator
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: widget.photos.length,
                      effect: ExpandingDotsEffect(
                        dotWidth: 8,
                        dotHeight: 8,
                        activeDotColor: modeColor,
                        dotColor: AppColors.white.withValues(alpha: 0.4),
                        expansionFactor: 3,
                        spacing: 6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Profile Info ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name, age, verified
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '${widget.name}, ${widget.age}',
                              style: GoogleFonts.outfit(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                            if (widget.verified) ...[
                              const Gap(8),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.info.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.verified_rounded,
                                    color: AppColors.info, size: 24),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(6),

                  // Distance
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: modeColor, size: 16),
                      const Gap(4),
                      Text(
                        '${widget.distanceKm.toStringAsFixed(1)} ${AppStrings.km}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),

                  // Mode badges
                  _ModeBadge(mode: widget.mode),
                  const Gap(24),

                  // Bio
                  Text(
                    AppStrings.profileAbout,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      shadows: AppTheme.neonTextShadow(
                          blurRadius: AppDimensions.neonBlurSmall),
                    ),
                  ),
                  const Gap(8),
                  Text(
                    widget.bio,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const Gap(24),

                  // Interests
                  Text(
                    AppStrings.profileInterests,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      shadows: AppTheme.neonTextShadow(
                          blurRadius: AppDimensions.neonBlurSmall),
                    ),
                  ),
                  const Gap(12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: widget.interests.map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: modeColor.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusRound),
                          border:
                              Border.all(color: modeColor.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: modeColor.withValues(alpha: 0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          interest,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Gap(24),

                  // Spotify player
                  if (widget.spotifyTrackName != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusL),
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.1),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusS),
                            ),
                            child: const Icon(Icons.music_note_rounded,
                                color: AppColors.success, size: 24),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.spotifyTrackName!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.spotifyArtist != null)
                                  Text(
                                    widget.spotifyArtist!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleSpotifyPlay,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.success.withValues(alpha: 0.2),
                              ),
                              child: Icon(
                                _isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: AppColors.success,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                    const Gap(32),
                  ],

                  // Report / Block
                  Center(
                    child: TextButton.icon(
                      onPressed: _showReportBlockSheet,
                      icon: const Icon(Icons.shield_outlined,
                          color: AppColors.textHint, size: 18),
                      label: Text(
                        '${AppStrings.matchesReport} / Zablokuj',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                  const Gap(32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mode Badge Widget ──────────────────────────────────────

class _ModeBadge extends StatelessWidget {
  final String mode;

  const _ModeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.colorForMode(mode);
    String label;
    switch (mode) {
      case 'friends':
        label = AppStrings.onboardingModeFriends;
        break;
      case 'fwb':
        label = AppStrings.onboardingModeFWB;
        break;
      default:
        label = AppStrings.onboardingModeRelationship;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
