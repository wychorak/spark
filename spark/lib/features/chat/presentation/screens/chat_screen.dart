import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/core/constants/app_dimensions.dart';
import 'package:spark/core/constants/app_strings.dart';
import 'package:spark/shared/providers/auth_provider.dart';
import 'package:spark/shared/providers/match_chat_provider.dart';
import 'package:spark/shared/providers/supabase_provider.dart';

// ─── Chat Request Status ────────────────────────────────────
enum ChatRequestStatus { none, pending, accepted, rejected }

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
  ChatRequestStatus _chatRequestStatus = ChatRequestStatus.none;
  bool _isFirstMessage = true;
  bool _checkingRequest = true;

  String get _conversationId => widget.matchId;

  Color get _modeColor => AppColors.colorForMode(widget.matchMode);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(markMessagesReadProvider)(_conversationId);
      _checkChatRequest();
    });
  }

  Future<void> _checkChatRequest() async {
    try {
      final client = Supabase.instance.client;
      final user = ref.read(currentUserProvider);
      if (user == null) {
        setState(() => _checkingRequest = false);
        return;
      }

      // Check if there are any messages already
      final messages = await client
          .from('messages')
          .select('id')
          .eq('conversation_id', _conversationId)
          .limit(1);

      if (messages.isNotEmpty) {
        setState(() {
          _isFirstMessage = false;
          _chatRequestStatus = ChatRequestStatus.accepted;
          _checkingRequest = false;
        });
        return;
      }

      // Check chat_requests table
      final requests = await client
          .from('chat_requests')
          .select()
          .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
          .eq('conversation_id', _conversationId)
          .limit(1);

      if (requests.isNotEmpty) {
        final status = requests[0]['status'] as String? ?? 'pending';
        setState(() {
          _isFirstMessage = false;
          _chatRequestStatus = switch (status) {
            'accepted' => ChatRequestStatus.accepted,
            'rejected' => ChatRequestStatus.rejected,
            _ => ChatRequestStatus.pending,
          };
          _checkingRequest = false;
        });
      } else {
        setState(() {
          _isFirstMessage = true;
          _chatRequestStatus = ChatRequestStatus.none;
          _checkingRequest = false;
        });
      }
    } catch (_) {
      setState(() => _checkingRequest = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    if (_isFirstMessage && _chatRequestStatus == ChatRequestStatus.none) {
      // Send as chat request
      await _sendChatRequest(text.trim());
    } else if (_chatRequestStatus == ChatRequestStatus.accepted ||
        _chatRequestStatus == ChatRequestStatus.none) {
      ref.read(sendMessageProvider)(_conversationId, text.trim());
    }
    _textController.clear();
    _scrollToBottom();
  }

  Future<void> _sendChatRequest(String message) async {
    try {
      final client = Supabase.instance.client;
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      // Find the other user from the conversation
      final convRow = await client
          .from('conversations')
          .select('match_id')
          .eq('id', _conversationId)
          .maybeSingle();

      if (convRow == null) return;
      final matchId = convRow['match_id'] as String;

      final matchRow = await client
          .from('matches')
          .select('user1_id, user2_id')
          .eq('id', matchId)
          .maybeSingle();

      if (matchRow == null) return;
      final otherUserId = matchRow['user1_id'] == user.id
          ? matchRow['user2_id'] as String
          : matchRow['user1_id'] as String;

      await client.from('chat_requests').insert({
        'sender_id': user.id,
        'receiver_id': otherUserId,
        'conversation_id': _conversationId,
        'message': message,
        'status': 'pending',
      });

      setState(() {
        _chatRequestStatus = ChatRequestStatus.pending;
        _isFirstMessage = false;
      });
    } catch (_) {}
  }

  Future<void> _acceptChatRequest() async {
    try {
      final client = Supabase.instance.client;
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      await client
          .from('chat_requests')
          .update({'status': 'accepted'})
          .eq('conversation_id', _conversationId)
          .eq('receiver_id', user.id);

      // Get the original message and send it as a real message
      final requests = await client
          .from('chat_requests')
          .select()
          .eq('conversation_id', _conversationId)
          .eq('status', 'accepted')
          .limit(1);

      if (requests.isNotEmpty) {
        final senderId = requests[0]['sender_id'] as String;
        final message = requests[0]['message'] as String? ?? '';
        if (message.isNotEmpty) {
          await client.from('messages').insert({
            'conversation_id': _conversationId,
            'sender_id': senderId,
            'content': message,
            'message_type': 'text',
            'is_read': false,
          });
        }
      }

      setState(() {
        _chatRequestStatus = ChatRequestStatus.accepted;
      });
    } catch (_) {}
  }

  Future<void> _rejectChatRequest() async {
    try {
      final client = Supabase.instance.client;
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      await client
          .from('chat_requests')
          .update({'status': 'rejected'})
          .eq('conversation_id', _conversationId)
          .eq('receiver_id', user.id);

      setState(() {
        _chatRequestStatus = ChatRequestStatus.rejected;
      });
    } catch (_) {}
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
      backgroundColor: AppColors.white,
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
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        title: Text(
          'Zablokuj',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
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
                    backgroundColor: AppColors.primary,
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
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        title: Text(
          'Zgłoś użytkownika',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...reasons.entries.map((entry) {
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
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                },
              );
            }),
            const Gap(12),
            Text(
              'Kontakt: sparksupport@gmail.com',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ],
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
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        title: Text(
          AppStrings.matchesUnmatch,
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
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

  Widget _buildChatRequestBanner() {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    if (_chatRequestStatus == ChatRequestStatus.pending) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: _modeColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: _modeColor.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.pending_outlined, color: _modeColor, size: 32),
            const Gap(8),
            Text(
              'Oczekiwanie na akceptację',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Gap(4),
            Text(
              'Twoja wiadomość czeka na zatwierdzenie',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_chatRequestStatus == ChatRequestStatus.rejected) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.block, color: AppColors.error, size: 32),
            const Gap(8),
            Text(
              'Wiadomość odrzucona',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildIncomingRequestBanner() {
    return FutureBuilder(
      future: _checkIncomingRequest(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: _modeColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: _modeColor.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.mail_outline, color: _modeColor, size: 32),
              const Gap(8),
              Text(
                'Nowa prośba o rozmowę',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _acceptChatRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _modeColor,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusRound),
                      ),
                    ),
                    child: Text('Akceptuj',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  ),
                  const Gap(12),
                  OutlinedButton(
                    onPressed: _rejectChatRequest,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusRound),
                      ),
                    ),
                    child: Text('Odrzuć',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _checkIncomingRequest() async {
    try {
      final client = Supabase.instance.client;
      final user = ref.read(currentUserProvider);
      if (user == null) return false;

      final requests = await client
          .from('chat_requests')
          .select()
          .eq('conversation_id', _conversationId)
          .eq('receiver_id', user.id)
          .eq('status', 'pending')
          .limit(1);

      return requests.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final messagesAsync = ref.watch(chatMessagesProvider(_conversationId));
    final modeColor = _modeColor;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final currentUserId = currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
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
                    backgroundColor: modeColor.withValues(alpha: 0.2),
                    child: Text(
                      widget.matchName.isNotEmpty
                          ? widget.matchName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.outfit(
                        color: modeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => CircleAvatar(
                    backgroundColor: modeColor.withValues(alpha: 0.2),
                    child: Text(
                      widget.matchName.isNotEmpty
                          ? widget.matchName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.outfit(
                        color: modeColor,
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
                        color: AppColors.textPrimary,
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textSecondary),
            color: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            onSelected: (value) {
              switch (value) {
                case 'report':
                  _showReportDialog();
                  break;
                case 'block':
                  _showBlockConfirmation();
                  break;
                case 'unmatch':
                  _showUnmatchConfirmation();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded,
                        color: AppColors.warning, size: 20),
                    const Gap(8),
                    Text(AppStrings.matchesReport,
                        style: GoogleFonts.outfit(color: AppColors.warning)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    const Icon(Icons.block_rounded,
                        color: AppColors.error, size: 20),
                    const Gap(8),
                    Text('Zablokuj',
                        style: GoogleFonts.outfit(color: AppColors.error)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'unmatch',
                child: Row(
                  children: [
                    const Icon(Icons.heart_broken_rounded,
                        color: AppColors.textSecondary, size: 20),
                    const Gap(8),
                    Text(AppStrings.matchesUnmatch,
                        style: GoogleFonts.outfit(
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat request banners
          if (_checkingRequest)
            const SizedBox.shrink()
          else if (_chatRequestStatus == ChatRequestStatus.pending ||
              _chatRequestStatus == ChatRequestStatus.rejected)
            _buildChatRequestBanner()
          else
            _buildIncomingRequestBanner(),

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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            color: modeColor.withValues(alpha: 0.4), size: 48),
                        const Gap(12),
                        Text(
                          AppStrings.chatEmpty,
                          style: GoogleFonts.outfit(
                              color: AppColors.textSecondary),
                        ),
                        if (_isFirstMessage) ...[
                          const Gap(4),
                          Text(
                            'Wyślij pierwszą wiadomość!',
                            style: GoogleFonts.outfit(
                              color: AppColors.textHint,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
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
                          modeColor: modeColor,
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
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                top: BorderSide(
                    color: AppColors.divider.withValues(alpha: 0.5)),
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
                      color: AppColors.background,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusRound),
                      border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.5)),
                    ),
                    child: TextField(
                      controller: _textController,
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: _chatRequestStatus ==
                                ChatRequestStatus.pending
                            ? 'Oczekiwanie na akceptację...'
                            : AppStrings.chatMessageHint,
                        hintStyle: GoogleFonts.outfit(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      enabled: _chatRequestStatus !=
                              ChatRequestStatus.pending &&
                          _chatRequestStatus != ChatRequestStatus.rejected,
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                ),
                const Gap(8),
                GestureDetector(
                  onTap: (_chatRequestStatus != ChatRequestStatus.pending &&
                          _chatRequestStatus != ChatRequestStatus.rejected)
                      ? _sendMessage
                      : null,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: modeColor,
                      boxShadow: [
                        BoxShadow(
                          color: modeColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
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
  final Color modeColor;

  const _MessageBubble({
    required this.content,
    required this.isMe,
    required this.modeColor,
  });

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
            color: isMe ? modeColor : AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: isMe
                    ? modeColor.withValues(alpha: 0.2)
                    : AppColors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            content,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isMe ? AppColors.white : AppColors.textPrimary,
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            '$hour:$minute',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
        ),
      ),
    );
  }
}
