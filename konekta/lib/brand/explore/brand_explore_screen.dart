import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../notification/notifications_screen.dart';
import '../../brand/subscription/subscription_screen.dart';
import '../../chat/chat_list_screen.dart';
import 'brand_view_profile_screen.dart';

class BrandExploreScreen extends StatelessWidget {
  const BrandExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _listCtrl = ScrollController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _influencers = const [];
  String? _activeNiche;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  AppScope? _scope;
  bool _initialized = false;

  static const List<String> _niches = [
    'All',
    'Fashion',
    'Food',
    'Lifestyle',
    'Beauty',
    'Tech',
    'Travel',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = AppScope.of(context);
    if (!_initialized) {
      _initialized = true;
      _load(reset: true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    final scope = _scope;
    if (scope == null) return;
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
      });
    } else {
      if (!_hasMore || _loadingMore) return;
      setState(() => _loadingMore = true);
    }
    try {
      final q = _searchController.text.trim();
      final query = <String, dynamic>{
        'page': _page,
        'limit': 20,
      };
      if (q.isNotEmpty) query['q'] = q;
      if (_activeNiche != null && _activeNiche != 'All') query['niche'] = _activeNiche;
      final res = await scope.run(() => scope.api.get('/influencers', query: query));
      if (!mounted) return;
      final list = (res is List)
          ? res.whereType<Map>().map((e) => (e).cast<String, dynamic>()).toList()
          : (res is Map && (res['items'] is List))
              ? (res['items'] as List).whereType<Map>().map((e) => (e).cast<String, dynamic>()).toList()
              : <Map<String, dynamic>>[];
      setState(() {
        if (reset) {
          _influencers = list;
        } else {
          _influencers = [..._influencers, ...list];
        }
        _hasMore = list.length >= 20;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onNicheTap(String niche) {
    setState(() {
      _activeNiche = niche;
    });
    _load(reset: true);
  }

  void _onSearchSubmit(String _) {
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const SizedBox(width: 24, height: 24),
                  const SizedBox(width: 10),
                  const Text(
                    "Konekta",
                    style: TextStyle(
                      color: Color(0xFF69B9FF),
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                    icon: const Icon(Icons.notifications_none, color: Color(0xFF5D6B82)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _load(reset: true),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification && _listCtrl.hasClients) {
                      _listCtrl.jumpTo(_listCtrl.offset);
                    }
                    return false;
                  },
                  child: ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    controller: _listCtrl,
                    children: [
                      const SizedBox(height: 20),
                      // Premium Card
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                        ),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "PREMIUM TIER",
                                      style: TextStyle(
                                        color: Color(0xFF4A7DFF),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Konekta Pro",
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2A2A2A),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Stand out to brands & unlock\nunlimited campaigns.",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4D8DFF), Color(0xFF79D4FF)],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Text(
                                  "Upgrade",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Message Card
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ChatListScreen()),
                        ),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF63C5FF), Color(0xFF5D9FFF)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.message_outlined, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "Messages",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      "Check your latest chats",
                                      style: TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Niche filter chips
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _niches.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final n = _niches[i];
                            final active = (_activeNiche ?? 'All') == n;
                            return InkWell(
                              onTap: () => _onNicheTap(n),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: active
                                      ? const LinearGradient(colors: [Color(0xFF4D8DFF), Color(0xFF79D4FF)])
                                      : null,
                                  color: active ? null : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: active ? null : Border.all(color: const Color(0xFFE3E9F2)),
                                ),
                                child: Text(
                                  n,
                                  style: TextStyle(
                                    color: active ? Colors.white : const Color(0xFF5D6B82),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Search
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search, color: Colors.grey),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      onSubmitted: _onSearchSubmit,
                                      decoration: const InputDecoration(
                                        hintText: 'Search by name or keyword',
                                        border: InputBorder.none,
                                        isCollapsed: true,
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  if (_searchController.text.isNotEmpty)
                                    IconButton(
                                      splashRadius: 16,
                                      onPressed: () {
                                        _searchController.clear();
                                        _load(reset: true);
                                      },
                                      icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(Icons.tune, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_error != null)
                        _ErrorBlock(message: _error!, onRetry: () => _load(reset: true))
                      else if (_influencers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text('No influencers found', style: TextStyle(color: Colors.grey)),
                        )
                      else ...[
                        ..._influencers.map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _creatorCardFromApi(c),
                            )),
                        if (_hasMore)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: _loadingMore
                                ? const Center(child: CircularProgressIndicator())
                                : TextButton(
                                    onPressed: () {
                                      setState(() => _page += 1);
                                      _load(reset: false);
                                    },
                                    child: const Text('SHOW MORE'),
                                  ),
                          ),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _creatorCardFromApi(Map<String, dynamic> c) {
    final name = (c['name'] ?? c['display_name'] ?? 'Creator').toString();
    final username = c['username']?.toString();
    final niche = (c['niche'] ?? 'Creator').toString();
    final followers = c['followers_count'];
    final engagement = c['engagement_rate'];
    final avatarUrl = c['avatar_url']?.toString();
    final followersText = followers != null
        ? '${Format.compact(followers is num ? followers : num.tryParse(followers.toString()) ?? 0)} Followers'
        : 'Followers N/A';
    final engagementText = engagement != null
        ? '${(engagement is num ? engagement : num.tryParse(engagement.toString()) ?? 0).toStringAsFixed(1)}% Engagement'
        : 'Engagement N/A';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              _avatar(avatarUrl, name),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (username != null && username.isNotEmpty)
                  Text('@$username', style: const TextStyle(color: Color(0xFF5D6B82), fontSize: 12))
                else
                  Text(niche, style: const TextStyle(color: Color(0xFF4D8DFF), fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(
                  '$followersText • $engagementText',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BrandViewProfileScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF5F8FFF), Color(0xFF69C6FF)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "VIEW PROFILE",
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _avatar(String? url, String name) {
    if (url != null && url.isNotEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
        ),
      );
    }
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(color: Color(0xFFFFB8B8), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, color: Color(0xFF4A7DFF), size: 40),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
