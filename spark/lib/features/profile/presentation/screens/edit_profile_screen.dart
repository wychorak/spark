import 'dart:convert';
import 'dart:typed_data';

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
import 'package:spark/shared/providers/auth_provider.dart';
import 'package:spark/shared/providers/profile_provider.dart';
import 'package:spark/shared/widgets/neon_button.dart';
import 'package:spark/shared/widgets/neon_text_field.dart';

// ── Constants ──

const _kMaxPhotos = 6;
const _kMaxBioLength = 500;

const List<String> _kAllInterests = [
  'Muzyka', 'Film', 'Ksiazki', 'Gry', 'Sport', 'Silownia',
  'Joga', 'Sztuka', 'Fotografia', 'Podroze', 'Gotowanie', 'Wino',
  'Kawa', 'Psy', 'Koty', 'Natura', 'Teatr', 'Taniec',
  'Karaoke', 'Wspinaczka', 'Rower', 'Plywanie', 'Podcasty', 'Technologia',
  'Ekologia', 'Festiwale', 'Stand-up', 'Netflix', 'Astrologia', 'Piwo',
];

const Map<String, String> _kInterestEmojis = {
  'Muzyka': '🎵', 'Film': '🎬', 'Ksiazki': '📚', 'Gry': '🎮',
  'Sport': '⚽', 'Silownia': '🏋️', 'Joga': '🧘', 'Sztuka': '🎨',
  'Fotografia': '📸', 'Podroze': '✈️', 'Gotowanie': '🍳', 'Wino': '🍷',
  'Kawa': '☕', 'Psy': '🐕', 'Koty': '🐈', 'Natura': '🌿',
  'Teatr': '🎭', 'Taniec': '💃', 'Karaoke': '🎤', 'Wspinaczka': '🧗',
  'Rower': '🚴', 'Plywanie': '🏊', 'Podcasty': '🎧', 'Technologia': '💻',
  'Ekologia': '♻️', 'Festiwale': '🎪', 'Stand-up': '🎙️', 'Netflix': '📺',
  'Astrologia': '♈', 'Piwo': '🍺',
};

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
    label: 'Zwiazek',
    emoji: '\u2764\uFE0F',
    color: AppColors.modeRelationship,
  ),
  _ModeOption(
    id: 'friends',
    label: 'Przyjazn',
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

class _GradientPreset {
  final String startHex;
  final String endHex;
  final String label;
  const _GradientPreset({required this.startHex, required this.endHex, required this.label});
}

const List<_GradientPreset> _kGradientPresets = [
  _GradientPreset(startHex: 'FF6B9D', endHex: 'FF9F43', label: 'Roz-Pomaranczowy'),
  _GradientPreset(startHex: 'A29BFE', endHex: 'FF6B9D', label: 'Fiolet-Roz'),
  _GradientPreset(startHex: '74B9FF', endHex: '5CD68A', label: 'Blekitny-Zielony'),
  _GradientPreset(startHex: 'FF9F43', endHex: 'FFD93D', label: 'Pomaranczowy-Zolty'),
  _GradientPreset(startHex: 'FF6B9D', endHex: 'A29BFE', label: 'Roz-Fioletowy'),
  _GradientPreset(startHex: '5CD68A', endHex: '74B9FF', label: 'Zielony-Blekitny'),
  _GradientPreset(startHex: 'FF6B6B', endHex: 'FF6B9D', label: 'Czerwony-Roz'),
  _GradientPreset(startHex: '00CEC9', endHex: 'A29BFE', label: 'Morski-Fioletowy'),
  _GradientPreset(startHex: 'FD79A8', endHex: 'E17055', label: 'Brzoskwinia'),
  _GradientPreset(startHex: '6C5CE7', endHex: '00CEC9', label: 'Kosmos'),
  _GradientPreset(startHex: 'FDCB6E', endHex: 'E17055', label: 'Zachod Slonca'),
  _GradientPreset(startHex: '00B894', endHex: '55EFC4', label: 'Mieta'),
  _GradientPreset(startHex: 'E84393', endHex: '6C5CE7', label: 'Neon'),
  _GradientPreset(startHex: 'D63031', endHex: 'E17055', label: 'Ogien'),
  _GradientPreset(startHex: '2D3436', endHex: '636E72', label: 'Grafit'),
  _GradientPreset(startHex: 'FFD3A5', endHex: 'FCA5FF', label: 'Pastel'),
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

final _songNameController = Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});

