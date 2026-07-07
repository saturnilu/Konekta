import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../notification/notifications_screen.dart';
import '../../data/models/campaign.dart';
import 'brand_active_room_screen.dart';
import 'brand_completed_campaigns_screen.dart';
import 'brand_pending_approvals_screen.dart';
import 'new_campaign_screen.dart';

class BrandDashboardScreen extends StatefulWidget {
  const BrandDashboardScreen({super.key});

  @override
  State<BrandDashboardScreen> createState() => _BrandDashboardScreenState();
}

class _BrandDashboardScreenState extends State<BrandDashboardScreen> {
  static const Color backgroundColor = Color(0xFFEDF4FC);
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color darkText = Color(0xFF1E293B);
  static const Color subText = Color(0xFF64748B);

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _rooms = const [];
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
    final scope = _scope;
    if (scope == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await scope.run(() async {
        final summary = await scope.api.get('/dashboard/brand');
        final offers = await scope.api.get('/offers/mine');
        return {
          'summary': summary,
          'rooms': offers,
        };
      });
      if (!mounted) return;
      final summary = (results['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
      final summaryInner = (summary['summary'] as Map?)?.cast<String, dynamic>() ?? summary;
      final rooms = (results['rooms'] as List?) ?? const [];
      setState(() {
        _summary = summaryInner;
        _rooms = rooms
            .whereType<Map>()
            .map((e) => (e).cast<String, dynamic>())
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _scope?.session ?? AppScope.of(context).session;
    final firstName = (session.name ?? '').isNotEmpty ? session.name!.split(' ').first : 'there';
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110, top: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER SECTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.hub_outlined, color: primaryBlue, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Konekta',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: primaryBlue.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        ),
                        icon: Icon(Icons.notifications_none_outlined, color: darkText, size: 26),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // --- SALUTATION ---
                  Text(
                    'Hi, $firstName',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ready to expand your reach?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: subText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _ErrorBlock(message: _error!, onRetry: _load)
                  else ...[
                    // --- MAIN PERFORMANCE CARD (AUDIENCE REACHED) ---
                    _buildAudienceCard(),
                    const SizedBox(height: 16),

                    // --- GRID STATS (ENGAGEMENT & INTERACTIONS) ---
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallStatCard(
                            title: _formatPercent(_summary?['engagement_rate']),
                            subtitle: 'AVG. ENGAGEMENT',
                            icon: Icons.trending_up,
                            iconColor: Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSmallStatCard(
                            title: _formatCompact(_summary?['total_interactions']),
                            subtitle: 'TOTAL INTERACTIONS',
                            icon: Icons.favorite_border,
                            iconColor: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 19),

                    // --- BUTTON: CREATE NEW ROOM ---
                    Container(
                      width: double.infinity,
                      height: 65,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NewCampaignScreen()),
                          );
                          _load();
                        },
                        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
                        label: Text(
                          'Create New Room',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- SECTION: ACTION NEED ---
                    Text(
                      'Action Need',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      icon: Icons.star,
                      iconBgColor: const Color(0xFFDBEAFE),
                      iconColor: primaryBlue,
                      title: 'Completed campaigns',
                      subtitle: '${_summary?['completed_campaigns'] ?? 0} successful collaborations',
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BrandCompletedCampaignsScreen()),
                        );
                        _load();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      icon: Icons.assignment_turned_in_outlined,
                      iconBgColor: const Color(0xFFDBEAFE),
                      iconColor: primaryBlue,
                      title: 'Pending Approvals',
                      subtitle: '${_summary?['pending_approvals'] ?? 0} awaiting your review',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BrandPendingApprovalsScreen()),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // --- SECTION: ACTIVE ROOMS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active Rooms',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const _AllCampaignsScreen()),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                'View All',
                                style: GoogleFonts.plusJakartaSans(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward, size: 12, color: primaryBlue),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    if (_rooms.isEmpty)
                      _EmptyRooms(onCreate: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const NewCampaignScreen()),
                            );
                            _load();
                          })
                    else
                      ..._rooms.take(3).map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildRoomCardFromApi(r),
                          )),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCompact(dynamic value) {
    if (value == null) return '0';
    final n = value is num ? value : num.tryParse(value.toString()) ?? 0;
    return Format.compact(n);
  }

  String _formatPercent(dynamic value) {
    if (value == null) return '0%';
    final n = value is num ? value : num.tryParse(value.toString()) ?? 0;
    return '${n.toStringAsFixed(1)}%';
  }

