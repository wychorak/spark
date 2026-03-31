import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spark/core/services/privacy_preferences_service.dart';
import 'package:spark/core/utils/web_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/features/matching/presentation/screens/match_screen.dart';
import 'package:spark/shared/providers/profile_provider.dart';

// ─── Interest emojis ────────────────────────────────────────

const Map<String, String> _kDiscoveryInterestEmojis = {
  'Muzyka': '🎵', 'Film': '🎬', 'Ksiazki': '📚', 'Gry': '🎮',
  'Sport': '⚽', 'Silownia': '🏋️', 'Joga': '🧘', 'Sztuka': '🎨',
  'Fotografia': '📸', 'Podroze': '✈️', 'Gotowanie': '🍳', 'Wino': '🍷',
  'Kawa': '☕', 'Psy': '🐕', 'Koty': '🐈', 'Natura': '🌿',
  'Teatr': '🎭', 'Taniec': '💃', 'Karaoke': '🎤', 'Wspinaczka': '🧗',
  'Rower': '🚴', 'Plywanie': '🏊', 'Podcasty': '🎧', 'Technologia': '💻',
  'Ekologia': '♻️', 'Festiwale': '🎪', 'Stand-up': '🎙️', 'Netflix': '📺',
  'Astrologia': '♈', 'Piwo': '🍺',
};