final _artistNameController = Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});

final _instagramController = Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});

final _tiktokController = Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});

final _snapchatController = Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});

final _selectedInterestsProvider = StateProvider.autoDispose<Set<String>>((ref) {
  return {};
});

final _selectedDesiredInterestsProvider = StateProvider.autoDispose<Set<String>>((ref) {
  return {};
});

final _selectedModesProvider = StateProvider.autoDispose<Set<String>>((ref) {
  return {};
});

final _bioLengthProvider = StateProvider.autoDispose<int>((ref) => 0);

final _profileLoadedProvider = StateProvider.autoDispose<bool>((ref) => false);

final _savingProvider = StateProvider.autoDispose<bool>((ref) => false);

final _pickedFilesProvider = StateProvider.autoDispose<Map<int, XFile>>((ref) {
  return {};
});

final _previewUrlProvider = StateProvider.autoDispose<String>((ref) => '');
final _artworkUrlProvider = StateProvider.autoDispose<String>((ref) => '');

final _searchResultsProvider = StateProvider.autoDispose<List<Map<String, dynamic>>>((ref) => []);
final _searchingProvider = StateProvider.autoDispose<bool>((ref) => false);

final _gradientStartProvider = StateProvider.autoDispose<String>((ref) => '');
final _gradientEndProvider = StateProvider.autoDispose<String>((ref) => '');

// ── Light styling helpers ──

const _kSectionBg = AppColors.white;
const _kSectionBorder = AppColors.divider;
const _kCardBg = AppColors.card;

