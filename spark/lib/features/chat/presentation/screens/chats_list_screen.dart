import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/shared/providers/match_chat_provider.dart';

Color _modeColor(String mode) {
  switch (mode) {
    case 'friends':
      return AppColors.neonGreen;
    case 'fwb':
      return AppColors.neonOrange;
    default:
      return AppColors.neonPink;
  }
}

String _formatTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes} min';
  if (diff.inHours < 24) return '${diff.inHours} godz.';
  if (diff.inDays == 1) return 'wczoraj';
  return '${diff.inDays} dni';
}

class ChatsListScreen extends ConsumerStatefulWidget {
  const ChatsListScreen({super.key});

  @override
  ConsumerState<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends ConsumerState<ChatsListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchesWithProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: matchesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonPink),
          ),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const Gap(AppDimensions.spacing12),
                Text(
                  'Nie udało się załadować rozmów',
                  style: GoogleFonts.outfit(
                    color: AppColors.textHint,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          data: (allMatches) {
            final conversations = allMatches
                .where((m) => m.lastMessage != null)
                .toList()
              ..sort((a, b) {
                final aTime = a.lastMessageAt ?? a.matchedAt;
                final bTime = b.lastMessageAt ?? b.matchedAt;
                return bTime.compareTo(aTime);
              });

            final filtered = conversations
                .where((c) => c.otherUserName.toLowerCase().contains(_query))
                .toList();

            final totalUnread =
                conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding,
                    vertical: AppDimensions.paddingM,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Wiadomości',
                        style: GoogleFonts.orbitron(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (totalUnread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.neonPink,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.neonPinkGlow,
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            '$totalUnread',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding,
                  ),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusL),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Szukaj rozmów...',
                        hintStyle: GoogleFonts.outfit(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textHint,
                          size: 18,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                const Gap(AppDimensions.spacing12),

                // Conversation list
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                color: AppColors.textHint,
                                size: 48,
                              ),
                              const Gap(AppDimensions.spacing12),
                              Text(
                                'Brak rozmów',
                                style: GoogleFonts.outfit(
                                  color: AppColors.textHint,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final item = filtered[i];
                            return _ConvTile(
                              item: item,
                              index: i,
                              onTap: () => context.push(
                                '/chat/${item.conversationId}'
                                '?name=${Uri.encodeComponent(item.otherUserName)}'
                                '&photo=${Uri.encodeComponent(item.otherUserPhotoUrl)}'
                                '&mode=${item.otherUserMode}',
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConvTile extends StatelessWidget {
  const _ConvTile({
    required this.item,
    required this.index,
    required this.onTap,
  });

  final MatchWithProfile item;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mode = item.otherUserMode;
    final hasUnread = item.unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding,
          vertical: 4,
        ),
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: hasUnread
              ? AppColors.surface.withValues(alpha: 0.9)
              : AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: hasUnread
              ? Border.all(
                  color: _modeColor(mode).withValues(alpha: 0.3),
                )
              : null,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _modeColor(mode),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: item.otherUserPhotoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.surfaceLight,
                    child: const Icon(
                      Icons.person,
                      color: AppColors.textHint,
                      size: 28,
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceLight,
                    child: const Icon(
                      Icons.person,
                      color: AppColors.textHint,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            const Gap(AppDimensions.spacing12),
            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.otherUserName,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight:
                              hasUnread ? FontWeight.w700 : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (item.lastMessageAt != null)
                        Text(
                          _formatTime(item.lastMessageAt!),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: hasUnread
                                ? _modeColor(mode)
                                : AppColors.textHint,
                          ),
                        ),
                    ],
                  ),
                  const Gap(2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.lastMessage ?? '',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: hasUnread
                                ? AppColors.textSecondary
                                : AppColors.textHint,
                            fontWeight:
                                hasUnread ? FontWeight.w500 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const Gap(8),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _modeColor(mode),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    _modeColor(mode).withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${item.unreadCount}',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: 50 * index), duration: 300.ms)
        .slideX(
            begin: 0.05,
            end: 0,
            delay: Duration(milliseconds: 50 * index));
  }
}
