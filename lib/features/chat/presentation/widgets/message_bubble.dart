import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/chat_message.dart';

/// A single chat bubble. `mine` controls alignment/colour; `showReadReceipt`
/// shows a single/double check on the current user's own outgoing messages.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
  });

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.createdAt);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.symmetric(vertical: ResponsiveUtils.sh(context, 4)),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.sw(context, 14),
          vertical: ResponsiveUtils.sh(context, 10),
        ),
        decoration: BoxDecoration(
          color: mine ? Colors.white : AppTheme.cardColorSecondary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: mine
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: mine ? Colors.black : Colors.white,
                fontSize: ResponsiveUtils.sf(context, 14),
                height: 1.3,
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 4)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: mine ? Colors.black54 : Colors.white38,
                    fontSize: ResponsiveUtils.sf(context, 10),
                  ),
                ),
                if (mine) ...[
                  SizedBox(width: ResponsiveUtils.sw(context, 4)),
                  Icon(
                    message.readAt != null ? Icons.done_all : Icons.done,
                    size: ResponsiveUtils.sf(context, 13),
                    color: message.readAt != null
                        ? Colors.blue
                        : Colors.black54,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
