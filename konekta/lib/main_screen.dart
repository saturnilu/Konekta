import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/app_scope.dart';
import 'brand/dashboard/brand_dashboard_screen.dart';
import 'brand/analytics/brand_analytics_screen.dart';
import 'brand/profile/brand_profile_screen.dart';
import 'brand/explore/brand_explore_screen.dart';
import 'influencer/dashboard/influencer_dashboard_screen.dart';
import 'influencer/analytics/influencer_analytics_screen.dart';
import 'influencer/profile/influencer_profile_screen.dart';
import 'influencer/explore/influencer_explore_screen.dart';
import 'chat/chat_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;

  List<Widget> _pagesFor(String role) {
    final isBrand = role == 'brand';
    return [
      isBrand ? const BrandDashboardScreen() : const InfluencerDashboardScreen(),
      isBrand ? const BrandExploreScreen() : const InfluencerExploreScreen(),
      isBrand ? const BrandAnalyticsScreen() : const InfluencerAnalyticsScreen(),
      isBrand ? const BrandProfileScreen() : const InfluencerProfileScreen(),
    ];
  }

  Widget _buildItem(IconData icon, String label, int i) {
    final active = _idx == i;
    return InkWell(
      onTap: () => setState(() => _idx = i),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? KonektaColors.primary : KonektaColors.textMuted, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: active ? KonektaColors.primary : KonektaColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = AppScope.of(context).role;
    final pages = _pagesFor(role);
    return Scaffold(
      body: IndexedStack(index: _idx, children: pages),
      floatingActionButton: _idx == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatListScreen())),
              backgroundColor: KonektaColors.primary,
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildItem(Icons.dashboard_rounded, 'DASHBOARD', 0),
                _buildItem(Icons.explore_rounded, 'EXPLORE', 1),
                _buildItem(Icons.bar_chart_rounded, 'ANALYTICS', 2),
                _buildItem(Icons.person_rounded, 'PROFILE', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
