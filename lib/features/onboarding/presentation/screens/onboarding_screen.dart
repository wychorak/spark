import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/core/router/app_router.dart';
import 'package:spark/core/theme/app_theme.dart';
import 'package:spark/shared/providers/auth_provider.dart';
import 'package:spark/shared/widgets/neon_button.dart';
import 'package:spark/shared/widgets/neon_text_field.dart';

// ── Interest data ──
const _interests = [
  {'emoji': '🎵', 'label': 'Muzyka'},
  {'emoji': '🎬', 'label': 'Film'},
  {'emoji': '📚', 'label': 'Książki'},
  {'emoji': '🎮', 'label': 'Gry'},
  {'emoji': '⚽', 'label': 'Sport'},
  {'emoji': '🏋️', 'label': 'Siłownia'},
  {'emoji': '🧘', 'label': 'Joga'},
  {'emoji': '🎨', 'label': 'Sztuka'},
  {'emoji': '📸', 'label': 'Fotografia'},
  {'emoji': '✈️', 'label': 'Podróże'},
  {'emoji': '🍳', 'label': 'Gotowanie'},
  {'emoji': '🍷', 'label': 'Wino'},
  {'emoji': '☕', 'label': 'Kawa'},
  {'emoji': '🐶', 'label': 'Psy'},
  {'emoji': '🐱', 'label': 'Koty'},
  {'emoji': '🌿', 'label': 'Natura'},
  {'emoji': '🎭', 'label': 'Teatr'},
  {'emoji': '💃', 'label': 'Taniec'},
  {'emoji': '🎤', 'label': 'Karaoke'},
  {'emoji': '🧗', 'label': 'Wspinaczka'},
  {'emoji': '🚴', 'label': 'Rower'},
  {'emoji': '🏊', 'label': 'Pływanie'},
  {'emoji': '🎧', 'label': 'Podcasty'},
  {'emoji': '🖥️', 'label': 'Technologia'},
  {'emoji': '🌍', 'label': 'Ekologia'},
  {'emoji': '🧩', 'label': 'Puzzle'},
  {'emoji': '🎪', 'label': 'Festiwale'},
  {'emoji': '🍕', 'label': 'Pizza'},
  {'emoji': '🎹', 'label': 'Instrument'},
  {'emoji': '📝', 'label': 'Pisanie'},
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 7;

  // Step 1: Name + birth date
  final _nameController = TextEditingController();
  DateTime _birthDate = DateTime(2000, 1, 1);

  // Step 2: Gender
  String? _selectedGender;

  // Step 3: Photos
  final List<XFile?> _photos = List.filled(6, null);
  final _picker = ImagePicker();

  // Step 4: Bio
  final _bioController = TextEditingController();

  // Step 5: Interests
  final Set<int> _selectedInterests = {};

  // Step 6: Modes
  final Set<String> _selectedModes = {};

  // Step 7: Location
  bool _locationGranted = false;
  Position? _position;

  bool _isSaving = false;

  int get _photoCount => _photos.where((p) => p != null).length;

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _selectedGender != null;
      case 2:
        return _photoCount >= 2;
      case 3:
        return true; // Bio is optional
      case 4:
        return _selectedInterests.length >= 3;
      case 5:
        return _selectedModes.isNotEmpty;
      case 6:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: AppDimensions.animNormal),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _finish();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: AppDimensions.animNormal),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
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
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.camera_alt, color: AppColors.neonPink),
              title: Text('Aparat',
                  style: GoogleFonts.outfit(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.neonPink),
              title: Text('Galeria',
                  style: GoogleFonts.outfit(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final image = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _photos[index] = image);
    }
  }

  Future<void> _requestLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
        setState(() {
          _locationGranted = true;
          _position = pos;
        });
      } catch (_) {
        setState(() => _locationGranted = false);
      }
    }
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final supabase = Supabase.instance.client;

      // Upload photos
      final List<String> photoUrls = [];
      for (int i = 0; i < _photos.length; i++) {
        final photo = _photos[i];
        if (photo == null) continue;
        final bytes = await photo.readAsBytes();
        final path = 'profiles/${user.id}/photo_$i.jpg';
        await supabase.storage.from('photos').uploadBinary(path, bytes,
            fileOptions: const FileOptions(upsert: true));
        final url = supabase.storage.from('photos').getPublicUrl(path);
        photoUrls.add(url);
      }

      // Save profile
      final selectedInterestLabels = _selectedInterests
          .map((i) => _interests[i]['label'] as String)
          .toList();

      await supabase.from('profiles').upsert({
        'id': user.id,
        'name': _nameController.text.trim(),
        'birth_date': _birthDate.toIso8601String().split('T').first,
        'gender': _selectedGender,
        'photos': photoUrls,
        'bio': _bioController.text.trim(),
        'interests': selectedInterestLabels,
        'modes': _selectedModes.toList(),
        if (_position != null) 'latitude': _position!.latitude,
        if (_position != null) 'longitude': _position!.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        context.go(RoutePaths.discovery);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.errorGeneral)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding,
                vertical: AppDimensions.paddingM,
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    GestureDetector(
                      onTap: _prevStep,
                      child: const Padding(
                        padding:
                            EdgeInsets.only(right: AppDimensions.spacing12),
                        child: Icon(Icons.arrow_back_ios,
                            color: AppColors.textPrimary, size: 20),
                      ),
                    ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusRound),
                      child: Stack(
                        children: [
                          Container(
                            height: 4,
                            color: AppColors.surfaceLight,
                          ),
                          AnimatedContainer(
                            duration: const Duration(
                                milliseconds: AppDimensions.animNormal),
                            height: 4,
                            width: MediaQuery.of(context).size.width *
                                ((_currentStep + 1) / _totalSteps),
                            decoration: const BoxDecoration(
                              gradient: AppColors.neonPinkGradient,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(AppDimensions.spacing12),
                  Text(
                    '${_currentStep + 1}/$_totalSteps',
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildNameStep(),
                  _buildGenderStep(),
                  _buildPhotosStep(),
                  _buildBioStep(),
                  _buildInterestsStep(),
                  _buildModeStep(),
                  _buildLocationStep(),
                ],
              ),
            ),

            // Next / Done button
            Padding(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              child: SizedBox(
                width: double.infinity,
                child: NeonButton(
                  label: _currentStep == _totalSteps - 1
                      ? AppStrings.done
                      : AppStrings.next,
                  onPressed: _canProceed ? _nextStep : null,
                  enabled: _canProceed,
                  isLoading: _isSaving,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Name + Birth date ──
  Widget _buildNameStep() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(AppDimensions.spacing32),
          Text(
            AppStrings.onboardingName,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              shadows: AppTheme.neonTextShadow(blurRadius: 8),
            ),
          ).animate().fadeIn(duration: 500.ms),
          const Gap(AppDimensions.spacing24),
          NeonTextField(
            controller: _nameController,
            hint: AppStrings.onboardingNameHint,
            prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
          ),
          const Gap(AppDimensions.spacing32),
          Text(
            AppStrings.onboardingBirthdate,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(AppDimensions.spacing16),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _birthDate,
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.neonPink,
                      surface: AppColors.surface,
                      onSurface: AppColors.textPrimary,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (date != null) setState(() => _birthDate = date);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: AppTheme.subtleNeonGlow(),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: AppColors.neonPink, size: 20),
                  const Gap(AppDimensions.spacing12),
                  Text(
                    '${_birthDate.day.toString().padLeft(2, '0')}.${_birthDate.month.toString().padLeft(2, '0')}.${_birthDate.year}',
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Gender ──
  Widget _buildGenderStep() {
    final genders = [
      {'key': 'female', 'label': AppStrings.onboardingGenderFemale, 'icon': Icons.female},
      {'key': 'male', 'label': AppStrings.onboardingGenderMale, 'icon': Icons.male},
      {'key': 'non_binary', 'label': AppStrings.onboardingGenderNonBinary, 'icon': Icons.transgender},
    ];

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(AppDimensions.spacing32),
          Text(
            AppStrings.onboardingGender,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              shadows: AppTheme.neonTextShadow(blurRadius: 8),
            ),
          ).animate().fadeIn(duration: 500.ms),
          const Gap(AppDimensions.spacing32),
          ...genders.asMap().entries.map((entry) {
            final index = entry.key;
            final g = entry.value;
            final key = g['key'] as String;
            final isSelected = _selectedGender == key;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacing16),
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = key),
                child: AnimatedContainer(
                  duration: const Duration(
                      milliseconds: AppDimensions.animNormal),
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  decoration: isSelected
                      ? AppTheme.neonGlowDecoration(
                          color: AppColors.neonPink,
                          blurRadius: AppDimensions.neonBlurSmall,
                          backgroundColor: AppColors.surface,
                        )
                      : BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusL),
                          border: Border.all(
                              color: AppColors.divider, width: 1),
                        ),
                  child: Row(
                    children: [
                      Icon(
                        g['icon'] as IconData,
                        color: isSelected
                            ? AppColors.neonPink
                            : AppColors.textSecondary,
                        size: AppDimensions.iconL,
                      ),
                      const Gap(AppDimensions.spacing16),
                      Text(
                        g['label'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                      delay: Duration(milliseconds: 100 * index),
                      duration: 400.ms)
                  .slideX(
                      begin: 0.1,
                      end: 0,
                      delay: Duration(milliseconds: 100 * index),
                      duration: 400.ms),
            );
          }),
        ],
      ),
    );
  }

  // ── Step 3: Photos ──
  Widget _buildPhotosStep() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(AppDimensions.spacing32),
          Text(
            AppStrings.onboardingPhotos,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              shadows: AppTheme.neonTextShadow(blurRadius: 8),
            ),
          ).animate().fadeIn(duration: 500.ms),
          const Gap(AppDimensions.spacing8),
          Text(
            AppStrings.onboardingPhotosSubtitle,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(AppDimensions.spacing24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppDimensions.spacing12,
                mainAxisSpacing: AppDimensions.spacing12,
                childAspectRatio: 0.75,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return GestureDetector(
                  onTap: () => _pickPhoto(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(
                        color: photo != null
                            ? AppColors.neonPink.withValues(alpha: 0.5)
                            : AppColors.divider,
                        width: photo != null ? 1.5 : 1,
                      ),
                      image: photo != null
                          ? DecorationImage(
                              image: FileImage(File(photo.path)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: photo == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: AppColors.textHint,
                                size: AppDimensions.iconL,
                              ),
                              const Gap(AppDimensions.spacing4),
                              if (index < 2)
                                Text(
                                  'Wymagane',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: AppColors.neonPink,
                                  ),
                                ),
                            ],
                          )
                        : Align(
                            alignment: Alignment.topRight,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _photos[index] = null),
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.overlay,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: AppColors.white, size: 14),
                              ),
                            ),
                          ),
                  ),
                )
                    .animate()
                    .fadeIn(
                        delay: Duration(milliseconds: 80 * index),
                        duration: 400.ms)
                    .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        delay: Duration(milliseconds: 80 * index),
                        duration: 400.ms);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 4: Bio ──
  Widget _buildBioStep() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(AppDimensions.spacing32),
          Text(
            AppStrings.onboardingBio,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              shadows: AppTheme.neonTextShadow(blurRadius: 8),
            ),
          ).animate().fadeIn(duration: 500.ms),
          const Gap(AppDimensions.spacing24),
          NeonTextField(
            controller: _bioController,
            hint: AppStrings.onboardingBioHint,
            maxLines: 6,
            minLines: 4,
            maxLength: 500,
            onChanged: (_) => setState(() {}),
          ),
          const Gap(AppDimensions.spacing8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_bioController.text.length}/500',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: _bioController.text.length > 450
                    ? AppColors.warning
                    : AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 5: Interests ──
  Widget _buildInterestsStep() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(AppDimensions.spacing32),
          Text(
            AppStrings.onboardingInterests,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              shadows: AppTheme.neonTextShadow(blurRadius: 8),
            ),
          ).animate().fadeIn(duration: 500.ms),
          const Gap(AppDimensions.spacing8),
          Text(
            'Wybierz co najmniej 3 (${_selectedInterests.length} wybrano)',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(AppDimensions.spacing16),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: AppDimensions.spacing8,
                runSpacing: AppDimensions.spacing8,
                children: _interests.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = _selectedInterests.contains(index);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedInterests.remove(index);
                        } else {
                          _selectedInterests.add(index);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(
                          milliseconds: AppDimensions.animFast),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusRound),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.neonPink
                              : AppColors.divider,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.neonPinkGlow,
                                  blurRadius: AppDimensions.neonBlurSmall,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        '${item['emoji']} ${item['label']}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 6: Mode selection ──
  Widget _buildModeStep() {
    final modes = [
      {
        'key': 'relationship',
        'label': AppStrings.onboardingModeRelationship,
        'desc': 'Szukam poważnego związku',
        'color': AppColors.modeRelationship,
        'icon': Icons.favorite,
      },
      {
        'key': 'friends',
        'label': AppStrings.onboardingModeFriends,
        'desc': 'Szukam nowych znajomości',
        'color': AppColors.modeFriends,
        'icon': Icons.people,
      },
      {
        'key': 'fwb',
        'label': AppStrings.onboardingModeFWB,
        'desc': 'Coś niezobowiązującego',
        'color': AppColors.modeFWB,
        'icon': Icons.local_fire_department,
      },
    ];

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(AppDimensions.spacing32),
          Text(
            AppStrings.onboardingMode,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              shadows: AppTheme.neonTextShadow(blurRadius: 8),
            ),
          ).animate().fadeIn(duration: 500.ms),
          const Gap(AppDimensions.spacing8),
          Text(
            'Możesz wybrać kilka opcji',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(AppDimensions.spacing24),
          ...modes.asMap().entries.map((entry) {
            final index = entry.key;
            final m = entry.value;
            final key = m['key'] as String;
            final color = m['color'] as Color;
            final isSelected = _selectedModes.contains(key);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacing16),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedModes.remove(key);
                    } else {
                      _selectedModes.add(key);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration:
                      const Duration(milliseconds: AppDimensions.animNormal),
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  decoration: isSelected
                      ? AppTheme.neonGlowDecoration(
                          color: color,
                          blurRadius: AppDimensions.neonBlurSmall,
                          backgroundColor: AppColors.surface,
                        )
                      : BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusL),
                          border:
                              Border.all(color: AppColors.divider, width: 1),
                        ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusM),
                        ),
                        child: Icon(
                          m['icon'] as IconData,
                          color: color,
                          size: AppDimensions.iconM,
                        ),
                      ),
                      const Gap(AppDimensions.spacing16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m['label'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? color
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const Gap(AppDimensions.spacing4),
                            Text(
                              m['desc'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: color, size: 24),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                      delay: Duration(milliseconds: 100 * index),
                      duration: 400.ms)
                  .slideX(
                      begin: 0.1,
                      end: 0,
                      delay: Duration(milliseconds: 100 * index),
                      duration: 400.ms),
            );
          }),
        ],
      ),
    );
  }

  // ── Step 7: Location ──
  Widget _buildLocationStep() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonPink.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.neonPink.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              _locationGranted
                  ? Icons.check_circle_outline
                  : Icons.location_on_outlined,
              color: AppColors.neonPink,
              size: AppDimensions.iconXXL,
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut),
          const Gap(AppDimensions.spacing32),
          Text(
            _locationGranted
                ? 'Lokalizacja przyznana!'
                : 'Włącz lokalizację',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              shadows: AppTheme.neonTextShadow(blurRadius: 8),
            ),
          ),
          const Gap(AppDimensions.spacing12),
          Text(
            _locationGranted
                ? 'Spark pokaże Ci osoby w pobliżu.'
                : 'Spark potrzebuje dostępu do Twojej lokalizacji, aby pokazywać osoby w Twojej okolicy.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(AppDimensions.spacing32),
          if (!_locationGranted)
            SizedBox(
              width: double.infinity,
              child: NeonButton(
                label: 'Włącz lokalizację',
                icon: Icons.my_location,
                onPressed: _requestLocation,
              ),
            ),
          if (!_locationGranted) ...[
            const Gap(AppDimensions.spacing16),
            TextButton(
              onPressed: () {},
              child: Text(
                AppStrings.skip,
                style: GoogleFonts.outfit(
                  color: AppColors.textHint,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
