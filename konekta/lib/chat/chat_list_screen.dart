import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/app_scope.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/models/chat.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Conversation> _all = [];
  List<Conversation> _filtered = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final scope = AppScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await scope.chatRepo.listConversations();
      if (!mounted) return;
      setState(() {
        _all = list;
        _filtered = _filter(list, _query);
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
        _error = 'Failed to load conversations: $e';
        _loading = false;
      });
    }
  }

  List<Conversation> _filter(List<Conversation> source, String q) {
    if (q.isEmpty) return source;
    final lower = q.toLowerCase();
    return source.where((c) {
      final name = (c.otherUserName ?? '').toLowerCase();
      final msg = (c.lastMessage ?? '').toLowerCase();
      return name.contains(lower) || msg.contains(lower);
    }).toList();
  }

  void _onSearch(String q) {
    setState(() {
      _query = q;
      _filtered = _filter(_all, q);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KonektaColors.bg,
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: KonektaColors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Search chats…',
                  prefixIcon: const Icon(Icons.search_rounded, color: KonektaColors.textMuted, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    if (_filtered.isEmpty) {
      return _EmptyState(query: _query);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filtered.length,
        itemBuilder: (context, i) {
          final c = _filtered[i];
          return _ChatTile(
            name: c.otherUserName ?? 'Unknown',
            lastMsg: c.lastMessage ?? '',
            time: c.lastMessageAt ?? '',
            unread: c.unreadCount ?? 0,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatRoomScreen(
                    conversationId: c.id,
                    otherUserId: c.otherUserId,
                    otherUserName: c.otherUserName,
                  ),
                ),
              );
              if (!mounted) return;
              _load();
            },
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String name, lastMsg, time;
  final int unread;
  final VoidCallback onTap;

  const _ChatTile({
    required this.name,
    required this.lastMsg,
    required this.time,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              AvatarPlaceholder(text: name, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: KonektaColors.textDark,
                            ),
                          ),
                        ),
                        Text(
                          Format.timeAgo(time),
                          style: const TextStyle(fontSize: 11, color: KonektaColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lastMsg.isEmpty ? 'No messages yet' : lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: unread > 0 ? KonektaColors.textDark : KonektaColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (unread > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: KonektaColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unread.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.chat_bubble_outline_rounded, size: 64, color: KonektaColors.textMuted.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            query.isEmpty ? 'No conversations yet' : 'No chats match "$query"',
            style: const TextStyle(color: KonektaColors.textMuted, fontSize: 14, fontWeight: FontWeight.w600),
          ),
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