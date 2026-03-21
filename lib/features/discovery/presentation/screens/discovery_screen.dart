import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/core/theme/app_theme.dart';
import 'package:spark/shared/widgets/neon_button.dart';

// ─── Mock Data ───────────────────────────────────────────────

class MockProfile {
  final String id;
  final String name;
  final int age;
  final double distanceKm;
  final String mode; // 'relationship', 'friends', 'fwb'
  final List<String> photos;
  final String bio;
  final List<String> interests;
  final bool verified;
  final String? spotifyTrackName;
  final String? spotifyArtist;
  final String? spotifyPreviewUrl;

  const MockProfile({
    required this.id,
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
}

final List<MockProfile> _mockProfiles = [
  const MockProfile(
    id: '1',
    name: 'Kasia',
    age: 24,
    distanceKm: 3.2,
    mode: 'relationship',
    photos: [
      'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=600',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600',
    ],
    bio: 'Kocham podróże, kawę i dobre książki. Szukam kogoś, z kim mogę odkrywać świat 🌍',
    interests: ['Podróże', 'Fotografia', 'Kawa', 'Joga', 'Książki'],
    verified: true,
    spotifyTrackName: 'Blinding Lights',
    spotifyArtist: 'The Weeknd',
  ),
  const MockProfile(
    id: '2',
    name: 'Maja',
    age: 22,
    distanceKm: 7.8,
    mode: 'friends',
    photos: [
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600',
      'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=600',
    ],
    bio: 'Szukam ekipy na weekendowe wycieczki i wspólne gotowanie!',
    interests: ['Gotowanie', 'Rower', 'Kino', 'Gry planszowe'],
    verified: false,
    spotifyTrackName: 'Levitating',
    spotifyArtist: 'Dua Lipa',
  ),
  const MockProfile(
    id: '3',
    name: 'Ola',
    age: 27,
    distanceKm: 1.5,
    mode: 'fwb',
    photos: [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600',
      'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=600',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=600',
    ],
    bio: 'Bez zobowiązań, z klasą. Lubię spontaniczne spotkania i dobrą muzykę.',
    interests: ['Muzyka', 'Taniec', 'Fitness', 'Wino', 'Sztuka'],
    verified: true,
    spotifyTrackName: 'After Hours',
    spotifyArtist: 'The Weeknd',
  ),
  const MockProfile(
    id: '4',
    name: 'Zuza',
    age: 25,
    distanceKm: 12.0,
    mode: 'relationship',
    photos: [
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=600',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600',
    ],
    bio: 'Programistka z duszą artystki. Szukam kogoś z poczuciem humoru.',
    interests: ['Programowanie', 'Malarstwo', 'Koty', 'Anime', 'Bieganie'],
    verified: true,
    spotifyTrackName: 'As It Was',
    spotifyArtist: 'Harry Styles',
  ),
  const MockProfile(
    id: '5',
    name: 'Ania',
    age: 23,
    distanceKm: 5.4,
    mode: 'friends',
    photos: [
      'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=600',
    ],
    bio: 'Nowa w mieście, chętnie poznam fajnych ludzi na wspólne wyjścia!',
    interests: ['Koncerty', 'Hiking', 'Siatkówka', 'Kuchnia azjatycka'],
    verified: false,
  ),
];

// ─── Providers ───────────────────────────────────────────────

class DiscoveryState {
  final List<MockProfile> profiles;
  final int currentIndex;
  final List<MockProfile> passedProfiles;
  final double distanceFilter;
  final RangeValues ageFilter;
  final Set<String> modeFilters;
  final Set<String> genderFilters;

  const DiscoveryState({
    this.profiles = const [],
    this.currentIndex = 0,
    this.passedProfiles = const [],
    this.distanceFilter = 50.0,
    this.ageFilter = const RangeValues(18, 65),
    this.modeFilters = const {'relationship', 'friends', 'fwb'},
    this.genderFilters = const {'female', 'male', 'nonbinary'},
  });

  DiscoveryState copyWith({
    List<MockProfile>? profiles,
    int? currentIndex,
    List<MockProfile>? passedProfiles,
    double? distanceFilter,
    RangeValues? ageFilter,
    Set<String>? modeFilters,
    Set<String>? genderFilters,
  }) {
    return DiscoveryState(
      profiles: profiles ?? this.profiles,
      currentIndex: currentIndex ?? this.currentIndex,
      passedProfiles: passedProfiles ?? this.passedProfiles,
      distanceFilter: distanceFilter ?? this.distanceFilter,
      ageFilter: ageFilter ?? this.ageFilter,
      modeFilters: modeFilters ?? this.modeFilters,
      genderFilters: genderFilters ?? this.genderFilters,
    );
  }

  bool get hasProfiles => currentIndex < profiles.length;
  MockProfile? get currentProfile =>
      hasProfiles ? profiles[currentIndex] : null;
}

class DiscoveryNotifier extends Notifier<DiscoveryState> {
  @override
  DiscoveryState build() => DiscoveryState(profiles: _mockProfiles);

  void pass() {
    if (!state.hasProfiles) return;
    final passed = [...state.passedProfiles, state.currentProfile!];
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      passedProfiles: passed,
    );
  }

  void like() {
    if (!state.hasProfiles) return;
    state = state.copyWith(currentIndex: state.currentIndex + 1);
  }

  void superLike() {
    if (!state.hasProfiles) return;
    state = state.copyWith(currentIndex: state.currentIndex + 1);
  }

  void undo() {
    if (state.currentIndex <= 0) return;
    state = state.copyWith(currentIndex: state.currentIndex - 1);
  }

  void setDistanceFilter(double value) {
    state = state.copyWith(distanceFilter: value);
  }

  void setAgeFilter(RangeValues value) {
    state = state.copyWith(ageFilter: value);
  }

  void toggleModeFilter(String mode) {
    final modes = Set<String>.from(state.modeFilters);
    if (modes.contains(mode)) {
      modes.remove(mode);
    } else {
      modes.add(mode);
    }
    state = state.copyWith(modeFilters: modes);
  }

  void toggleGenderFilter(String gender) {
    final genders = Set<String>.from(state.genderFilters);
    if (genders.contains(gender)) {
      genders.remove(gender);
    } else {
      genders.add(gender);
    }
    state = state.copyWith(genderFilters: genders);
  }
}

final discoveryProvider =
    NotifierProvider<DiscoveryNotifier, DiscoveryState>(
  DiscoveryNotifier.new,
);

// ─── Discovery Screen ───────────────────────────────────────

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen>
    with TickerProviderStateMixin {
  double _dragX = 0;
  double _dragY = 0;
  late AnimationController _swipeController;
  late AnimationController _particleController;
  // ignore: unused_field
  SwipeDirection? _swipeDirection;
  bool _showParticles = false;
  ParticleType _particleType = ParticleType.heart;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _particleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showParticles = false);
        _particleController.reset();
      }
    });
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragX += details.delta.dx;
      _dragY += details.delta.dy;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3;

    if (_dragX.abs() > threshold || _dragY < -threshold) {
      if (_dragY < -threshold) {
        _triggerSwipe(SwipeDirection.up);
      } else if (_dragX > threshold) {
        _triggerSwipe(SwipeDirection.right);
      } else {
        _triggerSwipe(SwipeDirection.left);
      }
    } else {
      setState(() {
        _dragX = 0;
        _dragY = 0;
      });
    }
  }

  void _triggerSwipe(SwipeDirection direction) {
    _swipeDirection = direction;
    final notifier = ref.read(discoveryProvider.notifier);

    switch (direction) {
      case SwipeDirection.right:
        _showParticleEffect(ParticleType.heart);
        notifier.like();
        break;
      case SwipeDirection.left:
        notifier.pass();
        break;
      case SwipeDirection.up:
        _showParticleEffect(ParticleType.star);
        notifier.superLike();
        break;
    }

    setState(() {
      _dragX = 0;
      _dragY = 0;
    });
  }

  void _showParticleEffect(ParticleType type) {
    setState(() {
      _showParticles = true;
      _particleType = type;
    });
    _particleController.forward();
  }

  void _openFilters() {
    final notifier = ref.read(discoveryProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final current = ref.read(discoveryProvider);
            return Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Gap(16),
                  Text(
                    AppStrings.discoveryFilters,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Gap(24),

                  // Distance slider
                  Text(
                    '${AppStrings.discoveryDistance}: ${current.distanceFilter.round()} ${AppStrings.km}',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.divider,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.neonPinkGlow,
                    ),
                    child: Slider(
                      value: current.distanceFilter,
                      min: 1,
                      max: 150,
                      onChanged: (v) {
                        notifier.setDistanceFilter(v);
                        setSheetState(() {});
                      },
                    ),
                  ),
                  const Gap(16),

                  // Age range slider
                  Text(
                    '${AppStrings.discoveryAgeRange}: ${current.ageFilter.start.round()} - ${current.ageFilter.end.round()} ${AppStrings.years}',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.divider,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.neonPinkGlow,
                    ),
                    child: RangeSlider(
                      values: current.ageFilter,
                      min: 18,
                      max: 65,
                      onChanged: (v) {
                        notifier.setAgeFilter(v);
                        setSheetState(() {});
                      },
                    ),
                  ),
                  const Gap(16),

                  // Mode checkboxes
                  Text(
                    'Tryb',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Gap(8),
                  ...[
                    ('relationship', AppStrings.onboardingModeRelationship,
                        AppColors.modeRelationship),
                    ('friends', AppStrings.onboardingModeFriends,
                        AppColors.modeFriends),
                    ('fwb', AppStrings.onboardingModeFWB, AppColors.modeFWB),
                  ].map((e) {
                    return CheckboxListTile(
                      value: current.modeFilters.contains(e.$1),
                      onChanged: (_) {
                        notifier.toggleModeFilter(e.$1);
                        setSheetState(() {});
                      },
                      title: Text(e.$2,
                          style: TextStyle(color: e.$3, fontSize: 14)),
                      activeColor: e.$3,
                      checkColor: AppColors.black,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  const Gap(16),

                  // Gender checkboxes
                  Text(
                    'Płeć',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Gap(8),
                  ...[
                    ('female', AppStrings.onboardingGenderFemale),
                    ('male', AppStrings.onboardingGenderMale),
                    ('nonbinary', AppStrings.onboardingGenderNonBinary),
                  ].map((e) {
                    return CheckboxListTile(
                      value: current.genderFilters.contains(e.$1),
                      onChanged: (_) {
                        notifier.toggleGenderFilter(e.$1);
                        setSheetState(() {});
                      },
                      title: Text(e.$2,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14)),
                      activeColor: AppColors.primary,
                      checkColor: AppColors.black,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  const Gap(24),
                  SizedBox(
                    width: double.infinity,
                    child: NeonButton(
                      label: AppStrings.done,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  const Gap(16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryProvider);
    final notifier = ref.read(discoveryProvider.notifier);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        centerTitle: true,
        title: Text(
          AppStrings.appName,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            shadows: AppTheme.neonTextShadow(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
            onPressed: _openFilters,
          ),
        ],
      ),
      body: state.hasProfiles
          ? Stack(
              children: [
                // Current card
                _buildSwipeCard(state.currentProfile!, size),

                // Particle overlay
                if (_showParticles)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _particleController,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: ParticlePainter(
                              progress: _particleController.value,
                              type: _particleType,
                              center: Offset(
                                  size.width / 2, size.height / 2 - 60),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Bottom action bar
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: _buildActionBar(notifier),
                ),
              ],
            )
          : _buildEmptyState(),
    );
  }

  Widget _buildSwipeCard(MockProfile profile, Size size) {
    final angle = _dragX / 800;
    final modeColor = AppColors.colorForMode(profile.mode);

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: () => _openProfileDetail(profile),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(_dragX, _dragY)
            ..rotateZ(angle),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                  AppDimensions.discoveryCardBorderRadius),
              border: Border.all(color: modeColor.withValues(alpha: 0.6), width: 2),
              boxShadow: [
                BoxShadow(
                  color: modeColor.withValues(alpha: 0.3),
                  blurRadius: AppDimensions.neonBlurLarge,
                  spreadRadius: AppDimensions.neonSpreadSmall,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                  AppDimensions.discoveryCardBorderRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo
                  CachedNetworkImage(
                    imageUrl: profile.photos.first,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            modeColor.withValues(alpha: 0.3),
                            AppColors.surfaceLight,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: const Icon(Icons.person,
                          size: 80, color: AppColors.textHint),
                    ),
                  ),

                  // Bottom gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 260,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black87,
                            Colors.black,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Info overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + Age
                          Row(
                            children: [
                              Text(
                                '${profile.name}, ${profile.age}',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                              if (profile.verified) ...[
                                const Gap(8),
                                const Icon(Icons.verified,
                                    color: AppColors.info, size: 22),
                              ],
                            ],
                          ),
                          const Gap(4),

                          // Distance
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  color: AppColors.textSecondary, size: 16),
                              const Gap(4),
                              Text(
                                '${profile.distanceKm.toStringAsFixed(1)} ${AppStrings.km}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),

                          // Mode badge
                          _buildModeBadge(profile.mode, modeColor),
                          const Gap(12),

                          // Interests
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: profile.interests
                                .take(4)
                                .map((i) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(
                                            AppDimensions.radiusRound),
                                        border: Border.all(
                                            color:
                                                AppColors.white.withValues(alpha: 0.2)),
                                      ),
                                      child: Text(
                                        i,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const Gap(12),

                          // Spotify mini player
                          if (profile.spotifyTrackName != null)
                            _SpotifyMiniPlayer(
                              trackName: profile.spotifyTrackName!,
                              artist: profile.spotifyArtist ?? '',
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Swipe indicators
                  if (_dragX > 40)
                    Positioned(
                      top: 60,
                      left: 24,
                      child: Transform.rotate(
                        angle: -0.3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: AppColors.success, width: 3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppStrings.discoveryLike,
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_dragX < -40)
                    Positioned(
                      top: 60,
                      right: 24,
                      child: Transform.rotate(
                        angle: 0.3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: AppColors.error, width: 3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppStrings.discoveryDislike,
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_dragY < -40)
                    Positioned(
                      bottom: 200,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.warning, width: 3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppStrings.discoverySuperLike,
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeBadge(String mode, Color color) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
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
  }

  Widget _buildActionBar(DiscoveryNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Undo (premium locked)
        _ActionButton(
          icon: Icons.replay_rounded,
          color: AppColors.warning,
          size: AppDimensions.discoveryActionButtonSize,
          onTap: () {},
          locked: true,
        ),
        // Pass
        _ActionButton(
          icon: Icons.close_rounded,
          color: AppColors.error,
          size: AppDimensions.discoveryActionButtonSizeLarge,
          onTap: () => _triggerSwipe(SwipeDirection.left),
        ),
        // Like
        _ActionButton(
          icon: Icons.favorite_rounded,
          color: AppColors.primary,
          size: AppDimensions.discoveryActionButtonSizeLarge,
          onTap: () => _triggerSwipe(SwipeDirection.right),
        ),
        // Super like
        _ActionButton(
          icon: Icons.star_rounded,
          color: AppColors.warning,
          size: AppDimensions.discoveryActionButtonSize,
          onTap: () => _triggerSwipe(SwipeDirection.up),
        ),
        // Boost (premium locked)
        _ActionButton(
          icon: Icons.bolt_rounded,
          color: AppColors.neonPurple,
          size: AppDimensions.discoveryActionButtonSize,
          onTap: () {},
          locked: true,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.explore_off_rounded,
              size: 80, color: AppColors.textHint),
          const Gap(16),
          Text(
            AppStrings.discoveryEmpty,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  void _openProfileDetail(MockProfile profile) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _FullProfileView(profile: profile),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

// ─── Action Button ──────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final bool locked;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: color, size: size * 0.45),
            if (locked)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock,
                      size: 10, color: AppColors.black),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Spotify Mini Player ────────────────────────────────────

class _SpotifyMiniPlayer extends StatefulWidget {
  final String trackName;
  final String artist;

  const _SpotifyMiniPlayer({
    required this.trackName,
    required this.artist,
  });

  @override
  State<_SpotifyMiniPlayer> createState() => _SpotifyMiniPlayerState();
}

class _SpotifyMiniPlayerState extends State<_SpotifyMiniPlayer> {
  bool _isPlaying = false;

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    // In production: use just_audio AudioPlayer to play 30s preview
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.music_note_rounded,
              color: AppColors.success, size: 18),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.trackName,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.artist,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _togglePlay,
            child: Icon(
              _isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              color: AppColors.success,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Full Profile View (expanded card) ──────────────────────

class _FullProfileView extends StatefulWidget {
  final MockProfile profile;

  const _FullProfileView({required this.profile});

  @override
  State<_FullProfileView> createState() => _FullProfileViewState();
}

class _FullProfileViewState extends State<_FullProfileView> {
  final PageController _pageController = PageController();
  int _currentPhoto = 0;
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final modeColor = AppColors.colorForMode(profile.mode);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Photo PageView
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: profile.photos.length,
                    onPageChanged: (i) => setState(() => _currentPhoto = i),
                    itemBuilder: (_, i) {
                      return CachedNetworkImage(
                        imageUrl: profile.photos[i],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.surfaceLight,
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.neonPinkGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonPinkGlow,
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.white, size: 20),
                    ),
                  ),
                ),

                // Page indicator dots
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 60,
                  right: 16,
                  child: Row(
                    children: List.generate(
                      profile.photos.length,
                      (i) => Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i == _currentPhoto
                                ? AppColors.white
                                : AppColors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Age + Verified
                  Row(
                    children: [
                      Text(
                        '${profile.name}, ${profile.age}',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                      if (profile.verified) ...[
                        const Gap(8),
                        const Icon(Icons.verified,
                            color: AppColors.info, size: 24),
                      ],
                    ],
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.textSecondary, size: 16),
                      const Gap(4),
                      Text(
                        '${profile.distanceKm.toStringAsFixed(1)} ${AppStrings.km}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),

                  // Mode badge
                  _buildModeBadge(profile.mode, modeColor),
                  const Gap(20),

                  // Bio
                  Text(
                    AppStrings.profileAbout,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    profile.bio,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const Gap(20),

                  // Interests
                  Text(
                    AppStrings.profileInterests,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Gap(8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.interests
                        .map((i) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: modeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusRound),
                                border:
                                    Border.all(color: modeColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                i,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AppColors.white,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const Gap(20),

                  // Spotify player
                  if (profile.spotifyTrackName != null)
                    _SpotifyMiniPlayer(
                      trackName: profile.spotifyTrackName!,
                      artist: profile.spotifyArtist ?? '',
                    ),
                  const Gap(40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeBadge(String mode, Color color) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
        ],
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
  }
}

// ─── Particle Painter ───────────────────────────────────────

enum SwipeDirection { left, right, up }

enum ParticleType { heart, star }

class ParticlePainter extends CustomPainter {
  final double progress;
  final ParticleType type;
  final Offset center;
  final Random _random = Random(42);

  ParticlePainter({
    required this.progress,
    required this.type,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final particleCount = 20;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * pi + _random.nextDouble() * 0.5;
      final distance = progress * (100 + _random.nextDouble() * 150);
      final x = center.dx + cos(angle) * distance;
      final y = center.dy + sin(angle) * distance - progress * 50;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final particleSize = (8 + _random.nextDouble() * 8) * (1 - progress * 0.5);

      if (type == ParticleType.heart) {
        paint.color =
            AppColors.primary.withValues(alpha: opacity);
      } else {
        paint.color =
            AppColors.warning.withValues(alpha: opacity);
      }

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
