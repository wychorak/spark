import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/core/theme/app_theme.dart';
import 'package:spark/shared/providers/auth_provider.dart';
import 'package:spark/shared/providers/profile_provider.dart';
import 'package:spark/shared/widgets/neon_button.dart';
import 'package:spark/shared/widgets/neon_text_field.dart';

// ── Constants ──

const _kMaxPhotos = 6;
const _kMaxBioLength = 500;

const List<String> _kAllInterests = [
  'Podroze',
  'Muzyka',
  'Filmy',
  'Gotowanie',
  'Fitness',
  'Gry wideo',
  'Fotografia',
  'Ksiazki',
  'Sztuka',
  'Taniec',
  'Joga',
  'Bieganie',
  'Kolarstwo',
  'Plywanie',
  'Wspinaczka',
  'Kawa',
  'Wino',
  'Piwo rzemielnicze',
  'Technologia',
  'Moda',
  'Zwierzeta',
  'Natura',
  'Koncerty',
  'Stand-up',
  'Sushi',
  'Netflix',
  'Medytacja',
  'Jezyki obce',
  'Astrologia',
  'Tatuaze',
];

class _ModeOption {
  final String id;
  final String label;
  final String emoji;
  final Color color;

  const _ModeOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
  });
}

const List<_ModeOption> _kModes = [
  _ModeOption(
    id: 'relationship',
    label: 'Związek',
    emoji: '\u2764\uFE0F',
    color: AppColors.modeRelationship,
  ),
  _ModeOption(
    id: 'friends',
    label: 'Przyjaźń',
    emoji: '\u{1F91D}',
    color: AppColors.modeFriends,
  ),
  _ModeOption(
    id: 'fwb',
    label: 'FWB',
    emoji: '\u{1F525}',
    color: AppColors.modeFWB,
  ),
];

// ── State providers ──

final _photosProvider = StateProvider.autoDispose<List<String?>>((ref) {
  return List.filled(_kMaxPhotos, null);
});

final _nameController = Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});

final _bioController = Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});

final _selectedInterestsProvider = StateProvider.autoDispose<Set<String>>((ref) {
  return {};
});

final _selectedModesProvider = StateProvider.autoDispose<Set<String>>((ref) {
  return {};
});

final _spotifyConnectedProvider = StateProvider.autoDispose<bool>((ref) => false);

final _spotifyTrackNameProvider = StateProvider.autoDispose<String?>((ref) => null);

final _spotifyArtistProvider = StateProvider.autoDispose<String?>((ref) => null);

final _bioLengthProvider = StateProvider.autoDispose<int>((ref) => 0);

final _profileLoadedProvider = StateProvider.autoDispose<bool>((ref) => false);