BoxDecoration _sectionDecoration() => BoxDecoration(
      color: _kSectionBg,
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      border: Border.all(color: _kSectionBorder),
      boxShadow: [
        BoxShadow(
          color: AppColors.neonPink.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );

// ── Main Screen ──

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
    ref.read(_selectedDesiredInterestsProvider.notifier).state = profile.desiredInterests.toSet();
    ref.read(_selectedModesProvider.notifier).state = profile.modes.toSet();

    final photos = List<String?>.filled(_kMaxPhotos, null);
    for (int i = 0; i < profile.photoUrls.length && i < _kMaxPhotos; i++) {
      photos[i] = profile.photoUrls[i];
    }
    ref.read(_photosProvider.notifier).state = photos;

    ref.read(_songNameController).text = profile.spotifyTrackName ?? '';
    ref.read(_artistNameController).text = profile.spotifyArtist ?? '';
    ref.read(_previewUrlProvider.notifier).state = profile.spotifyPreviewUrl ?? '';

    ref.read(_instagramController).text = profile.instagramHandle ?? '';
    ref.read(_tiktokController).text = profile.tiktokHandle ?? '';
    ref.read(_snapchatController).text = profile.snapchatHandle ?? '';

    ref.read(_gradientStartProvider.notifier).state = profile.profileGradientStart ?? '';
    ref.read(_gradientEndProvider.notifier).state = profile.profileGradientEnd ?? '';

    ref.read(_profileLoadedProvider.notifier).state = true;
  }

  Future<void> _pickPhoto(int index) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(20),
              Text(
                'Wybierz zrodlo',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Gap(20),
              _BottomSheetTile(
                icon: Icons.camera_alt_rounded,
                iconColor: AppColors.neonPink,
                label: 'Aparat',
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              _BottomSheetTile(
                icon: Icons.photo_library_rounded,
                iconColor: AppColors.neonPurple,
                label: 'Galeria',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (ref.read(_photosProvider)[index] != null)
                _BottomSheetTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: AppColors.error,
                  label: 'Usun zdjecie',
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
        final picked = {...ref.read(_pickedFilesProvider)};
        picked[index] = file;
        ref.read(_pickedFilesProvider.notifier).state = picked;
      }
    } catch (_) {}
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
      final desiredInterests = ref.read(_selectedDesiredInterestsProvider);
      final photos = ref.read(_photosProvider);
      final pickedFiles = ref.read(_pickedFilesProvider);
      final songName = ref.read(_songNameController).text.trim();
      final artistName = ref.read(_artistNameController).text.trim();
      final previewUrl = ref.read(_previewUrlProvider);
      final artworkUrl = ref.read(_artworkUrlProvider);
      final instagram = ref.read(_instagramController).text.trim();
      final tiktok = ref.read(_tiktokController).text.trim();
      final snapchat = ref.read(_snapchatController).text.trim();
      final gradientStart = ref.read(_gradientStartProvider);
      final gradientEnd = ref.read(_gradientEndProvider);

      for (int i = 0; i < photos.length; i++) {
        final photo = photos[i];
        if (photo == null) continue;
        if (photo.startsWith('http')) continue;

        final xfile = pickedFiles[i];
        if (xfile == null) continue;

        final bytes = await xfile.readAsBytes();
        final storagePath = 'profiles/$userId/photo_$i.jpg';
        await supabase.storage.from('photos').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
      }

      await supabase.from('user_profiles').update({
        'display_name': name,
        'bio': bio,
        'modes': modes.toList(),
        'spotify_track_name': songName.isEmpty ? null : songName,
        'spotify_artist_name': artistName.isEmpty ? null : artistName,
        'spotify_preview_url': previewUrl.isEmpty ? null : previewUrl,
        'spotify_artwork_url': artworkUrl.isEmpty ? null : artworkUrl,
        'desired_interests': desiredInterests.toList(),
        'instagram_handle': instagram.isEmpty ? null : instagram,
        'tiktok_handle': tiktok.isEmpty ? null : tiktok,
        'snapchat_handle': snapchat.isEmpty ? null : snapchat,
        'profile_gradient_start': gradientStart.isEmpty ? null : gradientStart,
        'profile_gradient_end': gradientEnd.isEmpty ? null : gradientEnd,
      }).eq('id', userId);

      await supabase.rpc('fn_save_user_interests', params: {
        'p_interest_names': interests.toList(),
      });

      ref.invalidate(profileByIdProvider(userId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil zapisany', style: GoogleFonts.outfit()),
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
              'Nie udalo sie zapisac profilu. Sprobuj ponownie.',
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
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edytuj profil',
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!isSaving)
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                AppStrings.save,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neonPink,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppColors.neonPink,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: profileAsync.maybeWhen(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.neonPink),
        ),
        orElse: () => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(12),

              // ── Photo Grid ──
              _SectionHeader(label: 'Zdjecia'),
              const Gap(10),
              const _PhotoGrid(),
              const Gap(28),

              // ── Name ──
              _SectionHeader(label: 'Imie'),
              const Gap(10),
              _NameField(),
              const Gap(28),

              // ── Bio ──
              _SectionHeader(label: 'O mnie'),
              const Gap(10),
              const _BioField(),
              const Gap(28),

              // ── Interests ──
              _SectionHeader(label: 'Zainteresowania'),
              const Gap(10),
              const _InterestsWrap(isDesired: false),
              const Gap(28),

              // ── Desired Interests ──
              _SectionHeader(label: 'Poszukiwane zainteresowania'),
              const Gap(10),
              const _InterestsWrap(isDesired: true),
              const Gap(28),

              // ── Modes ──
              _SectionHeader(label: 'Czego szukasz?'),
              const Gap(10),
              const _ModeSelection(),
              const Gap(28),

              // ── Song ──
              _SectionHeader(label: 'Ulubiona piosenka'),
              const Gap(10),
              const _SongInputSection(),
              const Gap(28),

              // ── Social Media ──
              _SectionHeader(label: 'Social media'),
              const Gap(10),
              const _SocialMediaFields(),
              const Gap(28),

              // ── Gradient Color ──
              _SectionHeader(label: 'Kolor profilu'),
              const Gap(10),
              const _GradientPicker(),
              const Gap(36),

              // ── Save Button ──
              SizedBox(
                width: double.infinity,
                child: isSaving
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.neonPink),
                      )
                    : NeonButton(
                        label: AppStrings.save,
                        icon: Icons.check_rounded,
                        onPressed: _saveProfile,
                      ),
              ),
              const Gap(48),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Header ──

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── Bottom Sheet Tile ──

class _BottomSheetTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _BottomSheetTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label, style: GoogleFonts.outfit(color: AppColors.textPrimary)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// ── Photo Grid (2x3) ──

