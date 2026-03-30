import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/core/router/app_router.dart';
import 'package:spark/shared/providers/auth_provider.dart';
import 'package:spark/shared/widgets/neon_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Toggle providers ──

final _biometricProvider = StateProvider.autoDispose<bool>((ref) => false);
final _rememberDeviceProvider = StateProvider.autoDispose<bool>((ref) => false);
final _notifyMatchesProvider = StateProvider.autoDispose<bool>((ref) => true);
final _notifyMessagesProvider = StateProvider.autoDispose<bool>((ref) => true);
final _notifySuperlikesProvider = StateProvider.autoDispose<bool>((ref) => true);
final _notifyMarketingProvider = StateProvider.autoDispose<bool>((ref) => false);
final _showDistanceProvider = StateProvider.autoDispose<bool>((ref) => true);
final _showActivityProvider = StateProvider.autoDispose<bool>((ref) => true);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isPremium = false;
  int _blockedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRememberDevice();
    _loadBlockedCount();
  }

  Future<void> _loadRememberDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('remember_device') ?? false;
    if (mounted) {
      ref.read(_rememberDeviceProvider.notifier).state = value;
    }
  }

  Future<void> _saveRememberDevice(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_device', value);
  }

  Future<void> _loadBlockedCount() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;
      final rows = await client
          .from('blocks')
          .select('id')
          .eq('blocker_id', user.id);
      if (mounted) {
        setState(() => _blockedCount = rows.length);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = ref.watch(currentUserProvider)?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
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
                const _SoftDivider(),
                _ActionTile(
                  icon: Icons.lock_outline,
                  title: 'Zmień hasło',
                  onTap: () => _handleChangePassword(context, userEmail),
                ),
                const _SoftDivider(),
                _ToggleTile(
                  icon: Icons.fingerprint,
                  title: 'Logowanie biometryczne',
                  provider: _biometricProvider,
                ),
                const _SoftDivider(),
                _ToggleTile(
                  icon: Icons.devices,
                  title: 'Zapamiętaj urządzenie',
                  provider: _rememberDeviceProvider,
                  onChanged: (value) => _saveRememberDevice(value),
                ),
              ],
            ),

            const Gap(AppDimensions.spacing24),

            // ── Tryb premium ──
            _SectionHeader(label: 'Tryb premium'),
            const Gap(AppDimensions.spacing8),
            _SettingsCard(
              children: [
                _ActionTile(
                  icon: Icons.workspace_premium,
                  title: _isPremium ? 'Spark Premium' : 'Przejdź na Premium',
                  titleColor: AppColors.primary,
                  iconColor: AppColors.primary,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isPremium
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                    ),
                    child: Text(
                      _isPremium ? 'AKTYWNY' : 'PRO',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _isPremium ? AppColors.primary : AppColors.white,
                      ),
                    ),
                  ),
                  onTap: () => context.pushNamed(RouteNames.paywall),
                ),
                if (_isPremium) ...[
                  const _SoftDivider(),
                  _InfoTile(
                    icon: Icons.calendar_today_outlined,
                    title: 'Plan',
                    trailing: Text(
                      'Miesięczny',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ],
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
                const _SoftDivider(),
                _ToggleTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'Wiadomości',
                  provider: _notifyMessagesProvider,
                ),
                const _SoftDivider(),
                _ToggleTile(
                  icon: Icons.star_outline,
                  title: 'Super Likes',
                  provider: _notifySuperlikesProvider,
                ),
                const _SoftDivider(),
                _ToggleTile(
                  icon: Icons.campaign_outlined,
                  title: 'Marketing',
                  provider: _notifyMarketingProvider,
                ),
              ],
            ),

            const Gap(AppDimensions.spacing24),

            // ── Prywatność ──
            _SectionHeader(label: AppStrings.settingsPrivacy),
            const Gap(AppDimensions.spacing8),
            _SettingsCard(
              children: [
                _ToggleTile(
                  icon: Icons.location_on_outlined,
                  title: 'Pokazuj odległość',
                  provider: _showDistanceProvider,
                ),
                const _SoftDivider(),
                _ToggleTile(
                  icon: Icons.visibility_outlined,
                  title: 'Pokazuj status aktywności',
                  provider: _showActivityProvider,
                ),
              ],
            ),

            const Gap(AppDimensions.spacing24),

            // ── Zablokowani ──
            _SectionHeader(label: AppStrings.settingsBlocked),
            const Gap(AppDimensions.spacing8),
            _SettingsCard(
              children: [
                _ActionTile(
                  icon: Icons.block,
                  title: 'Zablokowani użytkownicy',
                  trailing: Text(
                    '$_blockedCount',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textHint,
                    ),
                  ),
                  onTap: () {
                    _showBlockedUsers(context);
                  },
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
                const _SoftDivider(),
                _ActionTile(
                  icon: Icons.email_outlined,
                  title: 'Kontakt',
                  trailing: Text(
                    'sparksupport@gmail.com',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                  ),
                  onTap: () {},
                ),
                const _SoftDivider(),
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
                  onTap: () => launchUrl(
                    Uri.parse('https://wychorak.github.io/spark/terms.html'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const _SoftDivider(),
                _ActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: AppStrings.settingsPrivacyPolicy,
                  onTap: () => launchUrl(
                    Uri.parse('https://wychorak.github.io/spark/privacy-policy.html'),
                    mode: LaunchMode.externalApplication,
                  ),
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

            // ── Wersja aplikacji ──
            Center(
              child: Text(
                'Wersja aplikacji v1.0.0',
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

  void _showBlockedUsers(BuildContext context) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final blocks = await client
          .from('blocks')
          .select('blocked_id')
          .eq('blocker_id', user.id);

      final blockedIds =
          blocks.map((b) => b['blocked_id'] as String).toList();

      if (blockedIds.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Brak zablokowanych użytkowników',
                  style: GoogleFonts.outfit()),
              backgroundColor: AppColors.primary,
            ),
          );
        }
        return;
      }

      final profiles = await client
          .from('user_profiles')
          .select('id, display_name')
          .inFilter('id', blockedIds);

      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
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
                const Gap(16),
                Text(
                  'Zablokowani użytkownicy',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Gap(16),
                ...profiles.map((p) {
                  final name = p['display_name'] as String? ?? 'Nieznany';
                  final id = p['id'] as String;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(name[0].toUpperCase(),
                          style: GoogleFonts.outfit(color: AppColors.primary)),
                    ),
                    title: Text(name,
                        style: GoogleFonts.outfit(color: AppColors.textPrimary)),
                    trailing: TextButton(
                      onPressed: () async {
                        await client
                            .from('blocks')
                            .delete()
                            .eq('blocker_id', user.id)
                            .eq('blocked_id', id);
                        Navigator.pop(ctx);
                        _loadBlockedCount();
                      },
                      child: Text('Odblokuj',
                          style: GoogleFonts.outfit(
                              color: AppColors.primary, fontSize: 13)),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    } catch (_) {}
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
            backgroundColor: AppColors.primary,
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
        backgroundColor: AppColors.white,
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
        backgroundColor: AppColors.white,
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
        color: AppColors.primary,
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: AppDimensions.animNormal));
  }
}

// ── Soft Divider ──

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      color: AppColors.divider.withValues(alpha: 0.4),
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
    this.onChanged,
  });

  final IconData icon;
  final String title;
  final StateProvider<bool> provider;
  final ValueChanged<bool>? onChanged;

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
            activeColor: AppColors.primary,
            onChanged: (v) {
              ref.read(provider.notifier).state = v;
              onChanged?.call(v);
            },
          ),
        ],
      ),
    );
  }
}