final _savingProvider = StateProvider.autoDispose<bool>((ref) => false);

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  void _loadProfileData() {
    if (ref.read(_profileLoadedProvider)) return;

    final profileAsync = ref.read(currentProfileProvider);
    final profile = profileAsync.maybeWhen(
      data: (p) => p,
      orElse: () => null,
    );

    if (profile == null) return;

    ref.read(_nameController).text = profile.displayName;
    ref.read(_bioController).text = profile.bio ?? '';
    ref.read(_bioLengthProvider.notifier).state = (profile.bio ?? '').length;
    ref.read(_selectedInterestsProvider.notifier).state = profile.interests.toSet();
    ref.read(_selectedModesProvider.notifier).state = profile.modes.toSet();

    // Photos — pad to _kMaxPhotos
    final photos = List<String?>.filled(_kMaxPhotos, null);
    for (int i = 0; i < profile.photoUrls.length && i < _kMaxPhotos; i++) {
      photos[i] = profile.photoUrls[i];
    }
    ref.read(_photosProvider.notifier).state = photos;

    // Spotify
    final hasSpotify = profile.spotifyTrackName != null && profile.spotifyTrackName!.isNotEmpty;
    ref.read(_spotifyConnectedProvider.notifier).state = hasSpotify;
    ref.read(_spotifyTrackNameProvider.notifier).state = profile.spotifyTrackName;
    ref.read(_spotifyArtistProvider.notifier).state = profile.spotifyArtist;

    ref.read(_profileLoadedProvider.notifier).state = true;
  }

  Future<void> _pickPhoto(int index) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      builder: (ctx) => SafeArea(
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
              const Gap(AppDimensions.spacing24),
              Text(
                'Wybierz źródło',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Gap(AppDimensions.spacing24),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.neonPink),
                title: Text(
                  'Aparat',
                  style: GoogleFonts.outfit(color: AppColors.textPrimary),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.neonPurple),
                title: Text(
                  'Galeria',
                  style: GoogleFonts.outfit(color: AppColors.textPrimary),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (ref.read(_photosProvider)[index] != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: Text(
                    'Usuń zdjęcie',
                    style: GoogleFonts.outfit(color: AppColors.error),
                  ),
                  onTap: () {
                    final photos = [...ref.read(_photosProvider)];
                    photos[index] = null;
                    ref.read(_photosProvider.notifier).state = photos;
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1350,
        imageQuality: 85,
      );
      if (file != null) {
        final photos = [...ref.read(_photosProvider)];
        photos[index] = file.path;
        ref.read(_photosProvider.notifier).state = photos;
      }
    } catch (_) {
      // Handle permission or picker errors gracefully
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    final photos = [...ref.read(_photosProvider)];
    final item = photos.removeAt(oldIndex);
    photos.insert(newIndex, item);
    ref.read(_photosProvider.notifier).state = photos;
  }

  Future<void> _saveProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    ref.read(_savingProvider.notifier).state = true;

    try {
      final supabase = Supabase.instance.client;
      final userId = user.id;
      final name = ref.read(_nameController).text.trim();
      final bio = ref.read(_bioController).text.trim();
      final modes = ref.read(_selectedModesProvider);
      final interests = ref.read(_selectedInterestsProvider);
      final photos = ref.read(_photosProvider);

      // Upload new photos (local file paths)
      for (int i = 0; i < photos.length; i++) {
        final photo = photos[i];
        if (photo == null) continue;
        // Skip URLs (already uploaded)
        if (photo.startsWith('http')) continue;

        final file = File(photo);
        final storagePath = 'profiles/$userId/photo_$i.jpg';
        await supabase.storage.from('photos').upload(
          storagePath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
      }

      // Update profile
      await supabase.from('user_profiles').update({
        'display_name': name,
        'bio': bio,
        'modes': modes.toList(),
      }).eq('id', userId);

      // Save interests
      await supabase.rpc('fn_save_user_interests', params: {
        'p_interest_names': interests.toList(),
      });

      // Invalidate profile cache so it reloads
      ref.invalidate(profileByIdProvider(userId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profil zapisany',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nie udało się zapisać profilu. Spróbuj ponownie.',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(_savingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final isSaving = ref.watch(_savingProvider);

    // Try loading profile data if not yet loaded
    if (!ref.read(_profileLoadedProvider)) {
      profileAsync.whenData((profile) {
        if (profile != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadProfileData();
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppStrings.profileEdit,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: profileAsync.maybeWhen(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.neonPink),
        ),
        orElse: () => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(AppDimensions.spacing16),
              // ── Photo Grid ──
              _sectionLabel('Zdjęcia'),
              const Gap(AppDimensions.spacing12),
              const _PhotoGrid(),
              const Gap(AppDimensions.spacing32),
              // ── Display Name ──
              _sectionLabel('Imię'),
              const Gap(AppDimensions.spacing12),
              _NameField(),
              const Gap(AppDimensions.spacing32),
              // ── Bio ──
              _sectionLabel('O mnie'),
              const Gap(AppDimensions.spacing12),
              const _BioField(),
              const Gap(AppDimensions.spacing32),
              // ── Interests ──
              _sectionLabel('Zainteresowania'),
              const Gap(AppDimensions.spacing12),
              const _InterestsGrid(),
              const Gap(AppDimensions.spacing32),
              // ── Modes ──
              _sectionLabel('Czego szukasz?'),
              const Gap(AppDimensions.spacing12),
              const _ModeSelection(),
              const Gap(AppDimensions.spacing32),
              // ── Spotify ──
              _sectionLabel('Spotify'),
              const Gap(AppDimensions.spacing12),
              const _SpotifyConnectSection(),
              const Gap(AppDimensions.spacing40),
              // ── Save Button ──
              SizedBox(
                width: double.infinity,
                child: isSaving
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.neonPink),
                      )
                    : NeonButton(
                        label: AppStrings.save,
                        icon: Icons.check,
                        onPressed: _saveProfile,
                      ),
              ),
              const Gap(AppDimensions.spacing48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ── Photo Grid ──

class _PhotoGrid extends ConsumerWidget {
  const _PhotoGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(_photosProvider);
    final state = context.findAncestorStateOfType<_EditProfileScreenState>()!;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppDimensions.spacing8,
        mainAxisSpacing: AppDimensions.spacing8,
        childAspectRatio: 0.75,
      ),
      itemCount: _kMaxPhotos,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final hasPhoto = photo != null;
        final isNetworkPhoto = hasPhoto && photo.startsWith('http');
        final isLocalPhoto = hasPhoto && !photo.startsWith('http');

        return GestureDetector(
          onTap: () => state._pickPhoto(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: AppDimensions.animNormal),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: hasPhoto
                    ? AppColors.neonPink.withValues(alpha: 0.4)
                    : AppColors.divider,
                width: hasPhoto ? AppDimensions.neonBorderWidth : 1,
              ),
              boxShadow: hasPhoto
                  ? [
                      BoxShadow(
                        color: AppColors.neonPinkGlow,
                        blurRadius: AppDimensions.neonBlurSmall,
                      ),
                    ]
                  : [],
            ),
            child: hasPhoto
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusM - 1),
                        child: isNetworkPhoto
                            ? Image.network(
                                photo,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.card,
                                  child: Center(
                                    child: Icon(
                                      Icons.person,
                                      size: AppDimensions.iconXL,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ),
                              )
                            : isLocalPhoto
                                ? Image.file(
                                    File(photo),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppColors.card,
                                      child: Center(
                                        child: Icon(
                                          Icons.person,
                                          size: AppDimensions.iconXL,
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.card,
                                    child: Center(
                                      child: Icon(
                                        Icons.person,
                                        size: AppDimensions.iconXL,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ),
                      ),
                      // Index badge
                      if (index == 0)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neonPink,
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusS),
                            ),
                            child: Text(
                              'Główne',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      // Drag handle
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.drag_indicator,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.neonPink.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.neonPink,
                          size: 20,
                        ),
                      ),
                      const Gap(AppDimensions.spacing4),
                      Text(
                        'Dodaj',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
          ),
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: index * 80),
              duration: const Duration(milliseconds: AppDimensions.animNormal),
            );
      },
    );
  }
}

// ── Name Field ──

class _NameField extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NeonTextField(
      controller: ref.watch(_nameController),
      hint: AppStrings.onboardingNameHint,
      prefixIcon: Icons.person_outline,
    );
  }
}

