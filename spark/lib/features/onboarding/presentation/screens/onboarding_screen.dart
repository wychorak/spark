import 'dart:typed_data';

import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
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
import 'package:spark/core/services/analytics_service.dart';
import 'package:spark/core/theme/app_theme.dart';
import 'package:spark/features/notifications/notification_service.dart';
import 'package:spark/shared/widgets/neon_button.dart';
import 'package:spark/shared/widgets/neon_text_field.dart';

// ── Interest data (names must match DB `interests` table exactly) ──
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
  {'emoji': '🐕', 'label': 'Psy'},
  {'emoji': '🐈', 'label': 'Koty'},
  {'emoji': '🌿', 'label': 'Natura'},
  {'emoji': '🎭', 'label': 'Teatr'},
  {'emoji': '💃', 'label': 'Taniec'},
  {'emoji': '🎤', 'label': 'Karaoke'},
  {'emoji': '🧗', 'label': 'Wspinaczka'},
  {'emoji': '🚴', 'label': 'Rower'},
  {'emoji': '🏊', 'label': 'Pływanie'},
  {'emoji': '🎧', 'label': 'Podcasty'},
  {'emoji': '💻', 'label': 'Technologia'},
  {'emoji': '♻️', 'label': 'Ekologia'},
  {'emoji': '🧩', 'label': 'Puzzle'},
  {'emoji': '🎪', 'label': 'Festiwale'},
  {'emoji': '🍕', 'label': 'Pizza'},
  {'emoji': '🎹', 'label': 'Instrument'},
  {'emoji': '📝', 'label': 'Pisanie'},
];