// ─── Haversine distance ──────────────────────────────────────

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * (pi / 180);
  final dLon = (lon2 - lon1) * (pi / 180);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * (pi / 180)) *
          cos(lat2 * (pi / 180)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

// ─── Discovery Profile ──────────────────────────────────────

class DiscoveryProfile {
  final String id;
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
  final String? spotifyArtworkUrl;
  final String? city;
  final String? gender;
  final double? score;
  final Color? profileGradientStart;
  final Color? profileGradientEnd;

  const DiscoveryProfile({
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
    this.spotifyArtworkUrl,
    this.city,
    this.gender,
    this.score,
    this.profileGradientStart,
    this.profileGradientEnd,
  });
}

// ─── Empty state (no mock data) ─────────────────────────────

// ─── Providers ──────────────────────────────────────────────

class DiscoveryState {
  final List<DiscoveryProfile> profiles;
  final int currentIndex;
  final List<DiscoveryProfile> passedProfiles;
  final double distanceFilter;
  final RangeValues ageFilter;
  final Set<String> modeFilters;
  final Set<String> genderFilters;
  final bool isLoading;
  final String? error;

  const DiscoveryState({
    this.profiles = const [],
    this.currentIndex = 0,
    this.passedProfiles = const [],
    this.distanceFilter = 50.0,
    this.ageFilter = const RangeValues(18, 65),
    this.modeFilters = const {'relationship', 'friends', 'fwb'},
    this.genderFilters = const {'female', 'male', 'nonbinary'},
    this.isLoading = false,
    this.error,
  });

  DiscoveryState copyWith({
    List<DiscoveryProfile>? profiles,
    int? currentIndex,
    List<DiscoveryProfile>? passedProfiles,
    double? distanceFilter,
    RangeValues? ageFilter,
    Set<String>? modeFilters,
    Set<String>? genderFilters,
    bool? isLoading,
    String? error,
  }) {
    return DiscoveryState(
      profiles: profiles ?? this.profiles,
      currentIndex: currentIndex ?? this.currentIndex,
      passedProfiles: passedProfiles ?? this.passedProfiles,
      distanceFilter: distanceFilter ?? this.distanceFilter,
      ageFilter: ageFilter ?? this.ageFilter,
      modeFilters: modeFilters ?? this.modeFilters,
      genderFilters: genderFilters ?? this.genderFilters,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get hasProfiles => currentIndex < profiles.length;
  DiscoveryProfile? get currentProfile =>
      hasProfiles ? profiles[currentIndex] : null;
}

class DiscoveryNotifier extends Notifier<DiscoveryState> {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  DiscoveryState build() {
    Future.microtask(() => _loadProfiles());
    return const DiscoveryState(isLoading: true);
  }

  Future<void> _loadProfiles() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
    } catch (_) {}
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        state = DiscoveryState(profiles: const <DiscoveryProfile>[], isLoading: false);
        return;
      }

      final Set<String> blockedIds = {};
      try {
        final blocksRes = await _supabase
            .from('blocks')
            .select('blocked_id')
            .eq('blocker_id', userId);
        for (final b in blocksRes) {
          blockedIds.add(b['blocked_id'] as String);
        }
        final blockedByRes = await _supabase
            .from('blocks')
            .select('blocker_id')
            .eq('blocked_id', userId);
        for (final b in blockedByRes) {
          blockedIds.add(b['blocker_id'] as String);
        }
      } catch (_) {}

      final Set<String> swipedIds = {};
      try {
        final swipesRes = await _supabase
            .from('swipe_actions')
            .select('target_id')
            .eq('user_id', userId);
        for (final s in swipesRes) {
          swipedIds.add(s['target_id'] as String);
        }
      } catch (_) {}

      // Get current user's location
      double? myLat;
      double? myLon;
      try {
        final myProfile = await _supabase
            .from('user_profiles')
            .select('latitude, longitude')
            .eq('id', userId)
            .maybeSingle();
        if (myProfile != null) {
          myLat = (myProfile['latitude'] as num?)?.toDouble();
          myLon = (myProfile['longitude'] as num?)?.toDouble();
        }
      } catch (_) {}

      List<dynamic> data = const [];
      if (myLat != null && myLon != null) {
        final response = await _supabase.rpc(
          'fn_discover_profiles',
          params: {
            'p_user_id': userId,
            'p_lon': myLon,
            'p_lat': myLat,
            'p_radius_km': state.distanceFilter.round(),
            'p_min_age': state.ageFilter.start.round(),
            'p_max_age': state.ageFilter.end.round(),
            'p_genders': state.genderFilters.toList(),
            'p_modes': state.modeFilters.toList(),
            'p_limit': 50,
          },
        ).timeout(const Duration(seconds: 10));
        data = response as List<dynamic>;
      } else {
        final response = await _supabase
            .from('user_profiles')
            .select('*')
            .neq('id', userId)
            .eq('is_active', true)
            .eq('account_status', 'active')
            .limit(50)
            .timeout(const Duration(seconds: 10));
        data = response as List<dynamic>;
      }

      if (data.isEmpty) {
        state = DiscoveryState(profiles: const <DiscoveryProfile>[], isLoading: false);
        return;
      }

      final profileIds = data
          .map((row) => (row['profile_id'] ?? row['id'])?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      final extraProfiles = <String, Map<String, dynamic>>{};
      final photosByUser = <String, List<String>>{};
      final interestsByUser = <String, List<String>>{};

      try {
        final rows = await _supabase
            .from('user_profiles')
            .select(
              'id, profile_gradient_start, profile_gradient_end, spotify_artwork_url, modes, city',
            )
            .inFilter('id', profileIds);
        for (final row in rows as List) {
          final id = row['id']?.toString();
          if (id == null || id.isEmpty) continue;
          extraProfiles[id] = Map<String, dynamic>.from(row as Map);
        }
      } catch (_) {}

      try {
        final photoRows = await _supabase
            .from('user_photos')
            .select('user_id, storage_path, position')
            .inFilter('user_id', profileIds)
            .order('position', ascending: true);
        for (final row in photoRows as List) {
          final userPhotoId = row['user_id']?.toString();
          final path = row['storage_path']?.toString();
          if (userPhotoId == null || userPhotoId.isEmpty || path == null || path.isEmpty) {
            continue;
          }
          final url = path.startsWith('http')
              ? path
              : _supabase.storage.from('photos').getPublicUrl(path);
          photosByUser.putIfAbsent(userPhotoId, () => <String>[]).add(url);
        }
      } catch (_) {}

      try {
        final intRows = await _supabase
            .from('user_interests')
            .select('user_id, interests(name)')
            .inFilter('user_id', profileIds);
        for (final row in intRows as List) {
          final interestUserId = row['user_id']?.toString();
          final interestMap = row['interests'];
          final interestName = interestMap is Map ? interestMap['name']?.toString() : null;
          if (interestUserId == null ||
              interestUserId.isEmpty ||
              interestName == null ||
              interestName.isEmpty) {
            continue;
          }
          interestsByUser.putIfAbsent(interestUserId, () => <String>[]).add(interestName);
        }
      } catch (_) {}

      final profiles = <DiscoveryProfile>[];
      for (final row in data) {
        final profileId = (row['profile_id'] ?? row['id'])?.toString() ?? '';

        if (blockedIds.contains(profileId) || swipedIds.contains(profileId)) {
          continue;
        }

        final extra = extraProfiles[profileId] ?? const <String, dynamic>{};
        final photoUrls = photosByUser[profileId] ?? const <String>[];
        final interests = interestsByUser[profileId] ?? const <String>[];

        final rawModes = row['modes'] ?? extra['modes'];
        List<String> modesList = [];
        if (rawModes is List) {
          modesList = rawModes.map((e) => e.toString()).toList();
        } else if (rawModes is String) {
          final cleaned = rawModes.replaceAll('{', '').replaceAll('}', '');
          modesList = cleaned.split(',').where((s) => s.isNotEmpty).toList();
        }
        final mode = modesList.isNotEmpty ? modesList.first : 'relationship';

        int age = 0;
        final bornAt = row['born_at'];
        if (bornAt != null) {
          final born = DateTime.tryParse(bornAt.toString());
          if (born != null) {
            final now = DateTime.now();
            age = now.year -
                born.year -
                (now.month < born.month ||
                        (now.month == born.month && now.day < born.day)
                    ? 1
                    : 0);
          }
        }

        if (age < state.ageFilter.start || age > state.ageFilter.end) continue;
        final gender = row['gender']?.toString() ?? 'other';
        if (myLat == null || myLon == null) {
          if (!state.genderFilters.contains(gender)) continue;
          if (!modesList.any((m) => state.modeFilters.contains(m))) continue;
        }

        Color? gradStart;
        Color? gradEnd;
        final gsRaw = extra['profile_gradient_start'];
        final geRaw = extra['profile_gradient_end'];
        if (gsRaw is String && gsRaw.isNotEmpty) {
          gradStart = _parseHexColor(gsRaw);
        }
        if (geRaw is String && geRaw.isNotEmpty) {
          gradEnd = _parseHexColor(geRaw);
        }

        // Calculate real distance
        double distanceKm = 0.0;
        final theirLat = (row['latitude'] as num?)?.toDouble();
        final theirLon = (row['longitude'] as num?)?.toDouble();
        if (myLat != null && myLon != null && theirLat != null && theirLon != null) {
          distanceKm = _haversineKm(myLat, myLon, theirLat, theirLon);
        } else {
          distanceKm = -1;
        }

        final city = (row['city'] ?? extra['city'])?.toString();

        profiles.add(DiscoveryProfile(
          id: profileId,
          name: row['display_name']?.toString() ?? '',
          age: age,
          distanceKm: distanceKm,
          mode: mode,
          photos: photoUrls.isNotEmpty
              ? photoUrls
              : const [],
          bio: row['bio']?.toString() ?? '',
          interests: interests,
          verified: row['is_verified'] == true,
          spotifyTrackName: row['spotify_track_name']?.toString(),
          spotifyArtist: row['spotify_artist_name']?.toString(),
          spotifyPreviewUrl: row['spotify_preview_url']?.toString(),
          spotifyArtworkUrl: extra['spotify_artwork_url']?.toString(),
          city: city,
          gender: gender,
          score: (row['score'] as num?)?.toDouble(),
          profileGradientStart: gradStart,
          profileGradientEnd: gradEnd,
        ));
      }

      if (profiles.isEmpty) {
        state = DiscoveryState(profiles: const <DiscoveryProfile>[], isLoading: false);
        return;
      }

      state = state.copyWith(
        profiles: profiles,
        currentIndex: 0,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Discovery error: $e');
      state = DiscoveryState(profiles: const <DiscoveryProfile>[], isLoading: false);
    }
  }

  static Color? _parseHexColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      if (cleaned.length == 6) {
        return Color(int.parse('FF$cleaned', radix: 16));
      }
      if (cleaned.length == 8) {
        return Color(int.parse(cleaned, radix: 16));
      }
    } catch (_) {}
    return null;
  }

  Future<void> refresh() async {
    state = state.copyWith(currentIndex: 0, passedProfiles: []);
    await _loadProfiles();
  }

  Future<bool> _recordSwipeAction(String action) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null || !state.hasProfiles) return false;

      final targetId = state.currentProfile!.id;

      final swipeAccepted = await _supabase.rpc(
        'fn_submit_swipe_action',
        params: {
          'p_target_id': targetId,
          'p_action': action,
        },
      );

      if (swipeAccepted != true) {
        return false;
      }

      if (action == 'like' || action == 'superlike') {
        final matchCheck = await _supabase
            .from('matches')
            .select('id')
            .eq('is_active', true)
            .or('and(user1_id.eq.$userId,user2_id.eq.$targetId),and(user1_id.eq.$targetId,user2_id.eq.$userId)')
            .maybeSingle();
        return matchCheck != null;
      }
    } catch (e) {
      debugPrint('Swipe action error: $e');
    }
    return false;
  }

  DiscoveryProfile? _lastLikedProfile;
  bool _hasNewMatch = false;

  bool get hasNewMatch => _hasNewMatch;
  DiscoveryProfile? get lastLikedProfile => _lastLikedProfile;
  void clearNewMatch() => _hasNewMatch = false;

  void pass() {
    if (!state.hasProfiles) return;
    final passed = [...state.passedProfiles, state.currentProfile!];
    _recordSwipeAction('pass');
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      passedProfiles: passed,
    );
  }

  Future<void> like() async {
    if (!state.hasProfiles) return;
    _lastLikedProfile = state.currentProfile;
    final matched = await _recordSwipeAction('like');
    _hasNewMatch = matched;
    state = state.copyWith(currentIndex: state.currentIndex + 1);
  }

  Future<void> superLike() async {
    if (!state.hasProfiles) return;
    _lastLikedProfile = state.currentProfile;
    final matched = await _recordSwipeAction('superlike');
    _hasNewMatch = matched;
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

  Future<bool> sendChatRequest(String targetId, String message) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      await _supabase.rpc(
        'fn_submit_chat_request',
        params: {
          'p_receiver_id': targetId,
          'p_message': message,
          'p_conversation_id': null,
        },
      );
      return true;
    } catch (e) {
      debugPrint('Chat request error: $e');
      return false;
    }
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

  Future<void> resetFilters() async {
    state = state.copyWith(
      distanceFilter: 50.0,
      ageFilter: const RangeValues(18, 65),
      modeFilters: {'relationship', 'friends', 'fwb'},
      genderFilters: {'female', 'male', 'nonbinary'},
      currentIndex: 0,
      passedProfiles: const [],
    );
    await _loadProfiles();
  }
}

