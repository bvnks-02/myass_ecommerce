import 'package:flutter/material.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../theme/app_theme.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../chat/domain/entities/chat_message.dart';
import '../../../chat/presentation/widgets/chat_composer.dart';
import '../../../chat/presentation/widgets/message_bubble.dart';

/// Admin view of a single customer conversation. Admin replies are aligned to
/// the right (mine == sent by the current admin).
class AdminChatThreadScreen extends StatefulWidget {
  const AdminChatThreadScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  final String conversationId;
  final String title;

  @override
  State<AdminChatThreadScreen> createState() => _AdminChatThreadScreenState();
}

class _AdminChatThreadScreenState extends State<AdminChatThreadScreen> {
  final ChatRepository _repo = ChatRepository();
  final ScrollController _scrollController = ScrollController();
  late final Stream<List<ChatMessage>> _stream;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _stream = _repo.conversationStream(widget.conversationId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo.markRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onMessages(int count) {
    if (count != _lastCount) {
      _lastCount = count;
      _repo.markRead(widget.conversationId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = _repo.currentUserId;
    return Scaffold(
      backgroundColor: AppTheme.blackColor,
      appBar: AppBar(
        backgroundColor: AppTheme.blackColor,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }
                final messages = snapshot.data ?? const [];
                _onMessages(messages.length);
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucun message pour le moment.',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.padding(context),
                    vertical: ResponsiveUtils.sh(context, 10),
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    return MessageBubble(message: m, mine: m.isMine(myId));
                  },
                );
              },
            ),
          ),
          ChatComposer(
            onSend: (content) => _repo.sendMessage(
              conversationId: widget.conversationId,
              content: content,
            ),
          ),
        ],
      ),
    );
  }
}
