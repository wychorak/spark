import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/shared/providers/profile_provider.dart';

class ProfileDetailScreen extends ConsumerWidget {
  final String profileId;
  const ProfileDetailScreen({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For 'me', show current user profile
    final profileAsync = profileId == 'me'
        ? ref.watch(currentProfileProvider)
        : ref.watch(profileByIdProvider(profileId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profil',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.neonPink),
        ),
        error: (_, __) => Center(
          child: Text(
            'Nie udało się załadować profilu',
            style: GoogleFonts.outfit(color: AppColors.textSecondary),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(
                'Profil nie znaleziony',
                style: GoogleFonts.outfit(color: AppColors.textSecondary),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo
                if (profile.photoUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                    child: AspectRatio(
                      aspectRatio: 0.75,
                      child: CachedNetworkImage(
                        imageUrl: profile.photoUrls.first,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceLight,
                          child: const Icon(Icons.person, size: 80, color: AppColors.textHint),
                        ),
                      ),
                    ),
                  )
                else
                  AspectRatio(
                    aspectRatio: 0.75,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                      ),
                      child: const Center(
                        child: Icon(Icons.person, size: 80, color: AppColors.textHint),
                      ),
                    ),
                  ),
                const Gap(AppDimensions.spacing24),
                // Name + age
                Text(
                  profile.age != null
                      ? '${profile.displayName}, ${profile.age}'
                      : profile.displayName,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (profile.city != null) ...[
                  const Gap(AppDimensions.spacing4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 16),
                      const Gap(4),
                      Text(profile.city!, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                ],
                const Gap(AppDimensions.spacing16),
                // Bio
                if (profile.bio != null && profile.bio!.isNotEmpty)
                  Text(
                    profile.bio!,
                    style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
                  ),
                const Gap(AppDimensions.spacing16),
                // Modes
                if (profile.modes.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: profile.modes.map((mode) {
                      final color = AppColors.colorForMode(mode);
                      return Chip(
                        label: Text(mode, style: TextStyle(color: color, fontSize: 12)),
                        backgroundColor: color.withValues(alpha: 0.15),
                        side: BorderSide(color: color.withValues(alpha: 0.4)),
                      );
                    }).toList(),
                  ),
                const Gap(AppDimensions.spacing16),
                // Interests
                if (profile.interests.isNotEmpty) ...[
                  Text('Zainteresowania', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const Gap(8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.interests.map((i) => Chip(
                      label: Text(i, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textPrimary)),
                      backgroundColor: AppColors.surfaceLight,
                      side: const BorderSide(color: AppColors.divider),
                    )).toList(),
                  ),
                ],
                const Gap(AppDimensions.spacing48),
              ],
            ),
          );
        },
      ),
    );
  }
}
