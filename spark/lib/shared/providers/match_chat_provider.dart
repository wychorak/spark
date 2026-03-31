import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'supabase_provider.dart';

class MatchWithProfile {
  final String matchId;
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserPhotoUrl;
  final String otherUserMode;
  final DateTime matchedAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isNew;

  const MatchWithProfile({
    required this.matchId,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhotoUrl,
    required this.otherUserMode,
    required this.matchedAt,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    required this.isNew,
  });
}

class ChatMsg {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String messageType;
  final String? imagePath;
  final bool isRead;
  final DateTime createdAt;

  const ChatMsg({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.messageType,
    this.imagePath,
    required this.isRead,
    required this.createdAt,
  });
}

String _parseMode(dynamic rawModes) {
  List<String> modes = [];
  if (rawModes is List) {
    modes = rawModes.map((e) => e.toString()).toList();
  } else if (rawModes is String) {
    final cleaned = rawModes.replaceAll('{', '').replaceAll('}', '');
    modes = cleaned.split(',').where((s) => s.isNotEmpty).toList();
  }
  return modes.isNotEmpty ? modes.first : 'relationship';
}

final matchesWithProfileProvider =
    StreamProvider<List<MatchWithProfile>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final myId = user.id;
  final profileCache = <String, Map<String, dynamic>>{};

  return client
      .from('matches')
      .stream(primaryKey: ['id'])
      .order('matched_at')
      .asyncMap((matchRows) async {
    final activeMatches = matchRows
        .where((m) =>
            m['is_active'] == true &&
            (m['user1_id'] == myId || m['user2_id'] == myId))
        .toList();

    final results = <MatchWithProfile>[];

    for (final m in activeMatches) {
      final matchId = m['id'] as String;
      final otherUserId = m['user1_id'] == myId
          ? m['user2_id'] as String
          : m['user1_id'] as String;

      if (!profileCache.containsKey(otherUserId)) {
        final profile = await client
            .from('user_profiles')
            .select('id, display_name, modes, account_status')
            .eq('id', otherUserId)
            .maybeSingle();
        profileCache[otherUserId] = profile ?? {};
      }

      final profile = profileCache[otherUserId]!;
      if ((profile['account_status']?.toString() ?? 'active') != 'active') {
        continue;
      }

      final convRows = await client
          .from('conversations')
          .select()
          .eq('match_id', matchId)
          .limit(1);

      String conversationId = '';
      DateTime? lastMessageAt;

      if (convRows.isNotEmpty) {
        conversationId = convRows[0]['id'] as String;
        final lm = convRows[0]['last_message_at'];
        if (lm != null) lastMessageAt = DateTime.parse(lm as String);
      }

      String? lastMessage;
      int unreadCount = 0;
      bool isNew = true;

      if (conversationId.isNotEmpty) {
        final msgRows = await client
            .from('messages')
            .select()
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: false)
            .limit(1);

        if (msgRows.isNotEmpty) {
          isNew = false;
          lastMessage = msgRows[0]['content'] as String?;
        }

        final unreadRows = await client
            .from('messages')
            .select()
            .eq('conversation_id', conversationId)
            .neq('sender_id', myId)
            .eq('is_read', false);

        unreadCount = unreadRows.length;
      }

      String photoUrl = '';
      try {
        final photoRows = await client
            .from('user_photos')
            .select('storage_path')
            .eq('user_id', otherUserId)
            .order('position', ascending: true)
            .limit(1);
        if (photoRows.isNotEmpty) {
          final path = photoRows[0]['storage_path'] as String;
          photoUrl = path.startsWith('http')
              ? path
              : client.storage.from('photos').getPublicUrl(path);
        }
      } catch (_) {}

      results.add(MatchWithProfile(
        matchId: matchId,
        conversationId: conversationId,
        otherUserId: otherUserId,
        otherUserName: (profile['display_name'] as String?) ?? '',
        otherUserPhotoUrl: photoUrl,
        otherUserMode: _parseMode(profile['modes']),
        matchedAt: DateTime.parse(m['matched_at'] as String),
        lastMessage: lastMessage,
        lastMessageAt: lastMessageAt,
        unreadCount: unreadCount,
        isNew: isNew,
      ));
    }

    results.sort((a, b) {
      final aTime = a.lastMessageAt ?? a.matchedAt;
      final bTime = b.lastMessageAt ?? b.matchedAt;
      return bTime.compareTo(aTime);
    });

    return results;
  });
});

