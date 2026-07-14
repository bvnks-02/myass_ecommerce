import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../theme/app_theme.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../chat/domain/entities/chat_message.dart';
import 'admin_chat_thread_screen.dart';

/// Aggregated view of one conversation for the admin list.
class _ConversationSummary {
  final String conversationId;
  final String lastMessage;
  final DateTime lastAt;
  final int unread;
  _ConversationSummary({
    required this.conversationId,
    required this.lastMessage,
    required this.lastAt,
    required this.unread,
  });
}

/// Admin-only list of every customer conversation, with live unread badges.
/// Built by aggregating the realtime stream of all messages client-side.
class AdminConversationsScreen extends StatefulWidget {
  const AdminConversationsScreen({super.key});

  @override
  State<AdminConversationsScreen> createState() =>
      _AdminConversationsScreenState();
}

class _AdminConversationsScreenState extends State<AdminConversationsScreen> {
  final ChatRepository _repo = ChatRepository();
  late final Stream<List<ChatMessage>> _stream;
  final Map<String, Map<String, dynamic>> _profiles = {};

  @override
  void initState() {
    super.initState();
    _stream = _repo.allMessagesStream();
  }

  List<_ConversationSummary> _aggregate(List<ChatMessage> messages) {
    final byConversation = <String, List<ChatMessage>>{};
    for (final m in messages) {
      byConversation.putIfAbsent(m.conversationId, () => []).add(m);
    }
    final summaries = <_ConversationSummary>[];
    byConversation.forEach((id, msgs) {
      msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final last = msgs.last;
      // Unread for the admin = messages sent by the customer, still unread.
      final unread = msgs
          .where((m) => m.isFromCustomer && m.readAt == null)
          .length;
      summaries.add(_ConversationSummary(
        conversationId: id,
        lastMessage: last.content,
        lastAt: last.createdAt,
        unread: unread,
      ));
    });
    summaries.sort((a, b) => b.lastAt.compareTo(a.lastAt));
    return summaries;
  }

  Future<void> _ensureProfiles(List<String> ids) async {
    final missing = ids.where((id) => !_profiles.containsKey(id)).toList();
    if (missing.isEmpty) return;
    final fetched = await _repo.fetchProfiles(missing);
    if (!mounted) return;
    setState(() => _profiles.addAll(fetched));
  }

  String _displayName(String conversationId) {
    final p = _profiles[conversationId];
    final name = (p?['full_name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = (p?['email'] as String?)?.trim();
    if (email != null && email.isNotEmpty) return email;
    return 'Client ${conversationId.substring(0, 6)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackColor,
      appBar: AppBar(
        backgroundColor: AppTheme.blackColor,
        foregroundColor: Colors.white,
        title: const Text('Messagerie'),
      ),
      body: StreamBuilder<List<ChatMessage>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur de chargement des conversations.',
                  style: TextStyle(color: Colors.grey[500])),
            );
          }
          final summaries = _aggregate(snapshot.data ?? const []);
          if (summaries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined,
                      size: ResponsiveUtils.sf(context, 56),
                      color: Colors.white24),
                  SizedBox(height: ResponsiveUtils.sh(context, 12)),
                  Text('Aucune conversation pour le moment.',
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          // Resolve display names lazily.
          _ensureProfiles(summaries.map((s) => s.conversationId).toList());

          return ListView.separated(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.sh(context, 8),
            ),
            itemCount: summaries.length,
            separatorBuilder: (_, __) => Divider(
              color: Colors.white.withValues(alpha: 0.05),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final s = summaries[index];
              return _buildTile(context, s);
            },
          );
        },
      ),
    );
  }

  Widget _buildTile(BuildContext context, _ConversationSummary s) {
    final name = _displayName(s.conversationId);
    final time = DateFormat('dd/MM HH:mm').format(s.lastAt);
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminChatThreadScreen(
            conversationId: s.conversationId,
            title: name,
          ),
        ),
      ),
      leading: CircleAvatar(
        backgroundColor: AppTheme.cardColorSecondary,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        s.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[500]),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time,
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: ResponsiveUtils.sf(context, 11))),
          SizedBox(height: ResponsiveUtils.sh(context, 6)),
          if (s.unread > 0)
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.sw(context, 6)),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(
                minWidth: ResponsiveUtils.sw(context, 20),
                minHeight: ResponsiveUtils.sw(context, 20),
              ),
              child: Text(
                '${s.unread}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.sf(context, 11),
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
