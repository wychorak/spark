import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/core/theme/app_theme.dart';

// ─── Mock Data ──────────────────────────────────────────────

class MockMatch {
  final String id;
  final String name;
  final String photoUrl;
  final String mode;
  final bool isNew;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  const MockMatch({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.mode,
    this.isNew = false,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });
}

final List<MockMatch> _mockNewMatches = [
  const MockMatch(
    id: 'm1',
    name: 'Kasia',
    photoUrl: 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=200',
    mode: 'relationship',
    isNew: true,
  ),
  const MockMatch(
    id: 'm2',
    name: 'Maja',
    photoUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
    mode: 'friends',
    isNew: true,
  ),
  const MockMatch(
    id: 'm3',
    name: 'Zuza',
    photoUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
    mode: 'relationship',
    isNew: true,
  ),
];

final List<MockMatch> _mockConversations = [
  MockMatch(
    id: 'c1',
    name: 'Ola',
    photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    mode: 'fwb',
    lastMessage: 'Hej, co słychać? 😊',
    lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
    unreadCount: 2,
  ),
  MockMatch(
    id: 'c2',
    name: 'Ania',
    photoUrl: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=200',
    mode: 'friends',
    lastMessage: 'Jasne, spotkajmy się w sobotę!',
    lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
    unreadCount: 0,
  ),
  MockMatch(
    id: 'c3',
    name: 'Natalia',
    photoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
    mode: 'relationship',
    lastMessage: 'Ten film był świetny!',
    lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
    unreadCount: 0,
  ),
  MockMatch(
    id: 'c4',
    name: 'Weronika',
    photoUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
    mode: 'relationship',
    lastMessage: 'Dzięki za polecenie 🎵',
    lastMessageTime: DateTime.now().subtract(const Duration(days: 2)),
    unreadCount: 0,
  ),
];

// Blurred premium "who liked you"
final List<MockMatch> _mockLikedYou = [
  const MockMatch(
    id: 'p1',
    name: '???',
    photoUrl: 'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=200',
    mode: 'relationship',
  ),
  const MockMatch(
    id: 'p2',
    name: '???',
    photoUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
    mode: 'friends',
  ),
  const MockMatch(
    id: 'p3',
    name: '???',
    photoUrl: 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=200',
    mode: 'fwb',
  ),
];

// ─── Matches List Screen ────────────────────────────────────

class MatchesListScreen extends ConsumerWidget {
  const MatchesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMatches =
        _mockNewMatches.isNotEmpty || _mockConversations.isNotEmpty;

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
      body: hasMatches
          ? ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                // ── New matches horizontal scroll ──
                if (_mockNewMatches.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDimensions.screenPadding, 8, AppDimensions.screenPadding, 12),
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
                      itemCount: _mockNewMatches.length,
                      separatorBuilder: (_, __) => const Gap(14),
                      itemBuilder: (context, i) {
                        final match = _mockNewMatches[i];
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPadding, 0, AppDimensions.screenPadding, 12),
                  child: Text(
                    AppStrings.chatTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ..._mockConversations.asMap().entries.map((entry) {
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
            )
          : _buildEmptyState(),
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

  void _openChat(BuildContext context, MockMatch match) {
    // Navigate to chat screen
    // context.push('/chat/${match.id}');
    // For now, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Otwieranie czatu z ${match.name}...'),
        backgroundColor: AppColors.surfaceLight,
      ),
    );
  }
}

// ─── New Match Avatar ───────────────────────────────────────

class _NewMatchAvatar extends StatelessWidget {
  final MockMatch match;
  final VoidCallback onTap;

  const _NewMatchAvatar({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final modeColor = AppColors.colorForMode(match.mode);

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
                imageUrl: match.photoUrl,
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
            match.name,
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
      onTap: () {
        // Navigate to paywall
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Odblokuj Spark Premium!'),
            backgroundColor: AppColors.surfaceLight,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0A2E), Color(0xFF16082A)],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withValues(alpha: 0.1),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            // Blurred avatars
            SizedBox(
              width: 90,
              height: 50,
              child: Stack(
                children: _mockLikedYou.asMap().entries.map((entry) {
                  final i = entry.key;
                  final liked = entry.value;
                  return Positioned(
                    left: i * 22.0,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.5),
                            width: 1.5),
                      ),
                      child: ClipOval(
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            AppColors.overlay,
                            BlendMode.srcATop,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: liked.photoUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_rounded,
                          color: AppColors.warning, size: 16),
                      const Gap(4),
                      Text(
                        'Kto Cię polubił',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const Gap(2),
                  Text(
                    '${_mockLikedYou.length} osób czeka na Ciebie',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusRound),
              ),
              child: Text(
                'Premium',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
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
  final MockMatch match;
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
    final modeColor = AppColors.colorForMode(match.mode);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding,
          vertical: 10,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: modeColor.withValues(alpha: 0.4), width: 1.5),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: match.photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.surfaceLight,
                  ),
                ),
              ),
            ),
            const Gap(14),

            // Name + message preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.name,
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

            // Time + unread badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(match.lastMessageTime),
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