  Widget _buildAudienceCard() {
    final views = _summary?['this_week_views'];
    final viewsNum = views is num ? views : num.tryParse(views?.toString() ?? '') ?? 0;
    final growthRaw = _summary?['week_growth_pct'];
    final growth = growthRaw is num ? growthRaw.toDouble() : double.tryParse(growthRaw?.toString() ?? '') ?? 0.0;
    final isPositive = growth >= 0;
    final growthText = '${isPositive ? '+' : ''}${growth.toStringAsFixed(1)}% from last week';

    // Format with dots: 1.250.400
    final formatted = NumberFormat('#,###', 'id_ID').format(viewsNum);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFD6E6FE), Color(0xFF93C5FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "THIS WEEK'S AUDIENCE REACHED",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E1B4B).withValues(alpha: 0.6),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E1B4B),
              ),
              children: [
                TextSpan(text: formatted),
                const TextSpan(text: ' Views'),
              ],
            ),
          ),
          const Divider(height: 24, color: Color(0xFFBFD7F5)),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                growthText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Combined performance across all active creators.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF1E1B4B).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk Stat Kecil (Engagement & Interaction)
  Widget _buildSmallStatCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color.fromARGB(255, 71, 67, 67),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk Action Need List Item
  Widget _buildActionCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color.fromARGB(255, 71, 67, 67),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: const Color.fromARGB(255, 71, 67, 67)),
        ],
      ),
    ),
    );
  }

  // Widget untuk Active Room from API data
  Widget _buildRoomCardFromApi(Map<String, dynamic> room) {
    final id = room['id'];
    final title = (room['title'] ?? 'Untitled').toString();
    final daysLeft = room['days_left'];

    // Progress = completed (paid) / total active (approved + completed)
    final activeCount   = _tryInt(room['active_count'])    ?? 0;
    final completedCount = _tryInt(room['completed_count']) ?? 0;
    final progressClamped = activeCount > 0
        ? (completedCount / activeCount).clamp(0.0, 1.0)
        : 0.0;
    final progressPct = (progressClamped * 100).round();

    final isComplete = room['status'] == 'completed';
    final statusText = isComplete ? 'COMPLETE' : 'IN PROGRESS';
    final statusColor = isComplete ? const Color(0xFF059669) : const Color(0xFF3B82F6);
    final statusBg = isComplete ? const Color(0xFFD1FAE5) : const Color(0xFFDBEAFE);
    final daysLeftText = daysLeft == null
        ? 'No deadline'
        : (daysLeft is num ? '$daysLeft Days Left' : daysLeft.toString());

    final goalText = activeCount > 0
        ? '$completedCount / $activeCount influencers completed'
        : '${_tryInt(room['applicants_count']) ?? 0} applicants';

    return InkWell(
      onTap: () {
        final campaign = Campaign(
          id: _tryInt(id) ?? 0,
          brandUserId: 0,
          title: title,
          status: room['status'] as String? ?? 'open',
          budget: room['budget'] is num ? room['budget'] as num : null,
          endDate: room['deadline'] as String?,
          applicantsCount: _tryInt(room['applicants_count']),
          isCompleted: isComplete,
        );
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BrandActiveRoomScreen(campaign: campaign)),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _avatarColor(id),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: const Color.fromARGB(255, 71, 67, 67)),
                          const SizedBox(width: 4),
                          Text(
                            daysLeftText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color.fromARGB(255, 71, 67, 67),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    statusText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color.fromARGB(255, 71, 67, 67),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$progressPct%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: progressPct >= 100
                        ? const Color(0xFF059669)
                        : const Color.fromARGB(255, 71, 67, 67),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressClamped,
                minHeight: 8,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressPct >= 100 ? const Color(0xFF059669) : const Color(0xFF3B82F6),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              goalText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color.fromARGB(255, 71, 67, 67),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _avatarColor(dynamic id) {
    const palette = [
      Color(0xFF6F5651),
      Color(0xFFBFECE6),
      Color(0xFFE87A7A),
      Color(0xFF82B1EF),
      Color(0xFFFFB8B8),
    ];
    if (id == null) return palette[0];
    final h = id.toString().hashCode;
    return palette[h.abs() % palette.length];
  }

  int? _tryInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, color: const Color(0xFF3B82F6), size: 36),
          const SizedBox(height: 10),
          const Text(
            'No active rooms',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create a new campaign to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onCreate, child: const Text('Create Campaign')),
        ],
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
          const Icon(Icons.cloud_off, color: Color(0xFF3B82F6), size: 40),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _AllCampaignsScreen extends StatefulWidget {
  const _AllCampaignsScreen();
  @override
  State<_AllCampaignsScreen> createState() => _AllCampaignsScreenState();
}

class _AllCampaignsScreenState extends State<_AllCampaignsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final scope = AppScope.of(context);
      final res = await scope.run(() => scope.api.get('/offers', query: {
            'role': 'brand',
          }));
      if (!mounted) return;
      final list = (res as List?) ?? const [];
      setState(() {
        _items = list.whereType<Map>().map((e) => (e).cast<String, dynamic>()).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF4FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Active Rooms', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 16)),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? const Center(child: Text('No active rooms'))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: List.generate(_items.length, (i) {
                          final r = _items[i];
                          final title = (r['title'] ?? 'Untitled').toString();
                          final isComplete = r['is_completed'] == true || r['status'] == 'completed';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) {
                                      final campaign = Campaign(
                                        id: int.tryParse('${r['id'] ?? 0}') ?? 0,
                                        brandUserId: 0,
                                        title: (r['title'] ?? 'Untitled').toString(),
                                        status: r['status'] as String? ?? 'open',
                                        isCompleted: isComplete,
                                      );
                                      return BrandActiveRoomScreen(campaign: campaign);
                                    },
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.campaign_rounded, color: Color(0xFF3B82F6), size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B))),
                                    ),
                                    const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
    );
  }
}