final discoveryProvider =
    NotifierProvider<DiscoveryNotifier, DiscoveryState>(
  DiscoveryNotifier.new,
);

// ─── Image Preloader ────────────────────────────────────────

class _ImagePreloader {
  static final Set<String> _preloadedUrls = {};

  static void preloadImages(BuildContext context, List<DiscoveryProfile> profiles, int currentIndex) {
    for (int i = currentIndex + 1; i <= currentIndex + 2 && i < profiles.length; i++) {
      if (profiles[i].photos.isEmpty) continue;
      final photo = profiles[i].photos.first;
      if (!_preloadedUrls.contains(photo)) {
        _preloadedUrls.add(photo);
        precacheImage(
          NetworkImage(photo),
          context,
        );
      }
    }
  }
}

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
  int _currentPhotoIndex = 0;
  bool _showDistance = true;
  bool get _isPremium {
      final profileAsync = ref.read(currentProfileProvider);
      return profileAsync.when(
        data: (p) => p?.isPremium ?? false,
        loading: () => false,
        error: (_, __) => false,
      );
  }

  @override
  void initState() {
    super.initState();
    _loadPrivacyPreferences();
  }

  Future<void> _loadPrivacyPreferences() async {
    final showDistance =
        await PrivacyPreferencesService.instance.getShowDistance();
    if (!mounted) return;
    setState(() => _showDistance = showDistance);
  }

  bool _hasActiveFilters(DiscoveryState state) {
    return state.distanceFilter != 50.0 ||
        state.ageFilter != const RangeValues(18, 65) ||
        state.modeFilters.length != 3 ||
        state.genderFilters.length != 3;
  }

  List<String> _activeFilterLabels(DiscoveryState state) {
    final labels = <String>[];

    if (state.distanceFilter != 50.0) {
      labels.add('Do ${state.distanceFilter.round()} km');
    }

    if (state.ageFilter != const RangeValues(18, 65)) {
      labels.add(
        '${state.ageFilter.start.round()}-${state.ageFilter.end.round()} lat',
      );
    }

    if (state.modeFilters.length != 3) {
      labels.add(
        state.modeFilters
            .map((mode) => mode == 'relationship'
                ? 'Związek'
                : mode == 'friends'
                    ? 'Znajomi'
                    : 'FWB')
            .join(' • '),
      );
    }

    if (state.genderFilters.length != 3) {
      labels.add(
        state.genderFilters
            .map((gender) => gender == 'female'
                ? 'Kobiety'
                : gender == 'male'
                    ? 'Mężczyźni'
                    : 'Niebinarni')
            .join(' • '),
      );
    }

    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryProvider);
    final notifier = ref.read(discoveryProvider.notifier);
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final hasActiveFilters = _hasActiveFilters(state);

    if (!state.isLoading && state.hasProfiles) {
      _ImagePreloader.preloadImages(context, state.profiles, state.currentIndex);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          if (state.isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            )
          else if (state.hasProfiles)
            RepaintBoundary(
              child: _buildSwipeCard(
                state.currentProfile!,
                size,
                hasActiveFilters: hasActiveFilters,
              ),
            )
          else
            _buildEmptyState(hasActiveFilters: hasActiveFilters),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _DiscoveryHeader(
              topPadding: topPadding,
              onFilterTap: () => _openFilters(),
            ),
          ),

          if (hasActiveFilters)
            Positioned(
              top: topPadding + 68,
              left: 12,
              right: 12,
              child: SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._activeFilterLabels(state).map(
                      (label) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.divider.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: notifier.resetFilters,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Wyczyść',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom action bar
          if (!state.isLoading && state.hasProfiles)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _ActionBar(
                isPremium: _isPremium,
                onPass: () => _triggerSwipe(SwipeDirection.left),
                onSmash: () => _triggerSwipe(SwipeDirection.right),
                onSuperLike: () => _triggerSwipe(SwipeDirection.up),
                onUndo: () {
                  if (_isPremium) {
                    notifier.undo();
                    setState(() => _currentPhotoIndex = 0);
                  } else {
                    _showPremiumPrompt();
                  }
                },
                onChat: () => _showChatRequestSheet(state.currentProfile!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwipeCard(
    DiscoveryProfile profile,
    Size size, {
    required bool hasActiveFilters,
  }) {
    final angle = _dragX / 900;
    final topPadding = MediaQuery.of(context).padding.top;

    final gradStart = profile.profileGradientStart ?? const Color(0xFFFF6B9D);
    final gradEnd = profile.profileGradientEnd ?? const Color(0xFFFF9F43);

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _dragX += details.delta.dx;
          _dragY += details.delta.dy;
        });
      },
      onPanEnd: (details) {
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
      },
      onTapUp: (details) {
        final cardWidth = size.width - 20;
        final tapX = details.localPosition.dx;
        if (profile.photos.length > 1) {
          if (tapX < cardWidth * 0.35) {
            if (_currentPhotoIndex > 0) {
              setState(() => _currentPhotoIndex--);
            }
          } else if (tapX > cardWidth * 0.65) {
            if (_currentPhotoIndex < profile.photos.length - 1) {
              setState(() => _currentPhotoIndex++);
            }
          } else {
            _openProfileDetail(profile);
          }
        } else {
          _openProfileDetail(profile);
        }
      },
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..translate(_dragX, _dragY * 0.4)
          ..rotateZ(angle),
        child: Container(
          margin: EdgeInsets.fromLTRB(
            10,
            topPadding + (hasActiveFilters ? 108 : 70),
            10,
            130,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: const Color(0xFFFFF5F7),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 18,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Full-card photo ─────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: profile.photos.isEmpty
                      ? Container(
                          key: const ValueKey('no_photo'),
                          color: const Color(0xFFFFF0F5),
                          child: Center(
                            child: Icon(Icons.person_rounded,
                                size: 100,
                                color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                        )
                      : Image.network(
                    profile.photos[_currentPhotoIndex.clamp(0, profile.photos.length - 1)],
                    key: ValueKey('${profile.id}_$_currentPhotoIndex'),
                    fit: BoxFit.cover,
                    cacheWidth: 600,
                    cacheHeight: 900,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.surfaceLight,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceLight,
                      child: Icon(Icons.person_rounded,
                          size: 80,
                          color: AppColors.textHint.withValues(alpha: 0.3)),
                    ),
                  ),
                ),

                // Top gradient for dots
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.28),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Photo dots
                if (profile.photos.length > 1)
                  Positioned(
                    top: 12, left: 14, right: 14,
                    child: _PhotoDotsIndicator(
                      count: profile.photos.length,
                      current: _currentPhotoIndex,
                    ),
                  ),

                // Swipe SPARK! indicator
                if (_dragX > 30)
                  Positioned(
                    top: 50, left: 20,
                    child: Transform.rotate(
                      angle: -0.35,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary, width: 3),
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                        child: Text('SPARK! ✨',
                          style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800,
                              color: AppColors.primary, letterSpacing: 1.5)),
                      ),
                    ),
                  ),

                // Swipe PASS indicator
                if (_dragX < -30)
                  Positioned(
                    top: 50, right: 20,
                    child: Transform.rotate(
                      angle: 0.35,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400, width: 3),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.withValues(alpha: 0.08),
                        ),
                        child: Text('PASS',
                          style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800,
                              color: Colors.grey.shade500, letterSpacing: 1.5)),
                      ),
                    ),
                  ),

                // Swipe UP superlike
                if (_dragY < -30)
                  Positioned(
                    bottom: 180, left: 0, right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFFFBF00), width: 3),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFFFBF00).withValues(alpha: 0.08),
                        ),
                        child: Text('⭐ SUPER LIKE',
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800,
                              color: const Color(0xFFFFBF00), letterSpacing: 1.5)),
                      ),
                    ),
                  ),

                // ── Liquid glass info panel at bottom ───────
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: _ProfileInfoPanel(
                    profile: profile,
                    gradStart: gradStart,
                    gradEnd: gradEnd,
                    showDistance: _showDistance,
                  ),
                ),

                // ── Report/Block button ──────────────────────
                Positioned(
                  top: 14,
                  right: 14,
                  child: GestureDetector(
                    onTap: () => _showReportBlockSheet(context, profile),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _triggerSwipe(SwipeDirection direction) async {
    final notifier = ref.read(discoveryProvider.notifier);

    switch (direction) {
      case SwipeDirection.right:
        await notifier.like();
        break;
      case SwipeDirection.left:
        notifier.pass();
        break;
      case SwipeDirection.up:
        if (_isPremium) {
          await notifier.superLike();
        } else {
          _showPremiumPrompt();
          setState(() {
            _dragX = 0;
            _dragY = 0;
          });
          return;
        }
        break;
    }

    setState(() {
      _dragX = 0;
      _dragY = 0;
      _currentPhotoIndex = 0;
    });

    if (notifier.hasNewMatch && notifier.lastLikedProfile != null && mounted) {
      notifier.clearNewMatch();
      final matched = notifier.lastLikedProfile!;
      await Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => MatchScreen(
            matchPhotoUrl:
                matched.photos.isNotEmpty ? matched.photos.first : '',
            matchName: matched.name,
            onSendMessage: () => Navigator.pop(context),
            onContinueBrowsing: () => Navigator.pop(context),
          ),
        ),
      );
    }
  }

  void _showPremiumPrompt() {
    Navigator.of(context).pushNamed('/premium');
  }

  void _showChatRequestSheet(DiscoveryProfile profile) {
    if (!_isPremium) {
      _showPremiumPrompt();
      return;
    }
    final msgController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36, height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.textHint.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const Gap(20),
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_rounded, color: AppColors.primary, size: 22),
                        const Gap(10),
                        Expanded(
                          child: Text(
                            'Wyślij wiadomość do ${profile.name}',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    Text(
                      '${profile.name} musi zaakceptować Twoją wiadomość, aby móc rozmawiać.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Gap(16),
                    TextField(
                      controller: msgController,
                      autofocus: true,
                      maxLines: 3,
                      maxLength: 200,
                      style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Napisz coś miłego...',
                        hintStyle: GoogleFonts.outfit(color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const Gap(12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                        label: Text(
                          'Wyślij prośbę',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () async {
                          final msg = msgController.text.trim();
                          if (msg.isEmpty) return;
                          Navigator.pop(ctx);
                          final ok = await ref
                              .read(discoveryProvider.notifier)
                              .sendChatRequest(profile.id, msg);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Prośba o czat wysłana do ${profile.name}!'
                                      : 'Nie udało się wysłać prośby.',
                                  style: GoogleFonts.outfit(),
                                ),
                                backgroundColor: ok ? AppColors.success : AppColors.error,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({required bool hasActiveFilters}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.explore_outlined,
                size: 44,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            const Gap(24),
            Text(
              hasActiveFilters
                  ? 'Nic nie pasuje do wybranych filtrów.'
                  : AppStrings.discoveryEmpty,
              style: GoogleFonts.outfit(
                fontSize: 20,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(12),
            Text(
              hasActiveFilters
                  ? 'Poszerz wiek albo dystans, żeby zobaczyć więcej osób.'
                  : 'Odśwież discovery albo wróć za chwilę. Nowe profile pojawiają się regularnie.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                if (hasActiveFilters)
                  GestureDetector(
                    onTap: () => ref.read(discoveryProvider.notifier).resetFilters(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Poszerz filtry',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () => ref.read(discoveryProvider.notifier).refresh(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                        'Odśwież',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openFilters() {
    final notifier = ref.read(discoveryProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final current = ref.read(discoveryProvider);
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.textHint.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const Gap(20),
                        Text(
                          AppStrings.discoveryFilters,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Gap(28),
                        Text(
                          '${AppStrings.discoveryDistance}: ${current.distanceFilter.round()} km',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Gap(4),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.textHint.withValues(alpha: 0.2),
                            thumbColor: AppColors.primary,
                            overlayColor: AppColors.primary.withValues(alpha: 0.15),
                            trackHeight: 3,
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
                        Text(
                          '${AppStrings.discoveryAgeRange}: ${current.ageFilter.start.round()} - ${current.ageFilter.end.round()} lat',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Gap(4),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.textHint.withValues(alpha: 0.2),
                            thumbColor: AppColors.primary,
                            overlayColor: AppColors.primary.withValues(alpha: 0.15),
                            trackHeight: 3,
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
                        const Gap(20),
                        Text(
                          'Tryb',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Gap(10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ('relationship', AppStrings.onboardingModeRelationship, AppColors.modeRelationship),
                            ('friends', AppStrings.onboardingModeFriends, AppColors.modeFriends),
                            ('fwb', AppStrings.onboardingModeFWB, AppColors.modeFWB),
                          ].map((e) {
                            final selected = current.modeFilters.contains(e.$1);
                            return GestureDetector(
                              onTap: () {
                                notifier.toggleModeFilter(e.$1);
                                setSheetState(() {});
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? e.$3.withValues(alpha: 0.15) : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected ? e.$3.withValues(alpha: 0.5) : AppColors.divider,
                                  ),
                                ),
                                child: Text(
                                  e.$2,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: selected ? e.$3 : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const Gap(20),
                        Text(
                          'Plec',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Gap(10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ('female', AppStrings.onboardingGenderFemale),
                            ('male', AppStrings.onboardingGenderMale),
                            ('nonbinary', AppStrings.onboardingGenderNonBinary),
                          ].map((e) {
                            final selected = current.genderFilters.contains(e.$1);
                            return GestureDetector(
                              onTap: () {
                                notifier.toggleGenderFilter(e.$1);
                                setSheetState(() {});
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary.withValues(alpha: 0.4)
                                        : AppColors.divider,
                                  ),
                                ),
                                child: Text(
                                  e.$2,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: selected ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const Gap(28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: TextButton(
                            onPressed: () async {
                              await notifier.refresh();
                              if (context.mounted) {
                                Navigator.pop(ctx);
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Gotowe',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const Gap(16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openProfileDetail(DiscoveryProfile profile) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _FullProfileView(
          profile: profile,
          showDistance: _showDistance,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showReportBlockSheet(BuildContext context, DiscoveryProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Gap(12),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  profile.name,
                  style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ),
              const Gap(8),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag_rounded, color: Colors.orange, size: 20),
                ),
                title: Text('Zgłoś profil',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text('Spam, fake, nieodpowiednie treści',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                onTap: () async {
                  Navigator.pop(context);
                  await _reportUser(profile.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Zgłoszono ${profile.name}',
                            style: GoogleFonts.outfit()),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block_rounded, color: Colors.red, size: 20),
                ),
                title: Text('Zablokuj',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text('Nie będziesz się więcej widzieć',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                onTap: () async {
                  Navigator.pop(context);
                  await _blockUser(profile.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Zablokowano ${profile.name}',
                            style: GoogleFonts.outfit()),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    // Skip this card
                    _triggerSwipe(SwipeDirection.left);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                ),
                title: Text('Anuluj',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                onTap: () => Navigator.pop(context),
              ),
              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reportUser(String userId) async {
    try {
      final client = Supabase.instance.client;
      final me = client.auth.currentUser;
      if (me == null) return;
      await client.rpc(
        'fn_submit_report',
        params: {
          'p_reported_id': userId,
          'p_reason': 'inappropriate_content',
          'p_description': null,
        },
      );
    } catch (_) {}
  }

  Future<void> _blockUser(String userId) async {
    try {
      final client = Supabase.instance.client;
      final me = client.auth.currentUser;
      if (me == null) return;
      await client.from('blocks').insert({
        'blocker_id': me.id,
        'blocked_id': userId,
      });
    } catch (_) {}
  }
}

// ─── Header Widget ──────────────────────────────────────────

class _DiscoveryHeader extends StatelessWidget {
  final double topPadding;
  final VoidCallback onFilterTap;

  const _DiscoveryHeader({
    required this.topPadding,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: EdgeInsets.only(
            top: topPadding + 8,
            bottom: 12,
            left: 20,
            right: 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: AppColors.divider.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.navDiscover,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: onFilterTap,
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Photo Dots Indicator ───────────────────────────────────

class _PhotoDotsIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _PhotoDotsIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        count,
        (i) => Expanded(
          child: Container(
            height: 3.5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: i == current ? Colors.white : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
              boxShadow: i == current
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Profile Info Overlay ───────────────────────────────────

class _ProfileInfoOverlay extends StatelessWidget {
  final DiscoveryProfile profile;
  final bool showDistance;

  const _ProfileInfoOverlay({
    required this.profile,
    this.showDistance = true,
  });

  @override
  Widget build(BuildContext context) {
    final modeColor = AppColors.colorForMode(profile.mode);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                profile.name,
                style: GoogleFonts.outfit(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const Gap(8),
              Text(
                '${profile.age}',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.1,
                ),
              ),
              if (profile.verified) ...[
                const Gap(8),
                const Icon(Icons.verified_rounded, color: AppColors.info, size: 22),
              ],
            ],
          ),
          const Gap(6),
          Row(
            children: [
              if (showDistance) ...[
                Icon(Icons.location_on_outlined,
                    color: Colors.white.withValues(alpha: 0.6), size: 15),
                const Gap(3),
                Text(
                  profile.distanceKm < 0
                      ? 'Blisko'
                      : '${profile.distanceKm.toStringAsFixed(1)} km',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Gap(12),
              ],
              _ModeBadge(mode: profile.mode, color: modeColor),
            ],
          ),
          const Gap(12),
          if (profile.interests.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: profile.interests.take(3).map((i) {
                final emoji = _kDiscoveryInterestEmojis[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 0.5),
                  ),
                  child: Text(
                    emoji != null ? '$emoji $i' : i,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          if (profile.spotifyTrackName != null) ...[
            const Gap(12),
            _SpotifyMiniPlayer(
              trackName: profile.spotifyTrackName!,
              artist: profile.spotifyArtist ?? '',
              spotifyPreviewUrl: profile.spotifyPreviewUrl,
              artworkUrl: profile.spotifyArtworkUrl,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Profile Info Panel (below photo) ───────────────────────

class _ProfileInfoPanel extends StatelessWidget {
  final DiscoveryProfile profile;
  final Color gradStart;
  final Color gradEnd;
  final bool showDistance;

  const _ProfileInfoPanel({
    required this.profile,
    required this.gradStart,
    required this.gradEnd,
    this.showDistance = true,
  });

  String get _modeLabel {
    switch (profile.mode) {
      case 'friends': return 'Znajomi';
      case 'fwb': return 'FWB';
      default: return 'Związek';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(27),
        bottomRight: Radius.circular(27),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.6),
                width: 0.5,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name + age + verified + mode badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    profile.name,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    '${profile.age}',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (profile.verified) ...[
                    const Gap(4),
                    const Icon(Icons.verified_rounded, color: AppColors.info, size: 16),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [gradStart, gradEnd],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _modeLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(4),
              // Distance + bio snippet
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showDistance) ...[
                    Icon(Icons.location_on_outlined, color: AppColors.textHint, size: 13),
                    const Gap(2),
                    Text(
                      profile.distanceKm < 0
                          ? 'Blisko'
                          : '${profile.distanceKm.toStringAsFixed(1)} km',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                  if (profile.bio.isNotEmpty) ...[
                    if (showDistance) const Gap(6),
                    Text('·', style: GoogleFonts.outfit(color: AppColors.textHint)),
                    if (showDistance) const Gap(6),
                    Expanded(
                      child: Text(
                        profile.bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
              // "Fajnie jakbyś lubił/a" section
              if (profile.interests.isNotEmpty) ...[
                const Gap(10),
                Text(
                  'Lubi:',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Gap(6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: profile.interests.take(2).map((i) {
                    final e = _kDiscoveryInterestEmojis[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [gradStart.withValues(alpha: 0.15), gradEnd.withValues(alpha: 0.10)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: gradStart.withValues(alpha: 0.3), width: 0.5),
                      ),
                      child: Text(
                        e != null ? '$e $i' : i,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: gradStart,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              // Spotify mini player
              if (profile.spotifyTrackName != null) ...[
                const Gap(10),
                _SpotifyMiniPlayer(
                  trackName: profile.spotifyTrackName!,
                  artist: profile.spotifyArtist ?? '',
                  spotifyPreviewUrl: profile.spotifyPreviewUrl,
                  artworkUrl: profile.spotifyArtworkUrl,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mode Badge ─────────────────────────────────────────────

class _ModeBadge extends StatelessWidget {
  final String mode;
  final Color color;

  const _ModeBadge({required this.mode, required this.color});

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Action Bar ─────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final bool isPremium;
  final VoidCallback onPass;
  final VoidCallback onSmash;
  final VoidCallback onSuperLike;
  final VoidCallback onUndo;
  final VoidCallback onChat;

  const _ActionBar({
    required this.isPremium,
    required this.onPass,
    required this.onSmash,
    required this.onSuperLike,
    required this.onUndo,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: EdgeInsets.only(
            top: 14,
            bottom: bottomPadding + 14,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            border: Border(
              top: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // PASS
              _ActionButton(
                icon: Icons.close_rounded,
                color: const Color(0xFFB0B0B8),
                backgroundColor: const Color(0xFFF0F0F5),
                size: 58,
                iconSize: 26,
                label: 'PASS',
                onTap: onPass,
              ),
              // Cofnij (rewind)
              _ActionButton(
                icon: isPremium ? Icons.undo_rounded : Icons.lock_rounded,
                color: AppColors.neonBlue,
                backgroundColor: AppColors.neonBlue.withValues(alpha: 0.1),
                size: 50,
                iconSize: 22,
                label: 'Cofnij',
                onTap: onUndo,
                showLock: !isPremium,
              ),
              // SMASH
              _ActionButton(
                icon: Icons.favorite_rounded,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                size: 68,
                iconSize: 30,
                label: 'SMASH',
                onTap: onSmash,
              ),
              // Chat request (premium)
              _ActionButton(
                icon: Icons.chat_bubble_rounded,
                color: const Color(0xFF74B9FF),
                backgroundColor: const Color(0xFF74B9FF).withValues(alpha: 0.12),
                size: 50,
                iconSize: 22,
                label: 'Czat',
                onTap: onChat,
                showLock: !isPremium,
              ),
              // Super Like
              _ActionButton(
                icon: isPremium ? Icons.star_rounded : Icons.lock_rounded,
                color: const Color(0xFFFFBF00),
                backgroundColor: const Color(0xFFFFBF00).withValues(alpha: 0.12),
                size: 50,
                iconSize: 22,
                label: 'Super Like',
                onTap: onSuperLike,
                showLock: !isPremium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Action Button ──────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double size;
  final double iconSize;
  final String label;
  final VoidCallback onTap;
  final bool showLock;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.size,
    required this.iconSize,
    required this.label,
    required this.onTap,
    this.showLock = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnim.value, child: child);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.backgroundColor,
                    border: Border.all(
                      color: widget.color.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: widget.iconSize,
                  ),
                ),
                if (widget.showLock)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.divider, width: 1),
                      ),
                      child: const Icon(Icons.lock, size: 10, color: AppColors.textHint),
                    ),
                  ),
              ],
            ),
            const Gap(4),
            Text(
              widget.label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
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
  final String? spotifyPreviewUrl;
  final String? artworkUrl;

  const _SpotifyMiniPlayer({
    required this.trackName,
    required this.artist,
    this.spotifyPreviewUrl,
    this.artworkUrl,
  });

  @override
  State<_SpotifyMiniPlayer> createState() => _SpotifyMiniPlayerState();
}

class _SpotifyMiniPlayerState extends State<_SpotifyMiniPlayer> {
  bool _isPlaying = false;
  final WebAudio _audio = WebAudio();

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audio.pause();
      setState(() => _isPlaying = false);
    } else {
      final url = widget.spotifyPreviewUrl;
      if (url != null && url.isNotEmpty) {
        try {
          await _audio.play(url);
          setState(() => _isPlaying = true);
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1DB954).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              // On web, Spotify CDN blocks CORS — skip artwork load
              if (widget.artworkUrl != null && widget.artworkUrl!.isNotEmpty && !kIsWeb)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.artworkUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.music_note_rounded,
                          color: Color(0xFF1DB954), size: 22),
                    ),
                  ),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note_rounded,
                      color: Color(0xFF1DB954), size: 22),
                ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.trackName,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
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
                  color: const Color(0xFF1DB954),
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Full Profile View ──────────────────────────────────────

class _FullProfileView extends StatefulWidget {
  final DiscoveryProfile profile;
  final bool showDistance;

  const _FullProfileView({
    required this.profile,
    this.showDistance = true,
  });

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
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: profile.photos.length,
                    onPageChanged: (i) => setState(() => _currentPhoto = i),
                    itemBuilder: (_, i) {
                      return Image.network(
                        profile.photos[i],
                        fit: BoxFit.cover,
                        cacheWidth: 600,
                        cacheHeight: 900,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: AppColors.surfaceLight,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Positioned(
                  top: topPadding + 8,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: AppColors.textPrimary, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
                if (profile.photos.length > 1)
                  Positioned(
                    top: topPadding + 16,
                    left: 64,
                    right: 16,
                    child: _PhotoDotsIndicator(
                      count: profile.photos.length,
                      current: _currentPhoto,
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background.withValues(alpha: 0.8),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        profile.name,
                        style: GoogleFonts.outfit(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        '${profile.age}',
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (profile.verified) ...[
                        const Gap(8),
                        const Icon(Icons.verified_rounded, color: AppColors.info, size: 24),
                      ],
                    ],
                  ),
                  const Gap(6),
                  Row(
                    children: [
                      if (widget.showDistance) ...[
                        const Icon(Icons.location_on_outlined,
                            color: AppColors.textHint, size: 15),
                        const Gap(3),
                        Text(
                          profile.distanceKm < 0
                              ? 'Blisko'
                              : '${profile.distanceKm.toStringAsFixed(1)} km',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppColors.textHint,
                          ),
                        ),
                        const Gap(12),
                      ],
                      _DetailModeBadge(mode: profile.mode, color: modeColor),
                    ],
                  ),
                  const Gap(24),
                  if (profile.bio.isNotEmpty) ...[
                    Text(
                      AppStrings.profileAbout,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                        letterSpacing: 1,
                      ),
                    ),
                    const Gap(8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        profile.bio,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: AppColors.textPrimary.withValues(alpha: 0.8),
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const Gap(24),
                  ],
                  if (profile.interests.isNotEmpty) ...[
                    Text(
                      AppStrings.profileInterests,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                        letterSpacing: 1,
                      ),
                    ),
                    const Gap(10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.interests
                          .map((i) {
                            final emoji = _kDiscoveryInterestEmojis[i];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                emoji != null ? '$emoji $i' : i,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                    const Gap(24),
                  ],
                  if (profile.spotifyTrackName != null)
                    _SpotifyMiniPlayer(
                      trackName: profile.spotifyTrackName!,
                      artist: profile.spotifyArtist ?? '',
                      spotifyPreviewUrl: profile.spotifyPreviewUrl,
                      artworkUrl: profile.spotifyArtworkUrl,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail Mode Badge ──────────────────────────────────────

class _DetailModeBadge extends StatelessWidget {
  final String mode;
  final Color color;

  const _DetailModeBadge({required this.mode, required this.color});

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Enums ──────────────────────────────────────────────────

enum SwipeDirection { left, right, up }
