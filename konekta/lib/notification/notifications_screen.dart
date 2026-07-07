import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/app_scope.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/models/notification.dart' as model;
import '../chat/chat_room_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<model.AppNotification> _items = [];
  bool _loading = true;
  bool _mutating = false;
  String? _error;
  AppScope? _scope;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = AppScope.of(context);
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  Future<void> _load() async {
    final scope = _scope ?? AppScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await scope.notificationRepo.list();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load notifications: $e';
        _loading = false;
      });
    }
  }

  Future<void> _markAll() async {
    final scope = _scope ?? AppScope.of(context);
    setState(() => _mutating = true);
    try {
      await scope.notificationRepo.markAllRead();
      if (!mounted) return;
      setState(() {
        _items = _items
            .map((n) => model.AppNotification(
                  id: n.id,
                  type: n.type,
                  title: n.title,
                  body: n.body,
                  isRead: true,
                  createdAt: n.createdAt,
                  data: n.data,
                ))
            .toList();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _onTapItem(model.AppNotification n) async {
    final scope = _scope ?? AppScope.of(context);
    if (n.isRead == false) {
      // Optimistic update
      setState(() {
        final idx = _items.indexWhere((x) => x.id == n.id);
        if (idx >= 0) {
          _items[idx] = model.AppNotification(
            id: n.id,
            type: n.type,
            title: n.title,
            body: n.body,
            isRead: true,
            createdAt: n.createdAt,
            data: n.data,
          );
        }
      });
      try {
        await scope.notificationRepo.markRead(n.id);
      } catch (_) {/* ignore — already optimistic */}
    }
    _navigate(n);
  }

  void _navigate(model.AppNotification n) {
    final data = n.data ?? const <String, dynamic>{};
    final conversationId = _tryInt(data['conversation_id']);
    final otherUserId = _tryInt(data['other_user_id'] ?? data['applicant_id'] ?? data['sender_id']);
    final otherUserName = (data['other_user_name'] ?? data['sender_name'])?.toString();

    if (conversationId != null || otherUserId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            conversationId: conversationId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
          ),
        ),
      );
      return;
    }
    // offer_id and applicant_id navigation would land on offer/applicant screens.
    // We just show a snackbar so the user gets feedback.
    final offerId = _tryInt(data['offer_id']);
    if (offerId != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open offer #$offerId')));
    }
  }

  int? _tryInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => n.isRead == false);
    return Scaffold(
      backgroundColor: KonektaColors.bg,
      appBar: AppBar(
        backgroundColor: KonektaColors.surface,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: KonektaColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: KonektaColors.textPrimary)),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _mutating ? null : _markAll,
              child: _mutating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Mark all read', style: TextStyle(color: KonektaColors.primary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    if (_items.isEmpty) {
      return const _EmptyState();
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final n = _items[i];
          return _NotificationTile(
            n: n,
            onTap: () => _onTapItem(n),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final model.AppNotification n;
  final VoidCallback onTap;
  const _NotificationTile({required this.n, required this.onTap});

  IconData _iconFor(String? type) {
    switch (type) {
      case 'offer':
      case 'offer_received':
        return Icons.local_offer_rounded;
      case 'application':
      case 'application_received':
        return Icons.assignment_rounded;
      case 'message':
      case 'new_message':
        return Icons.chat_bubble_rounded;
      case 'approval':
        return Icons.check_circle_rounded;
      case 'rejection':
        return Icons.cancel_rounded;
      case 'subscription':
      case 'plan':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String? type) {
    switch (type) {
      case 'offer':
      case 'offer_received':
        return const Color(0xFF7A5BFF);
      case 'application':
      case 'application_received':
        return const Color(0xFFF6A623);
      case 'message':
      case 'new_message':
        return const Color(0xFF4FB6FF);
      case 'approval':
        return const Color(0xFF1FB76A);
      case 'rejection':
        return const Color(0xFFE5484D);
      case 'subscription':
      case 'plan':
        return const Color(0xFF0E5FCB);
      default:
        return const Color(0xFF6B7791);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(n.type);
    final icon = _iconFor(n.type);
    final unread = n.isRead == false;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: unread
                ? Border.all(color: color.withValues(alpha: 0.3), width: 1.2)
                : Border.all(color: KonektaColors.border, width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title ?? 'Notification',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                              color: KonektaColors.textDark,
                            ),
                          ),
                        ),
                        Text(
                          Format.timeAgo(n.createdAt),
                          style: const TextStyle(fontSize: 10, color: KonektaColors.textMuted),
                        ),
                      ],
                    ),
                    if ((n.body ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        n.body!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: KonektaColors.textSecondary, height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Icon(Icons.notifications_off_rounded, size: 64, color: KonektaColors.textMuted.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        const Center(
          child: Text('No notifications yet',
              style: TextStyle(color: KonektaColors.textMuted, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: KonektaColors.danger, size: 48),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: KonektaColors.textSecondary)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
