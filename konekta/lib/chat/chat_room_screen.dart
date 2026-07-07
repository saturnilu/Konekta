import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/app_scope.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/models/chat.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, this.conversationId, this.otherUserId, this.otherUserName});
  final int? conversationId;
  final int? otherUserId;
  final String? otherUserName;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  int? _conversationId;
  String _displayName = '';
  final List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  bool get _hasConversation => _conversationId != null;

  @override
  void initState() {
    super.initState();
    _displayName = widget.otherUserName ?? 'Chat';
    _initConversation();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _initConversation() async {
    if (widget.conversationId != null) {
      _conversationId = widget.conversationId;
      await _loadMessages();
      return;
    }
    if (widget.otherUserId != null) {
      await _startConversation();
      return;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = 'No conversation selected';
    });
  }

  Future<void> _startConversation() async {
    final scope = AppScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = await scope.chatRepo.startConversation(widget.otherUserId!);
      if (!mounted) return;
      setState(() {
        _conversationId = c.id;
        _displayName = c.otherUserName ?? widget.otherUserName ?? 'Chat';
        _loading = false;
      });
      await _loadMessages();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to start conversation: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) return;
    final scope = AppScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await scope.chatRepo.getMessages(_conversationId!);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(list);
        _loading = false;
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load messages: $e';
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    if (_conversationId == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final scope = AppScope.of(context);
    setState(() => _sending = true);
    try {
      final msg = await scope.chatRepo.sendMessage(_conversationId!, text);
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
        _controller.clear();
        _sending = false;
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: KonektaColors.surface,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: KonektaColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _displayName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: KonektaColors.textDark),
            ),
            Text(
              _hasConversation ? 'Conversation' : 'Starting chat…',
              style: const TextStyle(fontSize: 11, color: Color(0xFF22C55E)),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_rounded, color: KonektaColors.primary), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert_rounded, color: KonektaColors.textSecondary), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFE8E8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFE5484D), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFB81F23), fontSize: 12),
                    ),
                  ),
                  TextButton(onPressed: _loadMessages, child: const Text('Retry')),
                ],
              ),
            ),
          Expanded(
            child: _loading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                color: KonektaColors.textMuted.withValues(alpha: 0.5), size: 64),
                            const SizedBox(height: 12),
                            const Text(
                              'No messages yet — say hi!',
                              style: TextStyle(color: KonektaColors.textMuted, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        child: ListView.builder(
                          controller: _scroll,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final m = _messages[i];
                            return _MessageBubble(
                              isOutgoing: m.isMine,
                              text: m.body ?? '',
                              time: Format.chatTime(m.createdAt),
                            );
                          },
                        ),
                      ),
          ),
          _ChatInputBar(controller: _controller, onSend: _send, sending: _sending, enabled: _hasConversation),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final bool isOutgoing;
  final String text;
  final String time;

  const _MessageBubble({required this.isOutgoing, required this.text, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isOutgoing ? const Color(0xFFEFF5FF) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isOutgoing ? 18 : 4),
                bottomRight: Radius.circular(isOutgoing ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: TextStyle(fontSize: 14, color: KonektaColors.textDark, height: 1.4)),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(time, style: const TextStyle(fontSize: 10, color: KonektaColors.textMuted)),
                ),
              ],
            ),
          ),
          if (isOutgoing) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;
  final bool enabled;

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.sending,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file_rounded, color: KonektaColors.textMuted),
              onPressed: enabled ? () {} : null,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: KonektaColors.bg, borderRadius: BorderRadius.circular(24)),
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF60A9FF), Color(0xFF246FE0)]),
                shape: BoxShape.circle,
                color: enabled ? null : KonektaColors.textMuted.withValues(alpha: 0.4),
              ),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: enabled ? onSend : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
