import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/core/router/app_router.dart';

// ─── Mock Data ───────────────────────────────────────────────

class _ConvItem {
  final String id;
  final String name;
  final String photoUrl;
  final String mode;
  final String lastMessage;
  final DateTime lastTime;
  final int unread;
  final bool isOnline;

  const _ConvItem({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.mode,
    required this.lastMessage,
    required this.lastTime,
    this.unread = 0,
    this.isOnline = false,
  });
}

final List<_ConvItem> _mockConvs = [
  _ConvItem(
    id: 'c1',
    name: 'Ola',
    photoUrl: 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=200',
    mode: 'relationship',
    lastMessage: 'Hej, co słychać? 😊',
    lastTime: DateTime.now().subtract(const Duration(minutes: 5)),
    unread: 2,
    isOnline: true,
  ),
  _ConvItem(
    id: 'c2',
    name: 'Ania',
    photoUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
    mode: 'friends',
    lastMessage: 'Jasne, spotkajmy się w sobotę!',
    lastTime: DateTime.now().subtract(const Duration(hours: 2)),
    unread: 0,
    isOnline: false,
  ),
  _ConvItem(
    id: 'c3',
    name: 'Natalia',
    photoUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
    mode: 'relationship',
    lastMessage: 'Ten film był świetny!',
    lastTime: DateTime.now().subtract(const Duration(days: 1)),
    unread: 0,
    isOnline: true,
  ),
  _ConvItem(
    id: 'c4',
    name: 'Weronika',
    photoUrl: 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=200',
    mode: 'fwb',
    lastMessage: 'Dzięki za polecenie 🎵',
    lastTime: DateTime.now().subtract(const Duration(days: 2)),
    unread: 0,
    isOnline: false,
  ),
  _ConvItem(
    id: 'c5',
    name: 'Kasia',
    photoUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
    mode: 'relationship',
    lastMessage: 'Super! To do zobaczenia 🙂',
    lastTime: DateTime.now().subtract(const Duration(days: 3)),
    unread: 0,
    isOnline: false,
  ),
];

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

// ─── Screen ──────────────────────────────────────────────────

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
    final filtered = _mockConvs
        .where((c) => c.name.toLowerCase().contains(_query))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
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
                  _totalUnread() > 0
                      ? Container(
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
                            '${_totalUnread()}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
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
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
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
                        return _ConvTile(
                          item: filtered[i],
                          index: i,
                          onTap: () => context.push(
                            '/chat/${filtered[i].id}',
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  int _totalUnread() =>
      _mockConvs.fold(0, (sum, c) => sum + c.unread);
}

class _ConvTile extends StatelessWidget {
  const _ConvTile({
    required this.item,
    required this.index,
    required this.onTap,
  });

  final _ConvItem item;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding,
          vertical: 4,
        ),
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: item.unread > 0
              ? AppColors.surface.withValues(alpha: 0.9)
              : AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: item.unread > 0
              ? Border.all(
                  color: _modeColor(item.mode).withValues(alpha: 0.3),
                )
              : null,
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _modeColor(item.mode),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: item.photoUrl,
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
                if (item.isOnline)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
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
                        item.name,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: item.unread > 0
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(item.lastTime),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: item.unread > 0
                              ? _modeColor(item.mode)
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
                          item.lastMessage,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: item.unread > 0
                                ? AppColors.textSecondary
                                : AppColors.textHint,
                            fontWeight: item.unread > 0
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.unread > 0) ...[
                        const Gap(8),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _modeColor(item.mode),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _modeColor(item.mode)
                                    .withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${item.unread}',
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
        .fadeIn(delay: Duration(milliseconds: 50 * index), duration: 300.ms)
        .slideX(begin: 0.05, end: 0, delay: Duration(milliseconds: 50 * index));
  }
}
