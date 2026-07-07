class AppNotification {
  final int id;
  final String? title;
  final String? body;
  final String? type;
  final bool isRead;
  final String? createdAt;
  final Map<String, dynamic> data;

  AppNotification({
    required this.id,
    this.title,
    this.body,
    this.type,
    this.isRead = false,
    this.createdAt,
    this.data = const {},
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final isReadRaw = json['is_read'] ?? json['read_status'] ?? json['read'] ?? false;
    return AppNotification(
      id: (json['id'] is num) ? (json['id'] as num).toInt() : int.tryParse('${json['id']}') ?? 0,
      title: json['title'] as String?,
      body: (json['body'] ?? json['message'] ?? json['text']) as String?,
      type: json['type'] as String?,
      isRead: isReadRaw == true || isReadRaw == 1 || isReadRaw == '1',
      createdAt: json['created_at'] as String?,
      data: rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : const <String, dynamic>{},
    );
  }
}
