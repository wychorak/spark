import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../features/discovery/presentation/screens/home_screen.dart';

class SparkBottomNav extends ConsumerWidget {
  const SparkBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabProvider);

    return Container(
      height: AppDimensions.bottomNavHeight + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore,
              label: AppStrings.navDiscover,
              isActive: currentIndex == 0,
              onTap: () => ref.read(homeTabProvider.notifier).state = 0,
            ),
            _NavItem(
              icon: Icons.favorite_outline,
              activeIcon: Icons.favorite,
              label: AppStrings.navMatches,
              isActive: currentIndex == 1,
              onTap: () => ref.read(homeTabProvider.notifier).state = 1,
            ),
            _NavItem(
              icon: Icons.chat_bubble_outline,
              activeIcon: Icons.chat_bubble,
              label: AppStrings.navChat,
              isActive: currentIndex == 2,
              onTap: () => ref.read(homeTabProvider.notifier).state = 2,
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: AppStrings.navProfile,
              isActive: currentIndex == 3,
              onTap: () => ref.read(homeTabProvider.notifier).state = 3,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Neon active indicator bar
            AnimatedContainer(
              duration: const Duration(milliseconds: AppDimensions.animNormal),
              curve: Curves.easeInOut,
              width: isActive ? AppDimensions.bottomNavIndicatorWidth : 0,
              height: AppDimensions.bottomNavIndicatorHeight,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.transparent,
                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.neonPinkGlow,
                          blurRadius: AppDimensions.neonBlurSmall,
                          spreadRadius: AppDimensions.neonSpreadSmall,
                        ),
                      ]
                    : [],
              ),
            ),
            const SizedBox(height: AppDimensions.spacing6),
            // Icon with optional neon glow
            AnimatedContainer(
              duration: const Duration(milliseconds: AppDimensions.animNormal),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppColors.primary : AppColors.textHint,
                size: AppDimensions.iconM,
                shadows: isActive
                    ? [
                        Shadow(
                          color: AppColors.neonPinkGlow,
                          blurRadius: AppDimensions.neonBlurSmall,
                        ),
                      ]
                    : [],
              ),
            ),
            const SizedBox(height: AppDimensions.spacing2),
            // Label
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textHint,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
