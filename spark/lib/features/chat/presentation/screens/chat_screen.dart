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
import 'package:spark/shared/providers/auth_provider.dart';
import 'package:spark/shared/providers/match_chat_provider.dart';

// ─── Chat Screen ────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String matchName;
  final String matchPhotoUrl;
  final String matchMode;

  const ChatScreen({
    super.key,
    required this.matchId,
    this.matchName = '',
    this.matchPhotoUrl = '',
    this.matchMode = 'relationship',
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _previousMessageCount = 0;

  String get _conversationId => widget.matchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(markMessagesReadProvider)(_conversationId);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    ref.read(sendMessageProvider)(_conversationId, text.trim());
    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showReportBlockMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
      ),
      builder: (ctx) {
        return SafeArea(
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
                const Gap(20),
                ListTile(
                  leading:
                      const Icon(Icons.flag_rounded, color: AppColors.warning),
                  title: Text(AppStrings.matchesReport,
                      style: GoogleFonts.outfit(color: AppColors.warning)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReportDialog();
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.block_rounded, color: AppColors.error),
                  title: Text('Zablokuj',
                      style: GoogleFonts.outfit(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showBlockConfirmation();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.heart_broken_rounded,
                      color: AppColors.textSecondary),
                  title: Text(AppStrings.matchesUnmatch,
                      style: GoogleFonts.outfit(
                          color: AppColors.textSecondary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showUnmatchConfirmation();
                  },
                ),
                const Gap(8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppStrings.cancel,
                      style:
                          GoogleFonts.outfit(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Zablokuj',
          style: GoogleFonts.outfit(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Czy na pewno chcesz zablokować tego użytkownika?',
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel,
                style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(blockUserProvider)(_conversationId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Użytkownik został zablokowany',
                        style: GoogleFonts.outfit()),
                    backgroundColor: AppColors.surface,
                  ),
                );
                context.pop();
              }
            },
            child: Text('Zablokuj',
                style: GoogleFonts.outfit(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final reasons = <String, String>{
      'spam': 'Spam',
      'harassment': 'Nękanie',
      'fake_profile': 'Fałszywy profil',
      'inappropriate': 'Nieodpowiednie treści',
      'other': 'Inne',
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Zgłoś użytkownika',
          style: GoogleFonts.outfit(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: reasons.entries.map((entry) {
            return ListTile(
              title: Text(entry.value,
                  style: GoogleFonts.outfit(color: AppColors.textPrimary)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(reportUserProvider)(
                  _conversationId,
                  entry.key,
                  null,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Dziękujemy za zgłoszenie',
                          style: GoogleFonts.outfit()),
                      backgroundColor: AppColors.surface,
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel,
                style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _showUnmatchConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          AppStrings.matchesUnmatch,
          style: GoogleFonts.outfit(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Czy na pewno chcesz usunąć tę parę?',
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel,
                style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(unmatchProvider)(_conversationId);
              if (mounted) {
                context.pop();
              }
            },
            child: Text(AppStrings.matchesUnmatch,
                style: GoogleFonts.outfit(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final messagesAsync = ref.watch(chatMessagesProvider(_conversationId));
    final modeColor = AppColors.colorForMode(widget.matchMode);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final currentUserId = currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: modeColor, width: 1.5),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: widget.matchPhotoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => CircleAvatar(
                    backgroundColor: modeColor,
                    child: Text(
                      widget.matchName.isNotEmpty
                          ? widget.matchName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.outfit(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      widget.matchName.isNotEmpty
                          ? widget.matchName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.outfit(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Gap(10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.matchName,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    const Gap(6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: modeColor,
                        boxShadow: [
                          BoxShadow(
                            color: modeColor.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  AppStrings.chatOnline,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textSecondary),
            onPressed: _showReportBlockMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Text(
                  AppStrings.errorGeneral,
                  style: GoogleFonts.outfit(color: AppColors.textSecondary),
                ),
              ),
              data: (messages) {
                if (messages.length != _previousMessageCount) {
                  _previousMessageCount = messages.length;
                  _scrollToBottom();
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      AppStrings.chatEmpty,
                      style:
                          GoogleFonts.outfit(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == currentUserId;

                    final showTimestamp = i == 0 ||
                        msg.createdAt
                                .difference(messages[i - 1].createdAt)
                                .inMinutes >
                            15;

                    return Column(
                      children: [
                        if (showTimestamp)
                          _TimestampLabel(time: msg.createdAt),
                        _MessageBubble(
                          content: msg.content,
                          isMe: isMe,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
                12, 8, 12, bottomPadding > 0 ? bottomPadding : 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.textHint, size: 24),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library_rounded,
                      color: AppColors.textHint, size: 24),
                  onPressed: () {},
                ),
                const Gap(4),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusRound),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextField(
                      controller: _textController,
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: AppStrings.chatMessageHint,
                        hintStyle: GoogleFonts.outfit(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                ),
                const Gap(8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: AppColors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message Bubble ─────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;

  const _MessageBubble({required this.content, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isMe ? AppColors.neonPinkGradient : null,
            color: isMe ? null : AppColors.surfaceLight,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: isMe
                ? [
                    BoxShadow(
                      color: AppColors.neonPinkGlow,
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Text(
            content,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.white,
              height: 1.4,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1);
  }
}

// ─── Timestamp Label ────────────────────────────────────────

class _TimestampLabel extends StatelessWidget {
  final DateTime time;

  const _TimestampLabel({required this.time});

  @override
  Widget build(BuildContext context) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          '$hour:$minute',
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: AppColors.textHint,
          ),
        ),
      ),
    );
  }
}
