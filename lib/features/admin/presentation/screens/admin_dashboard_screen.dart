// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../chat/domain/entities/chat_message.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackColor,
      appBar: AppBar(
        title: const Text('Tableau de bord',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAdminCard(
                context,
                title: 'Gérer les produits',
                icon: Icons.inventory_2_outlined,
                onTap: () => Navigator.pushNamed(context, '/admin/products'),
              ),
              const SizedBox(height: 20),
              _buildAdminCard(
                context,
                title: 'Gérer les commandes',
                icon: Icons.receipt_long_outlined,
                onTap: () => Navigator.pushNamed(context, '/admin/orders'),
              ),
              const SizedBox(height: 20),
              _buildMessagingCard(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Messaging card with a live unread badge (total unread customer messages).
  Widget _buildMessagingCard(BuildContext context) {
    return StreamBuilder<List<ChatMessage>>(
      stream: ChatRepository().allMessagesStream(),
      builder: (context, snapshot) {
        final unread = (snapshot.data ?? const [])
            .where((m) => m.isFromCustomer && m.readAt == null)
            .length;
        return _buildAdminCard(
          context,
          title: 'Messagerie',
          icon: Icons.forum_outlined,
          badge: unread,
          onTap: () => Navigator.pushNamed(context, '/admin/messages'),
        );
      },
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (badge > 0)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints:
                    const BoxConstraints(minWidth: 24, minHeight: 24),
                child: Text(
                  '$badge',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}
