import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';

class SparkBottomNav extends StatelessWidget {
  const SparkBottomNav({super.key});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RoutePaths.matches)) return 1;
    if (location.startsWith(RoutePaths.chat)) return 2;
    if (location.startsWith(RoutePaths.profile)) return 3;
    return 0; // discovery
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.goNamed(RouteNames.discovery);
      case 1:
        context.goNamed(RouteNames.matches);
      case 2:
        context.goNamed(RouteNames.chat);
      case 3:
        context.goNamed(RouteNames.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

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
              onTap: () => _onTap(context, 0),
            ),
            _NavItem(
              icon: Icons.favorite_outline,
              activeIcon: Icons.favorite,
              label: AppStrings.navMatches,
              isActive: currentIndex == 1,
              onTap: () => _onTap(context, 1),
            ),
            _NavItem(
              icon: Icons.chat_bubble_outline,
              activeIcon: Icons.chat_bubble,
              label: AppStrings.navChat,
              isActive: currentIndex == 2,
              onTap: () => _onTap(context, 2),
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: AppStrings.navProfile,
              isActive: currentIndex == 3,
              onTap: () => _onTap(context, 3),
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