const _maxInterests = 5;
const _minInterests = 3;

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  static const Set<int> _optionalSteps = {3, 5, 6, 8};
  static const List<String> _stepLabels = [
    'Podstawy',
    'Tożsamość',
    'Zdjęcia',
    'Bio',
    'Zainteresowania',
    'Preferencje',
    'Sociale',
    'Tryby',
    'Lokalizacja',
    'Podsumowanie',
  ];

  final _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 10;

  // Step 1: Name + birth date
  final _nameController = TextEditingController();
  DateTime _birthDate = DateTime(2000, 1, 1);

  // Step 2: Gender
  String? _selectedGender;

  // Step 3: Photos
  final List<XFile?> _photos = List.filled(6, null);
  final Map<int, Uint8List> _photoBytes = {};
  final _picker = ImagePicker();

  // Step 4: Bio
  final _bioController = TextEditingController();

  // Step 5: Interests (min 3, max 5)
  final Set<int> _selectedInterests = {};

  // Step 6: Desired interests in partner (min 3, max 5)
  final Set<int> _selectedDesiredInterests = {};

  // Step 7: Social media links
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _snapchatController = TextEditingController();

  // Step 8: Modes
  final Set<String> _selectedModes = {};

  // Step 9: Location
  bool _locationGranted = false;
  Position? _position;
  String? _detectedCity;

  bool _isSaving = false;

  // Animation controllers for mode cards
  late final List<AnimationController> _modeControllers;

  @override
  void initState() {
    super.initState();
    _modeControllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
        lowerBound: 1.0,
        upperBound: 1.04,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _snapchatController.dispose();
    for (final c in _modeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  int get _photoCount => _photos.where((p) => p != null).length;

  bool get _isCurrentStepOptional => _optionalSteps.contains(_currentStep);

  String get _currentStepLabel => _stepLabels[_currentStep];

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _selectedGender != null;
      case 2:
        return _photoCount >= 2;
      case 3:
        return true;
      case 4:
        return _selectedInterests.length >= _minInterests;
      case 5:
        return true;
      case 6:
        return true; // social media is optional
      case 7:
        return _selectedModes.isNotEmpty;
      case 8:
        return true;
      case 9:
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

  void _skipCurrentStep() {
    if (_currentStep == _totalSteps - 1) return;
    _nextStep();
  }

  Future<void> _pickPhoto(int index) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
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
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('Aparat',
                  style: GoogleFonts.outfit(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
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
      final bytes = await image.readAsBytes();
      setState(() {
        _photos[index] = image;
        _photoBytes[index] = bytes;
      });
    }
  }

  Future<void> _requestLocation() async {
    try {
      if (kIsWeb) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
        setState(() {
          _locationGranted = true;
          _position = pos;
        });
        await _resolveCity(pos);
      } else {
        final status = await Permission.location.request();
        if (status.isGranted) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          );
          setState(() {
            _locationGranted = true;
            _position = pos;
          });
          await _resolveCity(pos);
        }
      }
    } catch (_) {
      setState(() => _locationGranted = false);
    }
  }

  Future<void> _resolveCity(Position pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (!mounted || placemarks.isEmpty) return;
      final place = placemarks.first;
      final city = ([
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
      ].firstWhere(
        (value) => value != null && value.trim().isNotEmpty,
        orElse: () => '',
      )) ??
          '';
      if (city.trim().isEmpty) return;
      setState(() => _detectedCity = city.trim());
    } catch (_) {}
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      User? user = supabase.auth.currentUser;
      if (user == null) {
        try {
          final refreshed = await supabase.auth.refreshSession();
          user = refreshed.user;
        } catch (_) {}
      }

      if (user == null) {
        if (mounted) context.go(RoutePaths.home);
        return;
      }

      // 1. Upload photos
      for (int i = 0; i < _photos.length; i++) {
        final photo = _photos[i];
        if (photo == null) continue;
        try {
          final bytes = _photoBytes[i] ?? await photo.readAsBytes();
          final path = 'profiles/${user.id}/photo_$i.jpg';
          await supabase.storage.from('photos').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );
        } catch (_) {}
      }

      // 2. Save profile via RPC
      await supabase.rpc('fn_upsert_profile', params: {
        'p_display_name': _nameController.text.trim(),
        'p_born_at': _birthDate.toIso8601String().split('T').first,
        'p_gender': _selectedGender ?? 'female',
        'p_bio': _bioController.text.trim(),
        'p_modes': _selectedModes.toList(),
        'p_city': _detectedCity,
      });

      // 3. Save interests
      if (_selectedInterests.isNotEmpty) {
        try {
          final interestNames = _selectedInterests
              .map((i) => _interests[i]['label'] as String)
              .toList();
          await supabase.rpc('fn_save_user_interests', params: {
            'p_interest_names': interestNames,
          });
        } catch (_) {}
      }

      // 4. Save desired interests
      if (_selectedDesiredInterests.isNotEmpty) {
        try {
          final desiredNames = _selectedDesiredInterests
              .map((i) => _interests[i]['label'] as String)
              .toList();
          await supabase.from('user_profiles').update({
            'desired_interests': desiredNames,
          }).eq('id', user.id);
        } catch (_) {}
      }

      // 5. Save social media handles
      try {
        final socialHandles = <String, String?>{};
        if (_instagramController.text.trim().isNotEmpty) {
          socialHandles['instagram_handle'] = _instagramController.text.trim();
        }
        if (_tiktokController.text.trim().isNotEmpty) {
          socialHandles['tiktok_handle'] = _tiktokController.text.trim();
        }
        if (_snapchatController.text.trim().isNotEmpty) {
          socialHandles['snapchat_handle'] = _snapchatController.text.trim();
        }
        if (socialHandles.isNotEmpty) {
          await supabase.from('user_profiles').update(socialHandles).eq('id', user.id);
        }
      } catch (_) {}

      // 6. Save photo metadata
      for (int i = 0; i < _photos.length; i++) {
        if (_photos[i] == null) continue;
        try {
          final path = 'profiles/${user.id}/photo_$i.jpg';
          await supabase.rpc('fn_save_user_photo', params: {
            'p_storage_path': path,
            'p_position': i,
            'p_is_primary': i == 0,
          });
        } catch (_) {}
      }

      // 7. Update location if granted
      if (_position != null) {
        try {
          await supabase.rpc('fn_update_user_location', params: {
            'lat': _position!.latitude,
            'lng': _position!.longitude,
            'city_name': _detectedCity,
          });
        } catch (_) {}
      }

      if (mounted) {
        await NotificationService.instance.init();
        await AnalyticsService.instance.track(
          'onboarding_completed',
          properties: {
            'photos_count': _photoCount,
            'interests_count': _selectedInterests.length,
            'desired_interests_count': _selectedDesiredInterests.length,
            'modes_count': _selectedModes.length,
            'location_granted': _position != null,
          },
        );
        context.go(RoutePaths.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd zapisu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                              Container(height: 4, color: AppColors.surfaceLight),
                              AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: AppDimensions.animNormal),
                                height: 4,
                                width: MediaQuery.of(context).size.width *
                                    ((_currentStep + 1) / _totalSteps),
                                decoration: BoxDecoration(
                                  gradient: AppColors.neonPinkGradient,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Gap(AppDimensions.spacing12),
                      Text(
                        'Krok ${_currentStep + 1} z $_totalSteps',
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Gap(AppDimensions.spacing12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentStepLabel,
                              style: GoogleFonts.outfit(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Gap(2),
                            Text(
                              _isCurrentStepOptional
                                  ? 'Opcjonalne, możesz wrócić do tego później.'
                                  : 'Uzupełnij, żeby profil dobrze wystartował.',
                              style: GoogleFonts.outfit(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isCurrentStepOptional && _currentStep < _totalSteps - 1)
                        TextButton(
                          onPressed: _skipCurrentStep,
                          child: Text(
                            AppStrings.skip,
                            style: GoogleFonts.outfit(
                              color: AppColors.textHint,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
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
                  _buildDesiredInterestsStep(),
                  _buildSocialMediaStep(),
                  _buildModeStep(),
                  _buildLocationStep(),
                  _buildSummaryStep(),
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
                      : _isCurrentStepOptional
                          ? 'Dalej'
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
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
                    colorScheme: ColorScheme.light(
                      primary: AppColors.primary,
                      surface: AppColors.white,
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
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: AppColors.primary, size: 20),
                  const Gap(AppDimensions.spacing12),
                  Text(
                    '${_birthDate.day.toString().padLeft(2, '0')}.${_birthDate.month.toString().padLeft(2, '0')}.${_birthDate.year}',
                    style: GoogleFonts.outfit(
                        color: AppColors.textPrimary, fontSize: 16),
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
      {
        'key': 'female',
        'label': AppStrings.onboardingGenderFemale,
        'icon': Icons.female
      },
      {
        'key': 'male',
        'label': AppStrings.onboardingGenderMale,
        'icon': Icons.male
      },
      {
        'key': 'nonbinary',
        'label': AppStrings.onboardingGenderNonBinary,
        'icon': Icons.transgender
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
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
            ),
          ).animate().fadeIn(duration: 500.ms),
          const Gap(AppDimensions.spacing32),
          ...genders.asMap().entries.map((entry) {
            final index = entry.key;
            final g = entry.value;
            final key = g['key'] as String;
            final isSelected = _selectedGender == key;
            return Padding(
              padding:
                  const EdgeInsets.only(bottom: AppDimensions.spacing16),
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = key),
                child: AnimatedContainer(
                  duration: const Duration(
                      milliseconds: AppDimensions.animNormal),
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(
                        AppDimensions.radiusL),
                    border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                        width: isSelected ? 1.5 : 1),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        g['icon'] as IconData,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: AppDimensions.iconL,
                      ),
                      const Gap(AppDimensions.spacing16),
                      Text(
                        g['label'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
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
            ),
          ).animate().fadeIn(duration: 500.ms),
          const Gap(AppDimensions.spacing8),
          Text(
            AppStrings.onboardingPhotosSubtitle,
            style: GoogleFonts.outfit(
                fontSize: 14, color: AppColors.textSecondary),
          ),
          const Gap(AppDimensions.spacing24),
          Expanded(
            child: GridView.builder(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppDimensions.spacing12,
                mainAxisSpacing: AppDimensions.spacing12,
                childAspectRatio: 0.75,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                final bytes = _photoBytes[index];
                final hasPhoto = photo != null && bytes != null;

                return GestureDetector(
                  onTap: () => _pickPhoto(index),
                  child: AnimatedContainer(
                    duration: const Duration(
                        milliseconds: AppDimensions.animFast),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM),
                      border: Border.all(
                        color: hasPhoto
                            ? AppColors.primary
                                .withValues(alpha: 0.6)
                            : AppColors.divider,
                        width: hasPhoto ? 1.5 : 1,
                      ),
                      boxShadow: hasPhoto
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasPhoto
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(bytes,
                                  fit: BoxFit.cover),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _photos[index] = null;
                                    _photoBytes.remove(index);
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.black.withValues(alpha: 0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: AppColors.white,
                                        size: 14),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
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
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
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
    return _buildInterestSelector(
      title: AppStrings.onboardingInterests,
      subtitle: 'Twoje zainteresowania',
      selectedSet: _selectedInterests,
    );
  }

  // ── Step 6: Desired Interests ──
  Widget _buildDesiredInterestsStep() {
    return _buildInterestSelector(
      title: 'Poszukiwane zainteresowania',
      subtitle: 'Opcjonalnie: zaznacz, co fajnie byłoby znaleźć u drugiej osoby.',
      selectedSet: _selectedDesiredInterests,
      isOptional: true,
    );
  }

  Widget _buildInterestSelector({
    required String title,
    required String subtitle,
    required Set<int> selectedSet,
    bool isOptional = false,
  }) {
    final remaining = _maxInterests - selectedSet.length;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(AppDimensions.spacing32),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn(duration: 500.ms),
          const Gap(AppDimensions.spacing4),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(AppDimensions.spacing8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              isOptional && selectedSet.isEmpty
                  ? 'Możesz to pominąć i wrócić później.'
                  : selectedSet.length < _minInterests
                  ? 'Wybierz co najmniej $_minInterests (${selectedSet.length} wybrano)'
                  : selectedSet.length == _maxInterests
                      ? 'Maksimum osiągnięte ($_maxInterests/$_maxInterests wybrano)'
                      : 'Możesz wybrać jeszcze $remaining (${selectedSet.length}/$_maxInterests wybrano)',
              key: ValueKey('${selectedSet.length}_$title'),
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: selectedSet.length == _maxInterests
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
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
                  final isSelected = selectedSet.contains(index);
                  final isDisabled = !isSelected &&
                      selectedSet.length >= _maxInterests;

                  return GestureDetector(
                    onTap: isDisabled
                        ? null
                        : () {
                            setState(() {
                              if (isSelected) {
                                selectedSet.remove(index);
                              } else {
                                selectedSet.add(index);
                              }
                            });
                          },
                    child: AnimatedContainer(
                      duration: const Duration(
                          milliseconds: AppDimensions.animFast),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : isDisabled
                                ? AppColors.white.withValues(alpha: 0.5)
                                : AppColors.white,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusRound),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : isDisabled
                                  ? AppColors.divider
                                      .withValues(alpha: 0.3)
                                  : AppColors.divider,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  blurRadius: 8,
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
                              : isDisabled
                                  ? AppColors.textHint
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

  // ── Step 7: Social Media ──
  Widget _buildSocialMediaStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(AppDimensions.spacing32),
          Text(
            'Social media',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn(duration: 500.ms),
          const Gap(AppDimensions.spacing8),
          Text(
            'Opcjonalne - dodaj swoje profile',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(AppDimensions.spacing24),
          _SocialField(
            controller: _instagramController,
            label: 'Instagram',
            icon: Icons.camera_alt_outlined,
            hint: '@twoj_instagram',
          ),
          const Gap(AppDimensions.spacing16),
          _SocialField(
            controller: _tiktokController,
            label: 'TikTok',
            icon: Icons.music_note_outlined,
            hint: '@twoj_tiktok',
          ),
          const Gap(AppDimensions.spacing16),
          _SocialField(
            controller: _snapchatController,
            label: 'Snapchat',
            icon: Icons.snapchat_outlined,
            hint: '@twoj_snapchat',
          ),
          const Gap(AppDimensions.spacing16),
          Text(
            'Twoje profile będą widoczne na Twoim profilu Spark',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 8: Mode selection ──
  Widget _buildModeStep() {
    final modes = [
      {
        'key': 'relationship',
        'label': AppStrings.onboardingModeRelationship,
        'desc': 'Szukam poważnego związku',
        'color': AppColors.modeRelationship,
        'icon': Icons.favorite_rounded,
        'emoji': '💕',
      },
      {
        'key': 'friends',
        'label': AppStrings.onboardingModeFriends,
        'desc': 'Szukam nowych znajomości',
        'color': AppColors.modeFriends,
        'icon': Icons.people_rounded,
        'emoji': '👋',
      },
      {
        'key': 'fwb',
        'label': AppStrings.onboardingModeFWB,
        'desc': 'Coś niezobowiązującego',
        'color': AppColors.modeFWB,
        'icon': Icons.local_fire_department_rounded,
        'emoji': '🔥',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(AppDimensions.spacing32),
          Text(
            AppStrings.onboardingMode,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: -0.1, end: 0, duration: 500.ms),
          const Gap(AppDimensions.spacing4),
          Text(
            'Możesz wybrać kilka opcji',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const Gap(AppDimensions.spacing24),
          ...modes.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;
            final key = m['key'] as String;
            final color = m['color'] as Color;
            final isSelected = _selectedModes.contains(key);

            return Padding(
              padding:
                  const EdgeInsets.only(bottom: AppDimensions.spacing16),
              child: ScaleTransition(
                scale: _modeControllers[idx],
                child: GestureDetector(
                  onTapDown: (_) => _modeControllers[idx].forward(),
                  onTapUp: (_) {
                    _modeControllers[idx].reverse();
                    setState(() {
                      if (isSelected) {
                        _selectedModes.remove(key);
                      } else {
                        _selectedModes.add(key);
                      }
                    });
                  },
                  onTapCancel: () => _modeControllers[idx].reverse(),
                  child: AnimatedContainer(
                    duration: const Duration(
                        milliseconds: AppDimensions.animNormal),
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.08)
                          : AppColors.white,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusXL),
                      border: Border.all(
                        color: isSelected
                            ? color.withValues(alpha: 0.8)
                            : AppColors.divider,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.15),
                                blurRadius: 16,
                                spreadRadius: 0,
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(
                              milliseconds: AppDimensions.animNormal),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: color.withValues(
                                alpha: isSelected ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(
                                    color: color.withValues(alpha: 0.3),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              m['emoji'] as String,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                        const Gap(AppDimensions.spacing16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(
                                    milliseconds: AppDimensions.animFast),
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? color
                                      : AppColors.textPrimary,
                                ),
                                child: Text(m['label'] as String),
                              ),
                              const Gap(AppDimensions.spacing4),
                              Text(
                                m['desc'] as String,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: isSelected
                                      ? color.withValues(alpha: 0.7)
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(
                              milliseconds: AppDimensions.animFast),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : AppColors.textHint,
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(
                    delay: Duration(milliseconds: 120 * idx),
                    duration: 400.ms)
                .slideY(
                    begin: 0.15,
                    end: 0,
                    delay: Duration(milliseconds: 120 * idx),
                    duration: 400.ms,
                    curve: Curves.easeOutCubic);
          }),
        ],
      ),
    );
  }

  // ── Step 9: Location ──
  Widget _buildLocationStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PulsingLocationIcon(granted: _locationGranted)
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut),
          const Gap(AppDimensions.spacing32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _locationGranted
                  ? 'Lokalizacja włączona!'
                  : 'Włącz lokalizację',
              key: ValueKey(_locationGranted),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _locationGranted
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
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
          if (!_locationGranted) ...[
            SizedBox(
              width: double.infinity,
              child: NeonButton(
                label: 'Włącz lokalizację',
                icon: Icons.my_location,
                onPressed: _requestLocation,
              ),
            ),
            const Gap(AppDimensions.spacing16),
            TextButton(
              onPressed: _nextStep,
              child: Text(
                AppStrings.skip,
                style: GoogleFonts.outfit(
                    color: AppColors.textHint, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Step 10: Summary ──
  Widget _buildSummaryStep() {
    final firstPhotoIndex = _photos.indexWhere((photo) => photo != null);
    final previewBytes =
        firstPhotoIndex >= 0 ? _photoBytes[firstPhotoIndex] : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Gap(AppDimensions.spacing32),
          Icon(Icons.check_circle_outline,
              color: AppColors.primary, size: 64)
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.5, 0.5), duration: 500.ms),
          const Gap(AppDimensions.spacing16),
          Text(
            'Wszystko gotowe!',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
          const Gap(AppDimensions.spacing8),
          Text(
            'Twój profil Spark jest gotowy do odkrywania.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
          const Gap(AppDimensions.spacing32),
          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage:
                            previewBytes != null ? MemoryImage(previewBytes) : null,
                        child: _photoCount == 0
                            ? const Icon(
                                Icons.person_rounded,
                                color: AppColors.primary,
                                size: 32,
                              )
                            : null,
                      ),
                      const Gap(12),
                      Text(
                        _nameController.text.trim().isEmpty
                            ? 'Twój profil Spark'
                            : _nameController.text.trim(),
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_selectedModes.isNotEmpty) ...[
                        const Gap(10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: _selectedModes.map((mode) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.colorForMode(mode)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                mode == 'relationship'
                                    ? 'Związek'
                                    : mode == 'friends'
                                        ? 'Znajomi'
                                        : 'FWB',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.colorForMode(mode),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const Gap(16),
                    ],
                  ),
                ),
                _SummaryRow(label: 'Imię', value: _nameController.text.trim()),
                _SummaryRow(
                    label: 'Płeć',
                    value: _selectedGender == 'female'
                        ? 'Kobieta'
                        : _selectedGender == 'male'
                            ? 'Mężczyzna'
                            : 'Niebinarna'),
                _SummaryRow(
                    label: 'Zdjęcia', value: '$_photoCount dodanych'),
                _SummaryRow(
                    label: 'Zainteresowania',
                    value: '${_selectedInterests.length} wybranych'),
                _SummaryRow(
                    label: 'Poszukiwane',
                    value: '${_selectedDesiredInterests.length} wybranych'),
                if (_selectedModes.isNotEmpty)
                  _SummaryRow(
                      label: 'Tryby',
                      value: _selectedModes.join(', ')),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
        ],
      ),
    );
  }
}

// ── Social Field ──
class _SocialField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;

  const _SocialField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Gap(8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                color: AppColors.textHint,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Summary Row ──
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pulsing location icon ──
class _PulsingLocationIcon extends StatefulWidget {
  final bool granted;
  const _PulsingLocationIcon({required this.granted});

  @override
  State<_PulsingLocationIcon> createState() => _PulsingLocationIconState();
}

class _PulsingLocationIconState extends State<_PulsingLocationIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.granted
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.primary.withValues(alpha: 0.08),
          border: Border.all(
            color: widget.granted
                ? AppColors.primary.withValues(alpha: 0.8)
                : AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary
                  .withValues(alpha: widget.granted ? 0.3 : 0.1),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Icon(
          widget.granted
              ? Icons.check_circle_outline_rounded
              : Icons.location_on_rounded,
          color: AppColors.primary,
          size: 52,
        ),
      ),
    );
  }
}
