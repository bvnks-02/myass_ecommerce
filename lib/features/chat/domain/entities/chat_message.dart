/// A single support-chat message.
///
/// Conversation model: there is exactly one conversation per customer and
/// `conversationId` equals that customer's auth user id. Customer messages have
/// `senderId == conversationId`; admin replies have `senderId != conversationId`.
class ChatMessage {
  final int id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.readAt,
  });

  /// True when this message was sent by the customer who owns the conversation.
  bool get isFromCustomer => senderId == conversationId;

  bool isMine(String? userId) => userId != null && senderId == userId;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as int,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      content: map['content'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      readAt: map['read_at'] != null
          ? DateTime.parse(map['read_at'] as String).toLocal()
          : null,
    );
  }
}
