import 'dart:async';

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
import 'package:spark/shared/widgets/neon_text_field.dart';

// ─── Mock Data ──────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });
}

const String _myUserId = 'me';
const String _otherUserId = 'other';

final List<ChatMessage> _mockMessages = [
  ChatMessage(
    id: '1',
    senderId: _otherUserId,
    text: 'Hej! Widzę, że też lubisz podróże 🌍',
    createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
  ),
  ChatMessage(
    id: '2',
    senderId: _myUserId,
    text: 'Cześć! Tak, uwielbiam! Gdzie ostatnio byłaś?',
    createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 28)),
  ),
  ChatMessage(
    id: '3',
    senderId: _otherUserId,
    text: 'W Lizbonie! Było niesamowicie, muszę Ci opowiedzieć',
    createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 25)),
  ),
  ChatMessage(
    id: '4',
    senderId: _myUserId,
    text: 'O, Lizbona jest na mojej liście! Poleciłabyś jakieś miejsca?',
    createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
  ),
  ChatMessage(
    id: '5',
    senderId: _otherUserId,
    text: 'Zdecydowanie dzielnica Alfama i pastel de nata w Belém 🥐',
    createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
  ),
  ChatMessage(
    id: '6',
    senderId: _otherUserId,
    text: 'A Ty? Jakie masz plany podróżnicze?',
    createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 44)),
  ),
  ChatMessage(
    id: '7',
    senderId: _myUserId,
    text: 'Myślę o Japonii na wiosnę! 🌸 Czas na kwitnące wiśnie',
    createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
  ),
  ChatMessage(
    id: '8',
    senderId: _otherUserId,
    text: 'Marzenie! Może kiedyś razem? 😊',
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    isRead: false,
  ),
];

// ─── State ──────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final bool isLoading;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.isLoading = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    bool? isLoading,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  Timer? _typingTimer;

  @override
  ChatState build() {
    return ChatState(messages: _mockMessages);
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _myUserId,
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, msg]);

    // Simulate typing response
    state = state.copyWith(isTyping: true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      final reply = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        senderId: _otherUserId,
        text: _getAutoReply(),
        createdAt: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, reply],
        isTyping: false,
      );
    });
  }

  String _getAutoReply() {
    final replies = [
      'Super!',
      'Zgadzam sie!',
      'Opowiedz mi wiecej!',
      'To brzmi swietnie!',
      'Musze to sprawdzic!',
      'Haha, dokladnie tak!',
    ];
    return replies[state.messages.length % replies.length];
  }

  void markAsRead() {
    // In production: update via Supabase
  }
}

final chatProvider =
    NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);

// ─── Chat Screen ────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String matchName;
  final String matchPhotoUrl;
  final String matchMode;

  const ChatScreen({
    super.key,
    this.matchId = 'c1',
    this.matchName = 'Kasia',
    this.matchPhotoUrl =
        'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=200',
    this.matchMode = 'relationship',
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark messages as read
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).markAsRead();
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
    ref.read(chatProvider.notifier).sendMessage(text);
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
                  onTap: () => Navigator.pop(ctx),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.block_rounded, color: AppColors.error),
                  title: Text('Zablokuj',
                      style: GoogleFonts.outfit(color: AppColors.error)),
                  onTap: () => Navigator.pop(ctx),
                ),
                ListTile(
                  leading: const Icon(Icons.heart_broken_rounded,
                      color: AppColors.textSecondary),
                  title: Text(AppStrings.matchesUnmatch,
                      style: GoogleFonts.outfit(
                          color: AppColors.textSecondary)),
                  onTap: () => Navigator.pop(ctx),
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

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final modeColor = AppColors.colorForMode(widget.matchMode);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Auto-scroll when new messages arrive
    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (prev != null && next.messages.length > prev.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
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
                  chatState.isTyping
                      ? AppStrings.chatTyping
                      : AppStrings.chatOnline,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: chatState.isTyping
                        ? modeColor
                        : AppColors.textSecondary,
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
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding,
                vertical: 12,
              ),
              itemCount: chatState.messages.length +
                  (chatState.isTyping ? 1 : 0),
              itemBuilder: (context, i) {
                // Typing indicator
                if (i == chatState.messages.length && chatState.isTyping) {
                  return _TypingIndicator();
                }

                final msg = chatState.messages[i];
                final isMe = msg.senderId == _myUserId;

                // Group timestamps
                final showTimestamp = i == 0 ||
                    msg.createdAt
                            .difference(chatState.messages[i - 1].createdAt)
                            .inMinutes >
                        15;

                return Column(
                  children: [
                    if (showTimestamp) _TimestampLabel(time: msg.createdAt),
                    _MessageBubble(
                      message: msg,
                      isMe: isMe,
                    ),
                  ],
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
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

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
            message.text,
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

// ─── Typing Indicator ───────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.textHint,
                  shape: BoxShape.circle,
                ),
              )
                  .animate(
                    onPlay: (c) => c.repeat(),
                  )
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.4, 1.4),
                    duration: 600.ms,
                    delay: (i * 150).ms,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.4, 1.4),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                  ),
            );
          }),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