class _PhotoGrid extends ConsumerWidget {
  const _PhotoGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(_photosProvider);
    final pickedFiles = ref.watch(_pickedFilesProvider);
    final state = context.findAncestorStateOfType<_EditProfileScreenState>()!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _sectionDecoration(),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: _kMaxPhotos,
        itemBuilder: (context, index) {
          final photo = photos[index];
          final hasPhoto = photo != null;
          final isNetwork = hasPhoto && photo.startsWith('http');
          final xfile = pickedFiles[index];

          return GestureDetector(
            onTap: () => state._pickPhoto(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasPhoto
                      ? AppColors.neonPink.withValues(alpha: 0.2)
                      : AppColors.divider,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonPink.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: hasPhoto
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: isNetwork
                              ? Image.network(
                                  photo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _photoPlaceholder(),
                                )
                              : xfile != null
                                  ? FutureBuilder<Uint8List>(
                                      future: xfile.readAsBytes(),
                                      builder: (ctx, snap) {
                                        if (snap.hasData) {
                                          return Image.memory(
                                            snap.data!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _photoPlaceholder(),
                                          );
                                        }
                                        return _photoPlaceholder();
                                      },
                                    )
                                  : _photoPlaceholder(),
                        ),
                        if (index == 0)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.neonPink,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Glowne',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.neonPink.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: AppColors.neonPink,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
            ),
          )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: index * 60),
                duration: const Duration(milliseconds: 250),
              );
        },
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
        color: AppColors.card,
        child: const Center(
          child: Icon(Icons.person, size: 32, color: AppColors.textHint),
        ),
      );
}

// ── Name Field ──

