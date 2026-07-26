import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/chat_repository.dart';
import '../../domain/entities/chat_message.dart';

/// App-lifetime provider for the CUSTOMER side of the support chat.
/// Subscribes to the signed-in user's own conversation so the Messaging tab
/// can show a live unread badge. The chat screen itself renders from here too.
class ChatProvider extends ChangeNotifier {
  ChatProvider([ChatRepository? repository])
      : _repo = repository ?? ChatRepository() {
    _authSub =
        Supabase.instance.client.auth.onAuthStateChange.listen((_) => _bind());
    _bind();
  }

  final ChatRepository _repo;
  StreamSubscription<List<ChatMessage>>? _messagesSub;
  StreamSubscription<AuthState>? _authSub;

  String? _conversationId;
  List<ChatMessage> _messages = const [];

  List<ChatMessage> get messages => _messages;
  String? get conversationId => _conversationId;

  /// Number of unread messages sent by support (not by the current user).
  int get unreadCount {
    final uid = _repo.currentUserId;
    if (uid == null) return 0;
    return _messages
        .where((m) => m.senderId != uid && m.readAt == null)
        .length;
  }

  void _bind() {
    final uid = _repo.currentUserId;
    if (uid == null) {
      _messagesSub?.cancel();
      _messagesSub = null;
      _conversationId = null;
      _messages = const [];
      notifyListeners();
      return;
    }
    if (uid == _conversationId && _messagesSub != null) return;

    _conversationId = uid;
    _messagesSub?.cancel();
    _messagesSub = _repo.conversationStream(uid).listen((msgs) {
      _messages = msgs;
      notifyListeners();
    });
  }

  Future<bool> send(String content) async {
    final id = _conversationId;
    if (id == null) return false;
    return _repo.sendMessage(conversationId: id, content: content);
  }

  Future<void> markRead() async {
    final id = _conversationId;
    if (id != null) await _repo.markRead(id);
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
