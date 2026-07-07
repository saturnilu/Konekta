import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/app_scope.dart';

class InfluencerAnalyticsScreen extends StatefulWidget {
  const InfluencerAnalyticsScreen({super.key});

  @override
  State<InfluencerAnalyticsScreen> createState() => _InfluencerAnalyticsScreenState();
}

class _InfluencerAnalyticsScreenState extends State<InfluencerAnalyticsScreen> {
  int _selectedTab = 0;
  static const _tabs = ['Weekly', 'Monthly', 'Annually'];
  static const _tabDays = [7, 30, 365];

  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final scope = AppScope.of(context);
      final days = _tabDays[_selectedTab];
      final result = await scope.api.get('/analytics/influencer', query: {'days': days});
      if (!mounted) return;
      setState(() {
        _data = result is Map ? Map<String, dynamic>.from(result as Map) : {};
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

  void _onTabChanged(int i) {
    setState(() => _selectedTab = i);
    _load();
  }

  /// Parse daily_stats list into bar data.
  /// Each entry from API: { day: "2024-01-15", views: 1200, engagement: 340 }
  List<_BarEntry> _buildBarData() {
    final raw = (_data?['daily_stats'] as List?) ?? [];
    if (raw.isEmpty) return [];

    // For annually, group by month (sum)
    if (_selectedTab == 2) {
      final Map<String, _BarEntry> monthly = {};
      for (final e in raw) {
        final map = e as Map;
        final dayStr = map['day']?.toString() ?? '';
        try {
          final dt = DateTime.parse(dayStr);
          const months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
          final key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}';
          final label = months[dt.month - 1];
          final v = (map['views'] ?? 0) as num;
          final eng = (map['engagement'] ?? 0) as num;
          if (monthly.containsKey(key)) {
            monthly[key] = _BarEntry(
              label: label,
              views: monthly[key]!.views + v.toDouble(),
              engagement: monthly[key]!.engagement + eng.toDouble(),
            );
          } else {
            monthly[key] = _BarEntry(label: label, views: v.toDouble(), engagement: eng.toDouble());
          }
        } catch (_) {}
      }
      return monthly.values.toList();
    }

    // Weekly / Monthly: one bar per day
    return raw.map<_BarEntry>((e) {
      final map = e as Map;
      final dayStr = map['day']?.toString() ?? '';
      String label = dayStr;
      try {
        final dt = DateTime.parse(dayStr);
        if (_selectedTab == 0) {
          const days = ['MON','TUE','WED','THU','FRI','SAT','SUN'];
          label = days[dt.weekday - 1];
        } else {
          label = dt.day.toString();
        }
      } catch (_) {}
      return _BarEntry(
        label: label,
        views: ((map['views'] ?? 0) as num).toDouble(),
        engagement: ((map['engagement'] ?? 0) as num).toDouble(),
      );
    }).toList();
  }

  String _fmt(dynamic val) {
    if (val == null) return '0';
    final n = double.tryParse(val.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toStringAsFixed(n == n.truncateToDouble() ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: KonektaColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 16),
            decoration: const BoxDecoration(
              gradient: KonektaColors.headerGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: const Text(
              'Konekta',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Performance',
                      style: TextStyle(
                        color: KonektaColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Daily metrics and growth analysis for your all Campaigns',
                      style: TextStyle(color: KonektaColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    _buildSegmentedControl(),
                    const SizedBox(height: 20),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      _ErrorState(message: _error!, onRetry: _load)
                    else ...[
                      _buildDailyPerformanceCard(),
                      const SizedBox(height: 30),
                      const Text(
                        'GROWTH',
                        style: TextStyle(
                          color: KonektaColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildGrowthGrid(),
                      const SizedBox(height: 30),
                      const Text(
                        'RECENT EARNINGS',
                        style: TextStyle(
                          color: KonektaColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildEarningsTable(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KonektaColors.border,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onTabChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _tabs[i],
                    style: TextStyle(
                      color: isSelected ? KonektaColors.primary : KonektaColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDailyPerformanceCard() {
    final barData = _buildBarData();
    final isEmpty = barData.isEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVITY LOG',
                style: TextStyle(
                  color: KonektaColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  _legendItem(KonektaColors.primary, 'Views'),
                  const SizedBox(width: 15),
                  _legendItem(const Color(0xFFC48AFF), 'Engagement'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Daily\nPerformance',
            style: TextStyle(
              color: KonektaColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 25),
          if (isEmpty)
            const SizedBox(
              height: 90,
              child: Center(
                child: Text(
                  'No video data yet.\nSubmit a TikTok video to a campaign to see stats.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: KonektaColors.textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            _BarChart(data: barData),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: KonektaColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildGrowthGrid() {
    final kpis = (_data?['kpis'] as Map?)?.cast<String, dynamic>() ?? {};

    // Sum total views & likes from daily_stats for the selected period
    final dailyList = (_data?['daily_stats'] as List?) ?? [];
    final totalViews = dailyList.fold<double>(
        0, (s, e) => s + (((e as Map)['views'] ?? 0) as num).toDouble());
    final totalEngagement = dailyList.fold<double>(
        0, (s, e) => s + (((e as Map)['engagement'] ?? 0) as num).toDouble());

    final hasKpis = kpis.isNotEmpty;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      children: [
        _GrowthCard(
          title: 'TOTAL VIEWS',
          value: _fmt(totalViews),
          valueColor: KonektaColors.primary,
        ),
        _GrowthCard(
          title: 'TOTAL LIKES',
          value: _fmt(totalEngagement),
          valueColor: const Color(0xFFC48AFF),
        ),
        _GrowthCard(
          title: 'TOTAL FOLLOWERS',
          value: hasKpis ? _fmt(kpis['total_followers']) : '—',
          valueColor: KonektaColors.success,
        ),
        _GrowthCard(
          title: 'ENGAGEMENT RATE',
          value: hasKpis ? '${_fmt(kpis['avg_engagement_rate'])}%' : '—',
          valueColor: KonektaColors.primary,
        ),
      ],
    );
  }

  Widget _buildEarningsTable() {
    final campaigns = (_data?['recent_campaigns'] as List?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: KonektaColors.border,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('CAMPAIGN', style: TextStyle(color: KonektaColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.3))),
                Expanded(flex: 2, child: Text('STATUS', style: TextStyle(color: KonektaColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.3))),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('RATE', style: TextStyle(color: KonektaColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.3)))),
              ],
            ),
          ),
          if (campaigns.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No campaigns yet',
                  style: TextStyle(color: KonektaColors.textSecondary, fontSize: 14),
                ),
              ),
            )
          else
            ...campaigns.map((c) {
              final cam = (c as Map).cast<String, dynamic>();
              return _EarningsRow(
                title: cam['title']?.toString() ?? 'Untitled',
                status: cam['application_status']?.toString() ?? cam['status']?.toString() ?? '-',
                amount: 'Rp${_fmt(cam['proposed_rate'] ?? cam['budget'] ?? 0)}',
              );
            }),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: const BoxDecoration(
              color: Color(0xFFFBFDFF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const Center(
              child: Text(
                'SHOW ALL TRANSACTIONS',
                style: TextStyle(
                  color: KonektaColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarEntry {
  final String label;
  final double views;
  final double engagement;
  const _BarEntry({required this.label, required this.views, required this.engagement});
}

class _BarChart extends StatelessWidget {
  final List<_BarEntry> data;
  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final allVals = data.expand((e) => [e.views, e.engagement]);
    final maxVal = allVals.fold<double>(1, (m, v) => v > m ? v : m);
    const maxHeight = 90.0;
    final barW = data.length > 20 ? 6.0 : (data.length > 10 ? 10.0 : 15.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.map((item) {
            final viewH = (item.views / maxVal * maxHeight).clamp(4.0, maxHeight);
            final engH  = (item.engagement / maxVal * maxHeight).clamp(4.0, maxHeight);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Bar(height: viewH, width: barW, color: KonektaColors.primary),
                const SizedBox(width: 3),
                _Bar(height: engH,  width: barW, color: const Color(0xFFC48AFF)),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 15),
        if (data.length <= 14)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: data.map((item) {
              return SizedBox(
                width: barW * 2 + 3,
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: KonektaColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final double width;
  final Color color;
  const _Bar({required this.height, required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(3),
          topRight: Radius.circular(3),
        ),
      ),
    );
  }
}

class _GrowthCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;

  const _GrowthCard({required this.title, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: const TextStyle(
                color: KonektaColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              )),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(color: valueColor, fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _EarningsRow extends StatelessWidget {
  final String title;
  final String status;
  final String amount;
  const _EarningsRow({required this.title, required this.status, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: KonektaColors.softBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.campaign, color: KonektaColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: KonektaColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(status,
                style: const TextStyle(color: KonektaColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(amount,
                  style: const TextStyle(
                      color: KonektaColors.success, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, color: KonektaColors.primary, size: 48),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: KonektaColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}