class _NameField extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NeonTextField(
      controller: ref.watch(_nameController),
      hint: AppStrings.onboardingNameHint,
      prefixIcon: Icons.person_outline_rounded,
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
        const Gap(4),
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

// ── Interests Wrap (shared for interests & desired interests) ──

class _InterestsWrap extends ConsumerWidget {
  const _InterestsWrap({required this.isDesired});
  final bool isDesired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = isDesired ? _selectedDesiredInterestsProvider : _selectedInterestsProvider;
    final selected = ref.watch(provider);
    final chipColor = isDesired ? AppColors.neonPurple : AppColors.neonPink;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _sectionDecoration(),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _kAllInterests.map((interest) {
          final isSelected = selected.contains(interest);

          return GestureDetector(
            onTap: () {
              final current = <String>{...selected};
              if (isSelected) {
                current.remove(interest);
              } else {
                current.add(interest);
              }
              ref.read(provider.notifier).state = current;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? chipColor.withValues(alpha: 0.1)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? chipColor.withValues(alpha: 0.5)
                      : AppColors.divider,
                ),
              ),
              child: Text(
                '${_kInterestEmojis[interest] ?? ''} $interest'.trim(),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? chipColor : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? mode.color.withValues(alpha: 0.08)
                    : AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? mode.color.withValues(alpha: 0.45)
                      : AppColors.divider,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: mode.color.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Text(mode.emoji, style: const TextStyle(fontSize: 26)),
                  const Gap(8),
                  Text(
                    mode.label,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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

// ── Social Media Fields ──

class _SocialMediaFields extends ConsumerWidget {
  const _SocialMediaFields();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _sectionDecoration(),
      child: Column(
        children: [
          _SocialField(
            controller: ref.watch(_instagramController),
            icon: Icons.camera_alt_outlined,
            label: 'Instagram',
            hint: 'Nazwa uzytkownika',
          ),
          const Gap(12),
          _SocialField(
            controller: ref.watch(_tiktokController),
            icon: Icons.music_video_outlined,
            label: 'TikTok',
            hint: 'Nazwa uzytkownika',
          ),
          const Gap(12),
          _SocialField(
            controller: ref.watch(_snapchatController),
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Snapchat',
            hint: 'Nazwa uzytkownika',
          ),
        ],
      ),
    );
  }
}

class _SocialField extends StatelessWidget {
  const _SocialField({
    required this.controller,
    required this.icon,
    required this.label,
    required this.hint,
  });
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.neonPink),
        const Gap(10),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(fontSize: 14, color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.neonPink, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Gradient Picker ──

class _GradientPicker extends ConsumerWidget {
  const _GradientPicker();

  Color _parseHex(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startHex = ref.watch(_gradientStartProvider);
    final endHex = ref.watch(_gradientEndProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _sectionDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (startHex.isNotEmpty && endHex.isNotEmpty) ...[
            Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [_parseHex(startHex), _parseHex(endHex)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Aktualny gradient',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Gap(16),
          ],
          Text(
            'Wybierz gradient',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.8,
            ),
            itemCount: _kGradientPresets.length,
            itemBuilder: (context, index) {
              final preset = _kGradientPresets[index];
              final isSelected = startHex == preset.startHex && endHex == preset.endHex;

              return GestureDetector(
                onTap: () {
                  ref.read(_gradientStartProvider.notifier).state = preset.startHex;
                  ref.read(_gradientEndProvider.notifier).state = preset.endHex;
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [_parseHex(preset.startHex), _parseHex(preset.endHex)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    border: isSelected
                        ? Border.all(color: AppColors.textPrimary, width: 2.5)
                        : Border.all(color: AppColors.divider, width: 1),
                  ),
                ),
              );
            },
          ),
          const Gap(8),
          // Clear button
          if (startHex.isNotEmpty)
            GestureDetector(
              onTap: () {
                ref.read(_gradientStartProvider.notifier).state = '';
                ref.read(_gradientEndProvider.notifier).state = '';
              },
              child: Text(
                'Usun gradient',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Song Input Section ──

class _SongInputSection extends ConsumerStatefulWidget {
  const _SongInputSection();

  @override
  ConsumerState<_SongInputSection> createState() => _SongInputSectionState();
}

class _SongInputSectionState extends ConsumerState<_SongInputSection> {
  final _searchController = TextEditingController();

  Future<void> _searchSongs(String query) async {
    if (query.trim().length < 2) return;
    ref.read(_searchingProvider.notifier).state = true;
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'search-music',
        queryParameters: {'q': query.trim()},
        method: HttpMethod.get,
      );
      if (response.status == 200) {
        final data = response.data is String
            ? jsonDecode(response.data) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        final results = (data['results'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        ref.read(_searchResultsProvider.notifier).state = results;
      }
    } catch (_) {}
    ref.read(_searchingProvider.notifier).state = false;
  }

  void _selectSong(Map<String, dynamic> song) {
    ref.read(_songNameController).text = song['trackName']?.toString() ?? '';
    ref.read(_artistNameController).text = song['artistName']?.toString() ?? '';
    ref.read(_previewUrlProvider.notifier).state =
        song['previewUrl']?.toString() ?? '';
    ref.read(_artworkUrlProvider.notifier).state =
        song['artworkUrl100']?.toString() ?? '';
    ref.read(_searchResultsProvider.notifier).state = [];
    _searchController.clear();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songName = ref.watch(_songNameController).text;
    final artistName = ref.watch(_artistNameController).text;
    final artworkUrl = ref.watch(_artworkUrlProvider);
    final searchResults = ref.watch(_searchResultsProvider);
    final isSearching = ref.watch(_searchingProvider);
    final hasSong = songName.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _sectionDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  'Dodaj ulubiona piosenke',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (hasSong)
                GestureDetector(
                  onTap: () {
                    ref.read(_songNameController).text = '';
                    ref.read(_artistNameController).text = '';
                    ref.read(_previewUrlProvider.notifier).state = '';
                    ref.read(_artworkUrlProvider.notifier).state = '';
                    setState(() {});
                  },
                  child: Icon(Icons.close_rounded,
                      size: 20, color: AppColors.textHint),
                ),
            ],
          ),
          const Gap(16),

          // Selected song card
          if (hasSong) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  if (artworkUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(artworkUrl,
                          width: 48, height: 48, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.music_note,
                                    color: AppColors.primary),
                              )),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Icon(Icons.music_note, color: AppColors.primary),
                    ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          songName,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          artistName,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),
          ],

          // Search field
          TextField(
            controller: _searchController,
            style: GoogleFonts.outfit(
                fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Wyszukaj utwor...',
              hintStyle:
                  GoogleFonts.outfit(fontSize: 14, color: AppColors.textHint),
              prefixIcon: Icon(Icons.search_rounded,
                  color: AppColors.textHint, size: 20),
              suffixIcon: isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.card,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            onSubmitted: _searchSongs,
          ),

          // Search results
          if (searchResults.isNotEmpty) ...[
            const Gap(8),
            Container(
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(4),
                itemCount: searchResults.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, index) {
                  final song = searchResults[index];
                  final artwork =
                      song['artworkUrl60']?.toString() ?? '';
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    leading: artwork.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(artwork,
                                width: 40, height: 40, fit: BoxFit.cover),
                          )
                        : null,
                    title: Text(
                      song['trackName']?.toString() ?? '',
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song['artistName']?.toString() ?? '',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      _selectSong(song);
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
