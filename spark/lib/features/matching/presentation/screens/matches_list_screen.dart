import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/core/theme/app_theme.dart';
import 'package:spark/shared/providers/match_chat_provider.dart';

// ─── Matches List Screen ────────────────────────────────────

class MatchesListScreen extends ConsumerWidget {
  const MatchesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesWithProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        centerTitle: true,
        title: Text(
          AppStrings.matchesTitle,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            shadows: AppTheme.neonTextShadow(
                blurRadius: AppDimensions.neonBlurSmall),
          ),
        ),
      ),
      body: matchesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 60, color: AppColors.error),
              const Gap(16),
              Text(
                'Coś poszło nie tak. Spróbuj ponownie.',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(16),
              TextButton(
                onPressed: () => ref.invalidate(matchesWithProfileProvider),
                child: Text(
                  'Odśwież',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        data: (matches) {
          final newMatches =
              matches.where((m) => m.isNew).toList();
          final conversations =
              matches.where((m) => !m.isNew).toList();

          // Sort conversations by last message time (most recent first)
          conversations.sort((a, b) {
            final aTime = a.lastMessageAt ?? a.matchedAt;
            final bTime = b.lastMessageAt ?? b.matchedAt;
            return bTime.compareTo(aTime);
          });

          final hasMatches =
              newMatches.isNotEmpty || conversations.isNotEmpty;

          if (!hasMatches) return _buildEmptyState();

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              // ── New matches horizontal scroll ──
              if (newMatches.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPadding,
                      8,
                      AppDimensions.screenPadding,
                      12),
                  child: Text(
                    'Nowe pary',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.screenPadding),
                    itemCount: newMatches.length,
                    separatorBuilder: (_, __) => const Gap(14),
                    itemBuilder: (context, i) {
                      final match = newMatches[i];
                      return _NewMatchAvatar(
                        match: match,
                        onTap: () => _openChat(context, match),
                      )
                          .animate()
                          .fadeIn(delay: (i * 100).ms, duration: 400.ms)
                          .slideX(begin: 0.2);
                    },
                  ),
                ),
                const Gap(16),
              ],

              // ── Premium banner: who liked you ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding),
                child: _PremiumLikedBanner(),
              ),
              const Gap(20),

              // ── Active conversations ──
              if (conversations.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPadding,
                      0,
                      AppDimensions.screenPadding,
                      12),
                  child: Text(
                    AppStrings.chatTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ...conversations.asMap().entries.map((entry) {
                  final i = entry.key;
                  final convo = entry.value;
                  return _ConversationTile(
                    match: convo,
                    onTap: () => _openChat(context, convo),
                  )
                      .animate()
                      .fadeIn(delay: (i * 80).ms, duration: 400.ms)
                      .slideX(begin: 0.05);
                }),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border_rounded,
              size: 80, color: AppColors.textHint),
          const Gap(16),
          Text(
            'Brak matchów – kontynuuj przeglądanie!',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  void _openChat(BuildContext context, MatchWithProfile match) {
    context.push(
      '/chat/${match.conversationId}'
      '?name=${Uri.encodeComponent(match.otherUserName)}'
      '&photo=${Uri.encodeComponent(match.otherUserPhotoUrl)}'
      '&mode=${match.otherUserMode}',
    );
  }
}

// ─── New Match Avatar ───────────────────────────────────────

class _NewMatchAvatar extends StatelessWidget {
  final MatchWithProfile match;
  final VoidCallback onTap;

  const _NewMatchAvatar({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final modeColor = AppColors.colorForMode(match.otherUserMode);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: modeColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: modeColor.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: match.otherUserPhotoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.surfaceLight,
                  child: const Icon(Icons.person,
                      color: AppColors.textHint, size: 28),
                ),
              ),
            ),
          ),
          const Gap(6),
          Text(
            match.otherUserName,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Premium Liked Banner ───────────────────────────────────

class _PremiumLikedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/paywall'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF5F7), Color(0xFFFFF0F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 26),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spark Premium',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    'Kto Cię polubił, cofanie, Super Like i więcej',
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
            const Gap(8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFFF8FAB)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Odblokuj',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

// ─── Conversation Tile ──────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final MatchWithProfile match;
  final VoidCallback onTap;

  const _ConversationTile({required this.match, required this.onTap});

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} godz.';
    if (diff.inDays < 7) return '${diff.inDays} dni';
    return '${time.day}.${time.month}';
  }

  @override
  Widget build(BuildContext context) {
    final modeColor = AppColors.colorForMode(match.otherUserMode);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding,
          vertical: 10,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: modeColor.withValues(alpha: 0.4), width: 1.5),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: match.otherUserPhotoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.surfaceLight,
                  ),
                ),
              ),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.otherUserName,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: match.unreadCount > 0
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (match.lastMessage != null) ...[
                    const Gap(2),
                    Text(
                      match.lastMessage!,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: match.unreadCount > 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: match.unreadCount > 0
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(match.lastMessageAt),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: match.unreadCount > 0
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                ),
                if (match.unreadCount > 0) ...[
                  const Gap(4),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Center(
                      child: Text(
                        '${match.unreadCount}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
