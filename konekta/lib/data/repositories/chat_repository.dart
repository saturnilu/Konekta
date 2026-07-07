import '../../core/api_client.dart';
import '../models/chat.dart';

class ChatRepository {
  final ApiClient api;
  ChatRepository(this.api);

  Future<List<Conversation>> listConversations() async {
    final data = await api.get('/conversations');
    final list = (data as List).cast<Map>();
    return list.map((e) => Conversation.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<ChatMessage>> getMessages(int conversationId) async {
    final data = await api.get('/conversations/$conversationId/messages');
    final list = (data as List).cast<Map>();
    return list.map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<ChatMessage> sendMessage(int conversationId, String body) async {
    final data = await api.post('/conversations/$conversationId/messages', {'body': body});
    return ChatMessage.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Conversation> startConversation(int otherUserId) async {
    final data = await api.post('/conversations', {'other_user_id': otherUserId});
    return Conversation.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
