import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/security/input_sanitizer.dart';
import '../../../core/utils/logger.dart';
import '../domain/entities/chat_message.dart';

/// Data access for the support chat, backed by the Supabase `messages` table.
/// Live updates use Supabase Realtime streams (no polling).
class ChatRepository {
  ChatRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _tag = 'ChatRepository';

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Realtime stream of a single conversation's messages, oldest first.
  Stream<List<ChatMessage>> conversationStream(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => rows.map(ChatMessage.fromMap).toList());
  }

  /// Realtime stream of every message (admin only, enforced by RLS), oldest
  /// first. Used to build the admin conversation list with live unread counts.
  Stream<List<ChatMessage>> allMessagesStream() {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((rows) => rows.map(ChatMessage.fromMap).toList());
  }

  /// Inserts a sanitized message. Returns false if the content was empty.
  Future<bool> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final uid = currentUserId;
    if (uid == null) return false;
    final clean = InputSanitizer.sanitizeString(content.trim(), maxLength: 4000);
    if (clean.isEmpty) return false;
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': uid,
      'content': clean,
    });
    return true;
  }

  /// Marks all inbound (not-sent-by-me) messages in a conversation as read,
  /// via the SECURITY DEFINER RPC. Best-effort — failures are logged only.
  Future<void> markRead(String conversationId) async {
    try {
      await _client.rpc('mark_messages_read',
          params: {'p_conversation': conversationId});
    } catch (e) {
      AppLogger.warning('markRead failed: $e', tag: _tag);
    }
  }

  /// Fetches display info (name/email/avatar) for a set of customer ids.
  /// Admin-only; relies on the "Admins can view all profiles" RLS policy.
  Future<Map<String, Map<String, dynamic>>> fetchProfiles(
      List<String> userIds) async {
    if (userIds.isEmpty) return {};
    try {
      final rows = await _client
          .from('user_profiles')
          .select('id, full_name, email, avatar_url')
          .inFilter('id', userIds);
      return {for (final r in rows as List) r['id'] as String: r};
    } catch (e) {
      AppLogger.warning('fetchProfiles failed: $e', tag: _tag);
      return {};
    }
  }
}
