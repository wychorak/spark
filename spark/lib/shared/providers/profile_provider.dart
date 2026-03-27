import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'supabase_provider.dart';

class UserProfile {
  final String id;
  final String displayName;
  final int? age;
  final bool isVerified;
  final bool isPremium;
  final List<String> modes;
  final String? bio;
  final String? city;
  final List<String> photoUrls;
  final List<String> interests;
  final String? spotifyTrackName;
  final String? spotifyArtist;
  final String? spotifyPreviewUrl;

  const UserProfile({
    required this.id,
    required this.displayName,
    this.age,
    this.isVerified = false,
    this.isPremium = false,
    this.modes = const [],
    this.bio,
    this.city,
    this.photoUrls = const [],
    this.interests = const [],
    this.spotifyTrackName,
    this.spotifyArtist,
    this.spotifyPreviewUrl,
  });
}

/// Fetches profile for a given userId. Keyed by userId so it only re-fetches
/// when the user actually changes, not on every auth stream tick.
final profileByIdProvider =
    FutureProvider.family<UserProfile?, String>((ref, userId) async {
  final client = ref.watch(supabaseClientProvider);

  final profileRes = await client
      .from('user_profiles')
      .select('*')
      .eq('id', userId)
      .maybeSingle();

  if (profileRes == null) return null;

  // Interests — join with interests table to get names
  List<String> interests = [];
  try {
    final interestsRes = await client
        .from('user_interests')
        .select('interests(name)')
        .eq('user_id', userId);
    interests = (interestsRes as List)
        .map((e) {
          final interestMap = e['interests'];
          if (interestMap is Map) return interestMap['name']?.toString() ?? '';
          return '';
        })
        .where((s) => s.isNotEmpty)
        .toList();
  } catch (_) {}

  // Photos from storage
  final List<String> photoUrls = [];
  try {
    final files = await client.storage
        .from('photos')
        .list(path: 'profiles/$userId');
    for (final file in files) {
      final url = client.storage
          .from('photos')
          .getPublicUrl('profiles/$userId/${file.name}');
      photoUrls.add(url);
    }
  } catch (_) {}

  // Parse modes (PostgreSQL returns {relationship,friends} as String on web)
  final dynamic rawModes = profileRes['modes'];
  List<String> modes = [];
  if (rawModes is List) {
    modes = rawModes.map((e) => e.toString()).toList();
  } else if (rawModes is String) {
    final cleaned = rawModes.replaceAll('{', '').replaceAll('}', '');
    modes = cleaned.split(',').where((s) => s.isNotEmpty).toList();
  }

  // Calculate age
  int? age;
  final bornAt = profileRes['born_at'];
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

  return UserProfile(
    id: userId,
    displayName: profileRes['display_name']?.toString() ?? 'Użytkownik',
    age: age,
    isVerified: profileRes['is_verified'] == true,
    isPremium: profileRes['is_premium'] == true,
    modes: modes,
    bio: profileRes['bio']?.toString(),
    city: profileRes['city']?.toString(),
    photoUrls: photoUrls,
    interests: interests,
    spotifyTrackName: profileRes['spotify_track_name']?.toString(),
    spotifyArtist: profileRes['spotify_artist_name']?.toString(),
    spotifyPreviewUrl: profileRes['spotify_preview_url']?.toString(),
  );
});

/// Public provider used by UI — resolves to null when not logged in.
final currentProfileProvider = Provider<AsyncValue<UserProfile?>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const AsyncData(null);
  return ref.watch(profileByIdProvider(user.id));
});