final chatMessagesProvider =
    StreamProvider.family<List<ChatMsg>, String>((ref, conversationId) {
  final client = ref.watch(supabaseClientProvider);

  return client
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', conversationId)
      .order('created_at')
      .map((rows) => rows
          .map((r) => ChatMsg(
                id: r['id'] as String,
                conversationId: r['conversation_id'] as String,
                senderId: r['sender_id'] as String,
                content: (r['content'] as String?) ?? '',
                messageType: (r['message_type'] as String?) ?? 'text',
                imagePath: r['image_path'] as String?,
                isRead: r['is_read'] as bool? ?? false,
                createdAt: DateTime.parse(r['created_at'] as String),
              ))
          .toList());
});

// Positional function: sendMessageProvider(conversationId, content)
final sendMessageProvider =
    Provider<Future<void> Function(String conversationId, String content)>(
        (ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);

  return (String conversationId, String content) async {
    if (user == null) return;

    await client.rpc(
      'fn_send_message',
      params: {
        'p_conversation_id': conversationId,
        'p_content': content,
        'p_message_type': 'text',
        'p_image_path': null,
      },
    );
  };
});

// markMessagesReadProvider(conversationId)
final markMessagesReadProvider =
    Provider<Future<void> Function(String conversationId)>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);

  return (String conversationId) async {
    if (user == null) return;
    await client
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', user.id)
        .eq('is_read', false);
  };
});

// blockUserProvider(matchId) — blocks the other user and deactivates match
// The chat screen passes conversationId, so we need to look up the match
final blockUserProvider =
    Provider<Future<void> Function(String conversationId)>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);

  return (String conversationId) async {
    if (user == null) return;

    // Find match via conversation
    final convRow = await client
        .from('conversations')
        .select('match_id')
        .eq('id', conversationId)
        .maybeSingle();

    if (convRow == null) return;
    final matchId = convRow['match_id'] as String;

    // Find other user from match
    final matchRow = await client
        .from('matches')
        .select('user1_id, user2_id')
        .eq('id', matchId)
        .maybeSingle();

    if (matchRow == null) return;
    final otherUserId = matchRow['user1_id'] == user.id
        ? matchRow['user2_id'] as String
        : matchRow['user1_id'] as String;

    await client.from('blocks').insert({
      'blocker_id': user.id,
      'blocked_id': otherUserId,
    });

    await client
        .from('matches')
        .update({'is_active': false})
        .eq('id', matchId);
  };
});

// reportUserProvider(conversationId, reason, description)
final reportUserProvider = Provider<
    Future<void> Function(
        String conversationId, String reason, String? description)>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);

  return (String conversationId, String reason, String? description) async {
    if (user == null) return;

    final convRow = await client
        .from('conversations')
        .select('match_id')
        .eq('id', conversationId)
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

    await client.rpc(
      'fn_submit_report',
      params: {
        'p_reported_id': otherUserId,
        'p_reason': reason,
        'p_description': description,
      },
    );
  };
});

// unmatchProvider(conversationId)
final unmatchProvider =
    Provider<Future<void> Function(String conversationId)>((ref) {
  final client = ref.watch(supabaseClientProvider);

  return (String conversationId) async {
    final convRow = await client
        .from('conversations')
        .select('match_id')
        .eq('id', conversationId)
        .maybeSingle();

    if (convRow == null) return;
    final matchId = convRow['match_id'] as String;

    await client
        .from('matches')
        .update({'is_active': false})
        .eq('id', matchId);
  };
});
