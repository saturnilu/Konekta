import '../../core/api_client.dart';
import '../models/notification.dart';

class NotificationRepository {
  final ApiClient api;
  NotificationRepository(this.api);

  Future<List<AppNotification>> list() async {
    final data = await api.get('/notifications');
    final list = (data as List).cast<Map>();
    return list.map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> markRead(int id) async {
    await api.post('/notifications/$id/read', {});
  }

  Future<void> markAllRead() async {
    await api.post('/notifications/read-all', {});
  }
}
