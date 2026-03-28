import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/core/router/app_router.dart';
import 'package:spark/core/utils/web_audio.dart';
import 'package:spark/shared/providers/profile_provider.dart';

// ── Providers ──

final _webAudioProvider = Provider.autoDispose<WebAudio>((ref) {
  final a = WebAudio();
  ref.onDispose(a.dispose);
  return a;
});
final _isPlayingProvider = StateProvider.autoDispose<bool>((ref) => false);
final _currentPhotoProvider = StateProvider.autoDispose<int>((ref) => 0);

// ── Hex color helper ──
Color _hex(String h) {
  final c = h.replaceAll('#', '');
  return Color(int.parse('FF$c', radix: 16));
}

// ── Profile Screen ──

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.neonPink),
        ),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const Gap(16),
              Text('Nie udało się załadować profilu',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary)),
              const Gap(16),
              GestureDetector(
                onTap: () {
                  final u = Supabase.instance.client.auth.currentUser;
                  if (u != null) ref.invalidate(profileByIdProvider(u.id));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Spróbuj ponownie',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.neonPink));
          }
          return _ProfileBody(profile: profile);
        },
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Parse gradient colors
    final gradStart = (profile.profileGradientStart != null &&
            profile.profileGradientStart!.isNotEmpty)
        ? _hex(profile.profileGradientStart!)
        : AppColors.primary;
    final gradEnd = (profile.profileGradientEnd != null &&
            profile.profileGradientEnd!.isNotEmpty)
        ? _hex(profile.profileGradientEnd!)
        : const Color(0xFFFF9F43);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero sliver ──
        SliverToBoxAdapter(
          child: _HeroCard(
            profile: profile,
            gradStart: gradStart,
            gradEnd: gradEnd,
          ),
        ),

        // ── Content ──
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const Gap(20),
              // Mode + settings row
              _TopRow(profile: profile, gradStart: gradStart, gradEnd: gradEnd),
              const Gap(20),
              // Stats
              _StatsRow(isPremium: profile.isPremium),
              const Gap(16),
              // Song
              if (profile.spotifyTrackName != null &&
                  profile.spotifyTrackName!.isNotEmpty)
                _SongCard(
                  trackName: profile.spotifyTrackName,
                  artist: profile.spotifyArtist,
                  previewUrl: profile.spotifyPreviewUrl,
                  artworkUrl: profile.spotifyArtworkUrl,
                  gradStart: gradStart,
                  gradEnd: gradEnd,
                ),
              // Bio
              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                const Gap(16),
                _BioCard(bio: profile.bio!),
              ],
              // Interests
              if (profile.interests.isNotEmpty) ...[
                const Gap(16),
                _ChipsCard(
                  title: 'Zainteresowania',
                  emoji: '✨',
                  items: profile.interests,
                  chipColor: AppColors.neonPink,
                ),
              ],
              // Desired interests
              if (profile.desiredInterests.isNotEmpty) ...[
                const Gap(16),
                _ChipsCard(
                  title: 'Szukam kogoś kto lubi...',
                  emoji: '🔍',
                  items: profile.desiredInterests,
                  chipColor: AppColors.neonPurple,
                ),
              ],
              // Social media
              if (_hasSocial(profile)) ...[
                const Gap(16),
                _SocialCard(profile: profile),
              ],
              // Gradient strip
              const Gap(16),
              _GradientStrip(gradStart: gradStart, gradEnd: gradEnd),
              const Gap(28),
              // Actions
              _EditButton(),
            ]),
          ),
        ),
      ],
    );
  }

  static bool _hasSocial(UserProfile p) =>
      (p.instagramHandle?.isNotEmpty ?? false) ||
      (p.tiktokHandle?.isNotEmpty ?? false) ||
      (p.snapchatHandle?.isNotEmpty ?? false);
}

// ── Hero Card ──

class _HeroCard extends ConsumerStatefulWidget {
  const _HeroCard({required this.profile, required this.gradStart, required this.gradEnd});
  final UserProfile profile;
  final Color gradStart;
  final Color gradEnd;