// ── Bio Field ──

class _BioField extends ConsumerWidget {
  const _BioField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charCount = ref.watch(_bioLengthProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        NeonTextField(
          controller: ref.watch(_bioController),
          hint: AppStrings.onboardingBioHint,
          maxLines: 5,
          minLines: 3,
          maxLength: _kMaxBioLength,
          onChanged: (value) {
            ref.read(_bioLengthProvider.notifier).state = value.length;
          },
        ),
        const Gap(AppDimensions.spacing4),
        Text(
          '$charCount / $_kMaxBioLength',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: charCount > _kMaxBioLength * 0.9
                ? AppColors.warning
                : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

// ── Interests Grid ──

class _InterestsGrid extends ConsumerWidget {
  const _InterestsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_selectedInterestsProvider);

    return Wrap(
      spacing: AppDimensions.spacing8,
      runSpacing: AppDimensions.spacing8,
      children: _kAllInterests.map((interest) {
        final isSelected = selected.contains(interest);
        final color = isSelected ? AppColors.neonPink : AppColors.divider;

        return GestureDetector(
          onTap: () {
            final current = <String>{...selected};
            if (isSelected) {
              current.remove(interest);
            } else {
              current.add(interest);
            }
            ref.read(_selectedInterestsProvider.notifier).state = current;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: AppDimensions.animFast),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.neonPink.withValues(alpha: 0.15)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
              border: Border.all(color: color, width: isSelected ? 1.5 : 1),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.neonPinkGlow,
                        blurRadius: AppDimensions.neonBlurSmall,
                      ),
                    ]
                  : [],
            ),
            child: Text(
              interest,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.neonPink : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Mode Selection ──

class _ModeSelection extends ConsumerWidget {
  const _ModeSelection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedModes = ref.watch(_selectedModesProvider);

    return Row(
      children: _kModes.map((mode) {
        final isSelected = selectedModes.contains(mode.id);

        return Expanded(
          child: GestureDetector(
            onTap: () {
              final current = <String>{...selectedModes};
              if (isSelected) {
                current.remove(mode.id);
              } else {
                current.add(mode.id);
              }
              ref.read(_selectedModesProvider.notifier).state = current;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: AppDimensions.animNormal),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: isSelected
                    ? mode.color.withValues(alpha: 0.12)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                border: Border.all(
                  color: isSelected
                      ? mode.color.withValues(alpha: 0.6)
                      : AppColors.divider,
                  width: isSelected ? AppDimensions.neonBorderWidth : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: mode.color.withValues(alpha: 0.25),
                          blurRadius: AppDimensions.neonBlurSmall,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Text(
                    mode.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const Gap(AppDimensions.spacing8),
                  Text(
                    mode.label,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? mode.color : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Spotify Section ──

class _SpotifyConnectSection extends ConsumerWidget {
  const _SpotifyConnectSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(_spotifyConnectedProvider);
    final trackName = ref.watch(_spotifyTrackNameProvider);
    final artist = ref.watch(_spotifyArtistProvider);

    if (!isConnected) {
      return SizedBox(
        width: double.infinity,
        child: NeonOutlinedButton(
          label: 'Połącz ze Spotify',
          icon: Icons.music_note,
          color: const Color(0xFF1DB954),
          onPressed: () {
            ref.read(_spotifyConnectedProvider.notifier).state = true;
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: AppTheme.subtleNeonGlow(
        color: const Color(0xFF1DB954),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: const Icon(
              Icons.music_note,
              color: Color(0xFF1DB954),
            ),
          ),
          const Gap(AppDimensions.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist ?? 'Spotify',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  trackName ?? 'Połączono',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(_spotifyConnectedProvider.notifier).state = false;
              ref.read(_spotifyTrackNameProvider.notifier).state = null;
              ref.read(_spotifyArtistProvider.notifier).state = null;
            },
            child: const Icon(
              Icons.close,
              color: AppColors.textHint,
              size: AppDimensions.iconS,
            ),
          ),
        ],
      ),
    );
  }
}
