import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_scope.dart';
import '../../core/theme.dart';
import '../../core/format.dart';
import '../../data/models/campaign.dart';
import '../../data/repositories/campaign_repository.dart';
import '../../campaign/campaign_detail_screen.dart';
import '../../notification/notifications_screen.dart';
import '../subscription/influencer_subscription_screen.dart';

class InfluencerExploreScreen extends StatefulWidget {
  const InfluencerExploreScreen({super.key});

  @override
  State<InfluencerExploreScreen> createState() => _InfluencerExploreScreenState();
}

class _InfluencerExploreScreenState extends State<InfluencerExploreScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _roomCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Campaign> _campaigns = const [];
  String _search = '';
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final scope = _scope;
    if (scope == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await scope.api.get(
        '/offers',
        query: {'role': 'influencer', 'page': 1, 'limit': 50},
        auth: false,
      );
      final list = (data as List)
          .whereType<Map>()
          .map((e) => Campaign.fromJson(e.cast<String, dynamic>()))
          .toList();
      if (!mounted) return;
      setState(() {
        _campaigns = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Campaign> get _filtered {
    if (_search.isEmpty) return _campaigns;
    final q = _search.toLowerCase();
    return _campaigns.where((c) {
      return c.title.toLowerCase().contains(q) ||
          (c.brandName ?? '').toLowerCase().contains(q);
    }).toList();
  }

  void _joinRoom() {
    final code = _roomCtrl.text.trim();
    if (code.isEmpty) return;
    // TODO: navigate to campaign room by room code
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joining room: $code')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFEDF4FC),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(16, topPad + 16, 16, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2FA2EE), Color(0xFF3B7CE5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hub_outlined, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Konekta',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProBannerCard(
                      onUpgrade: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const InfluencerSubscriptionScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Private room join
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PRIVATE ACCESS',
                            style: TextStyle(
                              color: KonektaColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _roomCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Enter Room Code',
                                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                    filled: true,
                                    fillColor: const Color(0xFFF3F7FF),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: _joinRoom,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF4A9FFF), Color(0xFF3581E1)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Join',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search bar
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (v) => setState(() => _search = v.trim()),
                              decoration: InputDecoration(
                                hintText: 'Search campaigns or brands',
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_search.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() => _search = '');
                              },
                              child: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'FEATURED PUBLIC CAMPAIGNS',
                          style: TextStyle(
                            color: KonektaColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (!_loading)
                          Text(
                            '${_filtered.length} OPEN',
                            style: const TextStyle(
                              color: KonektaColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // Campaign list
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF2FA2EE))),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ErrorBlock(message: _error!, onRetry: _load),
                ),
              )
            else if (_filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _EmptyBlock(query: _search),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _CampaignCard(
                        campaign: _filtered[i],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CampaignDetailScreen(campaign: _filtered[i]),
                          ),
                        ),
                      ),
                    ),
                    childCount: _filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onTap;
  const _CampaignCard({required this.campaign, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final c = campaign;
    final brand = c.brandName ?? 'Brand';
    final daysLeft = c.daysLeft;
    final daysText = daysLeft == null
        ? '— Days Left'
        : daysLeft > 0
            ? '$daysLeft Days Left'
            : daysLeft == 0
                ? 'Due today'
                : 'Closed';
    final budget = c.budget != null ? rupiah.format(c.budget) : '—';
    final applicants = c.applicantsCount ?? 0;
    final isFull = c.isFull;
    final slotsLeft = c.slotsLeft;

    return InkWell(
      onTap: isFull ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: isFull ? 0.65 : 1.0,
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _brandColor(brand),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    brand.isEmpty ? 'B' : brand[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: KonektaColors.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(brand, style: const TextStyle(fontSize: 12, color: KonektaColors.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(daysText, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                          const SizedBox(width: 12),
                          Icon(Icons.people_outline_rounded, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text('$applicants applicants', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status / full chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isFull
                        ? const Color(0xFFF1F5F9)
                        : c.isOpen
                            ? const Color(0xFFD6F8E8)
                            : const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isFull ? 'FULL' : c.isOpen ? 'OPEN' : 'ACTIVE',
                    style: TextStyle(
                      color: isFull
                          ? const Color(0xFF94A3B8)
                          : c.isOpen
                              ? const Color(0xFF00C853)
                              : const Color(0xFF3B82F6),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (c.description != null && c.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                c.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BUDGET', style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(budget, style: const TextStyle(color: Color(0xFF3AA1FF), fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
                // Slots info
                if (!isFull && slotsLeft != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_add_outlined, size: 11, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          '$slotsLeft slot${slotsLeft == 1 ? '' : 's'} left',
                          style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )
                else if (isFull)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block_rounded, size: 11, color: Color(0xFF94A3B8)),
                        SizedBox(width: 4),
                        Text('Campaign full', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  )
                else
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: KonektaColors.textMuted),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Color _brandColor(String name) {
    final colors = [
      const Color(0xFF6A534E),
      const Color(0xFF4A7DFF),
      const Color(0xFF2FA2EE),
      const Color(0xFF1FB76A),
      const Color(0xFFF6A623),
      const Color(0xFFE5484D),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}

class _ProBannerCard extends StatelessWidget {
  final VoidCallback onUpgrade;
  const _ProBannerCard({required this.onUpgrade});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2FA2EE), Color(0xFF408CFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PREMIUM TIER',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Konekta Pro', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  'Stand out to brands & unlock\nunlimited campaigns.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: ElevatedButton(
              onPressed: onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF408CFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 0,
              ),
              child: const Text('Upgrade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final String query;
  const _EmptyBlock({required this.query});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, color: Colors.grey.shade400, size: 40),
          const SizedBox(height: 12),
          Text(
            query.isEmpty ? 'No open campaigns right now' : 'No campaigns match "$query"',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF26264A)),
          ),
          const SizedBox(height: 4),
          Text(
            'Check back later or broaden your search.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBlock({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: Color(0xFFB0B8C4)),
          const SizedBox(height: 10),
          const Text('Could not load campaigns', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF7E8CA0))),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2FA2EE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }
}