  @override
  ConsumerState<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends ConsumerState<_HeroCard> {
  @override
  Widget build(BuildContext context) {
    final photos = widget.profile.photoUrls;
    final currentIdx = ref.watch(_currentPhotoProvider);
    final safeIdx = photos.isEmpty ? 0 : currentIdx.clamp(0, photos.length - 1);
    final screenH = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenH * 0.62,
      child: Stack(
        children: [
          // Photo
          Positioned.fill(
            child: photos.isNotEmpty
                ? GestureDetector(
                    onTapUp: (d) {
                      final x = d.localPosition.dx;
                      final w = context.size?.width ?? 400;
                      if (x < w / 2 && safeIdx > 0) {
                        ref.read(_currentPhotoProvider.notifier).state = safeIdx - 1;
                      } else if (x >= w / 2 && safeIdx < photos.length - 1) {
                        ref.read(_currentPhotoProvider.notifier).state = safeIdx + 1;
                      }
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: CachedNetworkImage(
                        key: ValueKey(safeIdx),
                        imageUrl: photos[safeIdx],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (_, __) => Container(color: AppColors.surface),
                        errorWidget: (_, __, ___) => _placeholder(),
                      ),
                    ),
                  )
                : _placeholder(),
          ),

          // Top bar (tap zones visual indicator)
          if (photos.length > 1)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: List.generate(photos.length, (i) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 3,
                          decoration: BoxDecoration(
                            color: i <= safeIdx
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

          // Settings icon top-right
          Positioned(
            top: 0,
            right: 16,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: GestureDetector(
                  onTap: () => context.pushNamed(RouteNames.settings),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Gradient bottom overlay using profile gradient
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: screenH * 0.28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    widget.gradStart.withValues(alpha: 0.6),
                    widget.gradEnd.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Name + age + verified
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.profile.age != null
                            ? '${widget.profile.displayName}, ${widget.profile.age}'
                            : widget.profile.displayName,
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.profile.isVerified) ...[
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF007AFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 12),
                      ),
                    ],
                  ],
                ),
                if (widget.profile.city != null && widget.profile.city!.isNotEmpty) ...[
                  const Gap(4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                      const Gap(4),
                      Text(
                        widget.profile.city!,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _placeholder() => Container(
        color: AppColors.surface,
        child: Center(
          child: Icon(Icons.person_rounded, size: 80,
              color: AppColors.neonPink.withValues(alpha: 0.15)),
        ),
      );
}

// ── Top Row (modes + header) ──

class _TopRow extends StatelessWidget {
  const _TopRow({required this.profile, required this.gradStart, required this.gradEnd});
  final UserProfile profile;
  final Color gradStart;
  final Color gradEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Mój profil',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        ...profile.modes.map((m) {
          final color = AppColors.colorForMode(m);
          final label = _modeLabel(m);
          return Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          );
        }),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  static String _modeLabel(String m) {
    switch (m) {
      case 'relationship':
        return AppStrings.onboardingModeRelationship;
      case 'friends':
        return AppStrings.onboardingModeFriends;
      case 'fwb':
        return AppStrings.onboardingModeFWB;
      default:
        return m;
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
        Expanded(child: _StatCard(label: 'Polubienia', icon: '💖', isLocked: !isPremium)),
        const Gap(12),
        Expanded(child: _StatCard(label: 'Pary', icon: '🔥', isLocked: !isPremium)),
        const Gap(12),
        Expanded(child: _StatCard(label: 'Odwiedziny', icon: '👀', isLocked: !isPremium)),
      ],
    ).animate().fadeIn(delay: 150.ms, duration: 300.ms);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.icon, this.isLocked = false});
  final String label;
  final String icon;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonPink.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const Gap(4),
              Text(
                isLocked ? '—' : '0',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Gap(2),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          if (isLocked)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.6),
                    child: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.textHint, size: 20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Song Card (web audio) ──

class _SongCard extends ConsumerWidget {
  const _SongCard({
    this.trackName,
    this.artist,
    this.previewUrl,
    this.artworkUrl,
    required this.gradStart,
    required this.gradEnd,
  });
  final String? trackName;
  final String? artist;
  final String? previewUrl;
  final String? artworkUrl;
  final Color gradStart;
  final Color gradEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(_isPlayingProvider);
    final hasPreview = previewUrl != null && previewUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () async {
        if (!hasPreview) return;
        final audio = ref.read(_webAudioProvider);
        if (isPlaying) {
          await audio.pause();
          ref.read(_isPlayingProvider.notifier).state = false;
        } else {
          try {
            await audio.play(previewUrl!);
            ref.read(_isPlayingProvider.notifier).state = true;
          } catch (_) {
            ref.read(_isPlayingProvider.notifier).state = false;
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradStart.withValues(alpha: 0.08),
              gradEnd.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: gradStart.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            // Album art or gradient vinyl
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: artworkUrl == null || artworkUrl!.isEmpty
                    ? LinearGradient(
                        colors: [gradStart, gradEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: gradStart.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: artworkUrl != null && artworkUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        artworkUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    )
                  : Icon(
                      isPlaying ? Icons.pause_rounded : Icons.music_note_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ULUBIONA PIOSENKA',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: gradStart,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    trackName ?? 'Brak',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (artist != null)
                    Text(
                      artist!,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (hasPreview) ...[
              const Gap(8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [gradStart, gradEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }
}

// ── Bio Card ──

class _BioCard extends StatelessWidget {
  const _BioCard({required this.bio});
  final String bio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonPink.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💬', style: TextStyle(fontSize: 16)),
              const Gap(8),
              Text(
                'O mnie',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const Gap(10),
          Text(
            bio,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 300.ms);
  }
}

// ── Chips Card ──

class _ChipsCard extends StatelessWidget {
  const _ChipsCard({
    required this.title,
    required this.emoji,
    required this.items,
    required this.chipColor,
  });
  final String title;
  final String emoji;
  final List<String> items;
  final Color chipColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: chipColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const Gap(8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const Gap(12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: chipColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  item,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: chipColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }
}

// ── Social Card ──

class _SocialCard extends StatelessWidget {
  const _SocialCard({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final socials = <(IconData, String, String, Color)>[];
    if (profile.instagramHandle?.isNotEmpty ?? false) {
      socials.add((Icons.camera_alt_outlined, 'Instagram',
          '@${profile.instagramHandle}', const Color(0xFFE1306C)));
    }
    if (profile.tiktokHandle?.isNotEmpty ?? false) {
      socials.add((Icons.music_video_outlined, 'TikTok',
          '@${profile.tiktokHandle}', const Color(0xFF000000)));
    }
    if (profile.snapchatHandle?.isNotEmpty ?? false) {
      socials.add((Icons.chat_bubble_outline_rounded, 'Snapchat',
          '@${profile.snapchatHandle}', const Color(0xFFFFFC00)));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonPink.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌐', style: TextStyle(fontSize: 16)),
              const Gap(8),
              Text(
                'Social media',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const Gap(12),
          ...socials.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: s.$4.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(s.$1, size: 18, color: s.$4),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$2,
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                  fontWeight: FontWeight.w500)),
                          Text(s.$3,
                              style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.textHint),
                  ],
                ),
              )),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms, duration: 300.ms);
  }
}

// ── Gradient Strip ──

class _GradientStrip extends StatelessWidget {
  const _GradientStrip({required this.gradStart, required this.gradEnd});
  final Color gradStart;
  final Color gradEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [gradStart, gradEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradStart.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.palette_outlined, color: Colors.white, size: 18),
          const Gap(8),
          Text(
            'Mój kolor profilu',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 300.ms);
  }
}

// ── Edit Button ──

class _EditButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(RouteNames.editProfile),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neonPink, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_outlined, color: AppColors.neonPink, size: 18),
            const Gap(8),
            Text(
              AppStrings.profileEdit,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.neonPink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
