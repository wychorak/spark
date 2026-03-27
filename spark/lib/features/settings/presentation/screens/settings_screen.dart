import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/core/router/app_router.dart';
import 'package:spark/shared/providers/auth_provider.dart';
import 'package:spark/shared/widgets/neon_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Toggle providers ──

final _biometricProvider = StateProvider.autoDispose<bool>((ref) => false);
final _notifyMatchesProvider = StateProvider.autoDispose<bool>((ref) => true);
final _notifyMessagesProvider = StateProvider.autoDispose<bool>((ref) => true);
final _notifySuperlikesProvider = StateProvider.autoDispose<bool>((ref) => true);
final _notifyMarketingProvider = StateProvider.autoDispose<bool>((ref) => false);
final _showDistanceProvider = StateProvider.autoDispose<bool>((ref) => true);
final _showActivityProvider = StateProvider.autoDispose<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userEmail = ref.watch(currentUserProvider)?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppStrings.settingsTitle,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(AppDimensions.spacing16),

            // ── Konto ──
            _SectionHeader(label: AppStrings.settingsAccount),
            const Gap(AppDimensions.spacing8),
            _SettingsCard(
              children: [
                _InfoTile(
                  icon: Icons.email_outlined,
                  title: AppStrings.email,
                  trailing: Text(
                    userEmail,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                const _NeonDivider(),
                _ActionTile(
                  icon: Icons.lock_outline,
                  title: 'Zmień hasło',
                  onTap: () => _handleChangePassword(context, userEmail),
                ),
                const _NeonDivider(),
                _ToggleTile(
                  icon: Icons.fingerprint,
                  title: 'Logowanie biometryczne',
                  provider: _biometricProvider,
                ),
              ],
            ),

            const Gap(AppDimensions.spacing24),

            // ── Powiadomienia ──
            _SectionHeader(label: AppStrings.settingsNotifications),
            const Gap(AppDimensions.spacing8),
            _SettingsCard(
              children: [
                _ToggleTile(
                  icon: Icons.favorite_outline,
                  title: 'Nowe pary',
                  provider: _notifyMatchesProvider,
                ),
                const _NeonDivider(),
                _ToggleTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'Wiadomości',
                  provider: _notifyMessagesProvider,
                ),
                const _NeonDivider(),
                _ToggleTile(
                  icon: Icons.star_outline,
                  title: 'Super Likes',
                  provider: _notifySuperlikesProvider,
                ),
                const _NeonDivider(),
                _ToggleTile(
                  icon: Icons.campaign_outlined,
                  title: 'Marketing',
                  provider: _notifyMarketingProvider,
                ),
              ],
            ),

            const Gap(AppDimensions.spacing24),

            // ── Prywatnosc ──
            _SectionHeader(label: AppStrings.settingsPrivacy),
            const Gap(AppDimensions.spacing8),
            _SettingsCard(
              children: [
                _ToggleTile(
                  icon: Icons.location_on_outlined,
                  title: 'Pokazuj odległość',
                  provider: _showDistanceProvider,
                ),
                const _NeonDivider(),
                _ToggleTile(
                  icon: Icons.visibility_outlined,
                  title: 'Pokazuj status aktywności',
                  provider: _showActivityProvider,
                ),
              ],
            ),

            const Gap(AppDimensions.spacing24),

            // ── Premium ──
            _SectionHeader(label: 'Premium'),
            const Gap(AppDimensions.spacing8),
            _SettingsCard(
              children: [
                _ActionTile(
                  icon: Icons.workspace_premium,
                  title: 'Przejdź na Premium',
                  titleColor: AppColors.neonPink,
                  iconColor: AppColors.neonPink,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                    ),
                    child: Text(
                      'PRO',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  onTap: () => context.pushNamed(RouteNames.paywall),
                ),
              ],
            ),

            const Gap(AppDimensions.spacing24),

            // ── Zablokowane ──
            _SectionHeader(label: AppStrings.settingsBlocked),
            const Gap(AppDimensions.spacing8),
            _SettingsCard(
              children: [
                _ActionTile(
                  icon: Icons.block,
                  title: 'Zablokowani użytkownicy',
                  trailing: Text(
                    '3',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textHint,
                    ),
                  ),
                  onTap: () {},
                ),
              ],
            ),

            const Gap(AppDimensions.spacing24),

            // ── Pomoc ──
            _SectionHeader(label: AppStrings.settingsHelp),
            const Gap(AppDimensions.spacing8),
            _SettingsCard(
              children: [
                _ActionTile(
                  icon: Icons.help_outline,
                  title: 'FAQ',
                  onTap: () {},
                ),
                const _NeonDivider(),
                _ActionTile(
                  icon: Icons.email_outlined,
                  title: 'Kontakt',
                  trailing: Text(
                    'sparksupportpolska@gmail.com',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                  ),
                  onTap: () {},
                ),
                const _NeonDivider(),
                _ActionTile(
                  icon: Icons.bug_report_outlined,
                  title: 'Zgłoś błąd',
                  onTap: () {},
                ),
              ],
            ),

            const Gap(AppDimensions.spacing24),

            // ── Prawne ──
            _SectionHeader(label: 'Prawne'),
            const Gap(AppDimensions.spacing8),
            _SettingsCard(
              children: [
                _ActionTile(
                  icon: Icons.description_outlined,
                  title: AppStrings.settingsTerms,
                  onTap: () {},
                ),
                const _NeonDivider(),
                _ActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: AppStrings.settingsPrivacyPolicy,
                  onTap: () {},
                ),
              ],
            ),

            const Gap(AppDimensions.spacing32),

            // ── Wyloguj ──
            SizedBox(
              width: double.infinity,
              child: NeonOutlinedButton(
                label: AppStrings.logout,
                icon: Icons.logout,
                color: AppColors.error,
                onPressed: () {
                  _showLogoutDialog(context, ref);
                },
              ),
            ),

            const Gap(AppDimensions.spacing16),

            // ── Usun konto ──
            Center(
              child: TextButton(
                onPressed: () => _showDeleteAccountDialog(context, ref),
                child: Text(
                  AppStrings.settingsDeleteAccount,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.error.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),

            const Gap(AppDimensions.spacing16),

            // ── Wersja ──
            Center(
              child: Text(
                '${AppStrings.settingsVersion} v1.0.0',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ),

            const Gap(AppDimensions.spacing48),
          ],
        ),
      ),
    );
  }

  Future<void> _handleChangePassword(BuildContext context, String email) async {
    if (email.isEmpty) return;
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Link do zmiany hasła został wysłany na $email',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nie udało się wysłać linku do zmiany hasła',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        title: Text(
          AppStrings.logout,
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Czy na pewno chcesz się wylogować?',
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.cancel,
              style: GoogleFonts.outfit(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authActionsProvider.notifier).signOut();
              if (context.mounted) {
                context.go(RoutePaths.splash);
              }
            },
            child: Text(
              AppStrings.logout,
              style: GoogleFonts.outfit(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        title: Text(
          AppStrings.settingsDeleteAccount,
          style: GoogleFonts.outfit(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          AppStrings.settingsDeleteAccountConfirm,
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.cancel,
              style: GoogleFonts.outfit(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.rpc('fn_delete_account');
                await ref.read(authActionsProvider.notifier).signOut();
                if (context.mounted) {
                  context.go(RoutePaths.splash);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Nie udało się usunąć konta. Spróbuj ponownie.',
                        style: GoogleFonts.outfit(),
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              AppStrings.delete,
              style: GoogleFonts.outfit(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ──

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.neonPink,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ── Settings Card ──

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: children,
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: AppDimensions.animNormal));
  }
}

// ── Neon Divider ──

class _NeonDivider extends StatelessWidget {
  const _NeonDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.transparent,
            AppColors.neonPink.withValues(alpha: 0.2),
            AppColors.transparent,
          ],
        ),
      ),
    );
  }
}

// ── Info Tile ──

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingM,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: AppDimensions.iconM),
          const Gap(AppDimensions.spacing12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Action Tile ──

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.titleColor,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? titleColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingM,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? AppColors.textSecondary,
              size: AppDimensions.iconM,
            ),
            const Gap(AppDimensions.spacing12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: titleColor ?? AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              const Gap(AppDimensions.spacing8),
            ],
            Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: AppDimensions.iconS,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Toggle Tile ──

class _ToggleTile extends ConsumerWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.provider,
  });

  final IconData icon;
  final String title;
  final StateProvider<bool> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: AppDimensions.iconM),
          const Gap(AppDimensions.spacing12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) => ref.read(provider.notifier).state = v,
          ),
        ],
      ),
    );
  }
}
