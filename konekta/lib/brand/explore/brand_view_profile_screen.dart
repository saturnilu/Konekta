import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'brand_chatlist_screen.dart';

class BrandViewProfileScreen extends StatelessWidget {
  const BrandViewProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KonektaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black54, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'View Profile',
          style: TextStyle(
            color: KonektaColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: KonektaColors.primary.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      color: const Color(0xFF9CC2F9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Situbondo',
                    style: TextStyle(
                      color: KonektaColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '@stdbdnaonedada',
                    style: TextStyle(
                      color: KonektaColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildProfileBadge(label: 'Food'),
                      const SizedBox(width: 8),
                      _buildProfileBadge(label: 'Lifestyle'),
                      const SizedBox(width: 8),
                      _buildProfileBadge(
                        label: 'Verified',
                        icon: const Icon(Icons.check_circle, size: 14, color: KonektaColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Audience & Reach',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: KonektaColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.people_alt_outlined,
                          iconBg: const Color(0xFFE2F5F3),
                          iconColor: KonektaColors.success,
                          label: 'Followers',
                          value: '25.4K',
                          trend: '+12% this month',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.visibility_outlined,
                          iconBg: const Color(0xFFEBF2F9),
                          iconColor: KonektaColors.primary,
                          label: 'Avg. Views',
                          value: '15.2K',
                          trend: 'Per post',
                          isPositiveTrend: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.favorite_border,
                          iconBg: const Color(0xFFFDECE7),
                          iconColor: const Color(0xFFFF7043),
                          label: 'Engagement',
                          value: '3.2%',
                          trend: '+12% this month',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.share_outlined,
                          iconBg: const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF66BB6A),
                          label: 'Campaign',
                          value: '1.3k',
                          trend: '+12% this month',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Content',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: KonektaColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Row(
                          children: [
                            Text(
                              'View All ',
                              style: TextStyle(
                                color: KonektaColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 11, color: KonektaColors.primary),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildGalleryCard(color: const Color(0xFF9E5757), views: '22.1K'),
                        const SizedBox(width: 12),
                        _buildGalleryCard(color: const Color(0xFFF37A7A), views: '18.5K'),
                        const SizedBox(width: 12),
                        _buildGalleryCard(color: const Color(0xFF751C1C), views: '14.9K'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: KonektaColors.background,
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF76D1FF), Color(0xFF408CFF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: KonektaColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BrandChatListScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Contact',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBadge({required String label, Widget? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD2E6FF).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon,
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: KonektaColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String trend,
    bool isPositiveTrend = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: KonektaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (isPositiveTrend) ...[
                Icon(Icons.trending_up, size: 13, color: KonektaColors.success),
                const SizedBox(width: 4),
              ],
              Text(
                trend,
                style: TextStyle(
                  fontSize: 11,
                  color: isPositiveTrend ? KonektaColors.success : Colors.grey.shade500,
                  fontWeight: isPositiveTrend ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryCard({required Color color, required String views}) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow, size: 14, color: Colors.white),
                const SizedBox(width: 2),
                Text(
                  views,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
