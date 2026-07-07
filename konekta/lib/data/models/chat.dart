class Conversation {
  final int id;
  final int? otherUserId;
  final String? otherUserName;
  final String? otherUserAvatarUrl;
  final String? lastMessage;
  final String? lastMessageAt;
  final int? unreadCount;

  Conversation({
    required this.id,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: (json['id'] ?? 0) as int,
      otherUserId: (json['other_user_id'] as num?)?.toInt(),
      otherUserName: (json['other_user_name'] ?? json['name'] ?? json['title']) as String?,
      otherUserAvatarUrl: (json['other_user_avatar_url'] ?? json['avatar_url']) as String?,
      lastMessage: (json['last_message'] ?? json['preview']) as String?,
      lastMessageAt: (json['last_message_at'] ?? json['updated_at']) as String?,
      unreadCount: (json['unread_count'] as num?)?.toInt(),
    );
  }
}

class ChatMessage {
  final int id;
  final int? senderId;
  final String? body;
  final String? createdAt;
  final bool isMine;

  ChatMessage({
    required this.id,
    this.senderId,
    this.body,
    this.createdAt,
    this.isMine = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final senderIdRaw = json['sender_id'] ?? json['sender_user_id'];
    return ChatMessage(
      id: (json['id'] is num) ? (json['id'] as num).toInt() : int.tryParse('${json['id']}') ?? 0,
      senderId: senderIdRaw is num ? senderIdRaw.toInt() : int.tryParse('$senderIdRaw'),
      body: (json['body'] ?? json['text'] ?? json['message'] ?? json['message_text']) as String?,
      createdAt: json['created_at'] as String?,
      isMine: (json['is_mine'] ?? false) == true,
    );
  }
}
