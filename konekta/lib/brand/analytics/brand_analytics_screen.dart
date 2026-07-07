import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/app_scope.dart';
import '../../core/theme.dart';
import '../../notification/notifications_screen.dart';

const Color _kBlue      = Color(0xFF1E70E7);
const Color _kTextDark  = Color(0xFF2C254A);
const Color _kTextSubtle= Color(0xFF757D95);
const Color _kGreen     = Color(0xFF2FA85C);
const Color _kBg        = Color(0xFFEDF4FF);
const Color _kViewsBar  = Color(0xFFD3DCFA);
const Color _kEngageBar = Color(0xFFE8BEE3);

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _BarEntry {
  final String label;
  final double views;
  final double engagement;
  const _BarEntry({required this.label, required this.views, required this.engagement});
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class BrandAnalyticsScreen extends StatefulWidget {
  const BrandAnalyticsScreen({super.key});

  @override
  State<BrandAnalyticsScreen> createState() => _BrandAnalyticsScreenState();
}

class _BrandAnalyticsScreenState extends State<BrandAnalyticsScreen> {
  int _selectedTab = 0;
  static const _tabs    = ['Weekly', 'Monthly', 'Annually'];
  static const _tabDays = [7, 30, 365];

  Map<String, dynamic>? _data;
  bool   _loading     = true;
  String? _error;
  bool   _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final scope  = AppScope.of(context);
      final days   = _tabDays[_selectedTab];
      final result = await scope.api.get('/analytics/brand', query: {'days': days});
      if (!mounted) return;
      setState(() {
        _data    = result is Map ? Map<String, dynamic>.from(result as Map) : {};
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  void _onTabChanged(int i) {
    setState(() => _selectedTab = i);
    _load();
  }

  // ---- helpers ----

  String _fmt(dynamic val) {
    if (val == null) return '0';
    final n = double.tryParse(val.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toStringAsFixed(n == n.truncateToDouble() ? 0 : 1);
  }

  String _fmtRupiah(dynamic val) {
    if (val == null) return 'Rp0';
    final n = double.tryParse(val.toString()) ?? 0;
    if (n >= 1000000) return 'Rp${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return 'Rp${(n / 1000).toStringAsFixed(0)}k';
    return 'Rp${n.toStringAsFixed(0)}';
  }

  // ---- bar data from daily_stats ----
  // API returns: [{ day: "2024-01-15", views: 4200, engagement: 980 }, ...]
  // views     = total views across all influencer videos under this brand
  // engagement = total likes

  List<_BarEntry> _buildBarData() {
    final raw = (_data?['daily_stats'] as List?) ?? [];
    if (raw.isEmpty) return [];

    // Annually → group by month
    if (_selectedTab == 2) {
      final Map<String, _BarEntry> monthly = {};
      for (final e in raw) {
        final map    = e as Map;
        final dayStr = map['day']?.toString() ?? '';
        try {
          final dt    = DateTime.parse(dayStr);
          const mon   = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
          final key   = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          final label = mon[dt.month - 1];
          final v     = ((map['views'] ?? 0) as num).toDouble();
          final eng   = ((map['engagement'] ?? 0) as num).toDouble();
          if (monthly.containsKey(key)) {
            monthly[key] = _BarEntry(
              label:      label,
              views:      monthly[key]!.views + v,
              engagement: monthly[key]!.engagement + eng,
            );
          } else {
            monthly[key] = _BarEntry(label: label, views: v, engagement: eng);
          }
        } catch (_) {}
      }
      return monthly.values.toList();
    }

    // Weekly / Monthly → one bar per day
    return raw.map<_BarEntry>((e) {
      final map    = e as Map;
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
        label:      label,
        views:      ((map['views'] ?? 0) as num).toDouble(),
        engagement: ((map['engagement'] ?? 0) as num).toDouble(),
      );
    }).toList();
  }

  List<BarChartGroupData> _buildBarGroups() {
    final data = _buildBarData();
    if (data.isEmpty) return [];
    return List.generate(data.length, (i) => BarChartGroupData(
      x: i,
      barRods: [
        BarChartRodData(
          toY: data[i].views,
          color: _kViewsBar,
          width: 14,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4), topRight: Radius.circular(4),
          ),
        ),
        BarChartRodData(
          toY: data[i].engagement,
          color: _kEngageBar,
          width: 14,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4), topRight: Radius.circular(4),
          ),
        ),
      ],
    ));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Performance',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _kTextDark)),
                      const SizedBox(height: 6),
                      const Text(
                        'Daily metrics and growth analysis for your all Campaigns',
                        style: TextStyle(fontSize: 14, color: _kTextSubtle, height: 1.3),
                      ),
                      const SizedBox(height: 20),
                      _buildTabFilter(),
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
                        const SizedBox(height: 24),
                        _buildGrowthSection(),
                        const SizedBox(height: 24),
                        _buildCampaignSummary(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(gradient: KonektaGradients.primary),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Konekta',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            child: const Icon(Icons.notifications_none, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildTabFilter() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFE2ECFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onTabChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _tabs[i],
                    style: TextStyle(
                      color:      selected ? _kBlue : _kTextSubtle,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
    final barData   = _buildBarData();
    final barGroups = _buildBarGroups();
    final isEmpty   = barGroups.isEmpty;
    final labels    = barData.map((e) => e.label).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ACTIVITY LOG',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold,
                      color: _kBlue, letterSpacing: 0.5)),
              Row(
                children: [
                  _legendDot(_kViewsBar,  'Views'),
                  const SizedBox(width: 12),
                  _legendDot(_kEngageBar, 'Likes'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Daily\nPerformance',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold,
                  color: _kTextDark, height: 1.1)),
          const SizedBox(height: 30),
          if (isEmpty)
            const SizedBox(
              height: 170,
              child: Center(
                child: Text(
                  'No video data yet.\nInfluencers need to submit TikTok videos\nto your campaigns first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _kTextSubtle, fontSize: 13),
                ),
              ),
            )
          else
            SizedBox(
              height: 170,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: barGroups.fold<double>(1, (m, g) {
                    final maxG = g.barRods.map((r) => r.toY).reduce((a, b) => a > b ? a : b);
                    return maxG > m ? maxG : m;
                  }) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) {
                          final idx = v.toInt();
                          if (idx < labels.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8,
                              child: Text(labels[idx],
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _kTextSubtle)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData:   const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups:  barGroups,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: _kTextSubtle)),
      ],
    );
  }

  Widget _buildGrowthSection() {
    final kpis      = (_data?['kpis'] as Map?)?.cast<String, dynamic>() ?? {};
    final dailyList = (_data?['daily_stats'] as List?) ?? [];

    // Sum views & likes for the selected period from daily_stats
    final totalViews = dailyList.fold<double>(
        0, (s, e) => s + (((e as Map)['views'] ?? 0) as num).toDouble());
    final totalLikes = dailyList.fold<double>(
        0, (s, e) => s + (((e as Map)['engagement'] ?? 0) as num).toDouble());

    final hasKpis = kpis.isNotEmpty;

    final metrics = [
      ('TOTAL VIEWS',   _fmt(totalViews),                                     _kBlue),
      ('TOTAL LIKES',   _fmt(totalLikes),                                     const Color(0xFFC48AFF)),
      ('ACTIVE OFFERS', hasKpis ? _fmt(kpis['active_offers'])     : '—',     _kBlue),
      ('APPLICATIONS',  hasKpis ? _fmt(kpis['total_applications']) : '—',    _kGreen),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Growth',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kTextDark)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: metrics
              .map((m) => _MetricCard(title: m.$1, value: m.$2, valueColor: m.$3))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCampaignSummary() {
    final kpis      = (_data?['kpis'] as Map?)?.cast<String, dynamic>() ?? {};
    final topNiches = (_data?['top_niches'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Campaign Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kTextDark)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              // header row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFEBE6E6),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: Text('DESCRIPTION',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6E6E6E)))),
                    Expanded(flex: 2, child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('VALUE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6E6E6E))),
                    )),
                  ],
                ),
              ),
              if (kpis.isNotEmpty) ...[
                _SummaryRow(label: 'Open Offers',       value: _fmt(kpis['open_offers'])),
                _SummaryRow(label: 'Completed Offers',  value: _fmt(kpis['completed_offers'])),
                _SummaryRow(label: 'Total Budget',      value: _fmtRupiah(kpis['total_budget'])),
                _SummaryRow(label: 'Budget Committed',  value: _fmtRupiah(kpis['committed_spend'])),
              ],
              if (topNiches.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('TOP NICHES',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold,
                            color: Color(0xFF6E6E6E))),
                  ),
                ),
                ...topNiches.map((n) {
                  final niche = (n as Map);
                  return _SummaryRow(
                    label: niche['niche']?.toString() ?? '-',
                    value: '${niche['n'] ?? 0} influencers',
                  );
                }),
              ],
              if (kpis.isEmpty && topNiches.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('No data yet',
                        style: TextStyle(color: _kTextSubtle, fontSize: 14)),
                  ),
                ),
              // footer
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFECEFFB),
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                ),
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('SHOW ALL TRANSACTIONS',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold,
                          color: Color(0xFF5A5385), letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color  valueColor;

  const _MetricCard({required this.title, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold,
                  color: _kTextSubtle, letterSpacing: 0.3)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFD9E7FF),
                      borderRadius: BorderRadius.circular(50)),
                  child: const Icon(Icons.campaign, color: Color(0xFF4285F4), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold, color: _kTextDark),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: _kGreen)),
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
          const Icon(Icons.cloud_off, color: _kBlue, size: 48),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextSubtle)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}