import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../theme/app_theme.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_composer.dart';
import '../widgets/message_bubble.dart';

/// Tab 2 — the customer's support conversation with the Myazz team.
class CustomerChatScreen extends StatefulWidget {
  const CustomerChatScreen({super.key});

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final ScrollController _scrollController = ScrollController();
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().markRead();
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
      // New messages arrived — mark read and scroll to the bottom.
      context.read<ChatProvider>().markRead();
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
    final isAuthenticated =
        context.select<AuthProvider, bool>((a) => a.isAuthenticated);

    return Scaffold(
      backgroundColor: AppTheme.blackColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: isAuthenticated
                  ? _buildConversation(context)
                  : _buildSignedOut(context),
            ),
            if (isAuthenticated)
              ChatComposer(
                onSend: (content) => context.read<ChatProvider>().send(content),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
      child: Row(
        children: [
          Container(
            width: ResponsiveUtils.sw(context, 44),
            height: ResponsiveUtils.sw(context, 44),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(Icons.support_agent,
                color: Colors.white, size: ResponsiveUtils.sf(context, 24)),
          ),
          SizedBox(width: ResponsiveUtils.sw(context, 12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support Myazz',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveUtils.sf(context, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Nous répondons dès que possible',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: ResponsiveUtils.sf(context, 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConversation(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        final messages = chat.messages;
        _onMessages(messages.length);
        if (messages.isEmpty) {
          return _buildEmptyState(context);
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
            return MessageBubble(message: m, mine: m.isFromCustomer);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.sw(context, 32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined,
                size: ResponsiveUtils.sf(context, 56), color: Colors.white24),
            SizedBox(height: ResponsiveUtils.sh(context, 16)),
            Text(
              'Démarrez la conversation',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.sf(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 8)),
            Text(
              'Une question sur un produit ou une commande ? Écrivez-nous, l\'équipe Myazz vous répondra ici.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: ResponsiveUtils.sf(context, 14),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignedOut(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.sw(context, 32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline,
                size: ResponsiveUtils.sf(context, 56), color: Colors.white24),
            SizedBox(height: ResponsiveUtils.sh(context, 16)),
            Text(
              'Connectez-vous pour discuter',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.sf(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 8)),
            Text(
              'Vous devez être connecté pour contacter le support Myazz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: ResponsiveUtils.sf(context, 14),
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 20)),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.sw(context, 32),
                  vertical: ResponsiveUtils.sh(context, 12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}
