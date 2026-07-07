import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../explore/brand_influencer_progress_detail_screen.dart';
import '../explore/brand_approval_applicants_screen.dart';

class CampaignRoomScreen extends StatelessWidget {
  const CampaignRoomScreen({super.key});

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
        titleSpacing: 0,
        title: const Text(
          'Konekta',
          style: TextStyle(
            color: KonektaColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ACTIVE CAMPAIGN',
              style: TextStyle(
                color: KonektaColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kopi susu',
              style: TextStyle(
                color: KonektaColors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4E4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.access_time_filled, size: 14, color: Color(0xFFC62828)),
                  SizedBox(width: 6),
                  Text(
                    'Deadline: 14 Days Left',
                    style: TextStyle(
                      color: Color(0xFFC62828),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
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
                    children: const [
                      Text(
                        'Overall Campaign\nProgress',
                        style: TextStyle(
                          color: KonektaColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        '78%',
                        style: TextStyle(
                          color: KonektaColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 0.78,
                      minHeight: 10,
                      backgroundColor: Color(0xFFE3EDFA),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006684)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniMetric(
                          label: 'Total Views',
                          current: '1.2M',
                          target: '1.5M',
                          progress: 1.2 / 1.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMiniMetric(
                          label: 'Total Likes',
                          current: '85K',
                          target: '100K',
                          progress: 85 / 100,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMiniMetric(
                          label: 'Total Shares',
                          current: '12K',
                          target: '15K',
                          progress: 12 / 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5F1FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people, color: KonektaColors.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Total Influencers',
                        style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '15/20',
                        style: TextStyle(color: KonektaColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFC62828),
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Action Required',
                    style: TextStyle(color: KonektaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Applicants awaiting your review.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0052CC), Color(0xFF006684)],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BrandApprovalApplicantsScreen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Approval Applicants (3 Pending)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Participating\nInfluencers',
                          style: TextStyle(color: KonektaColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'View\nAll',
                            textAlign: TextAlign.right,
                            style: TextStyle(color: KonektaColors.primary, fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  _buildInfluencerRow(
                    name: 'beebadoobie',
                    progress: 0.90,
                    progressLabel: '90%',
                    actionWidget: _buildOutlineButton(
                      'Detail',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BrandInfluencerProgressDetailScreen(showPayout: false),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  _buildInfluencerRow(
                    name: 'Lana del rei',
                    progress: 1.0,
                    progressLabel: '100%',
                    actionWidget: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BrandInfluencerProgressDetailScreen(showPayout: true),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F1FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: KonektaColors.primary.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle, size: 12, color: Color(0xFF0052CC)),
                            SizedBox(width: 4),
                            Text(
                              'Complete',
                              style: TextStyle(color: Color(0xFF0052CC), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  _buildInfluencerRow(
                    name: 'laufey',
                    progress: 0.50,
                    progressLabel: '50%',
                    actionWidget: _buildOutlineButton(
                      'Detail',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BrandInfluencerProgressDetailScreen(showPayout: false),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required String current,
    required String target,
    required double progress,
  }) {
    final labelParts = label.split(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${labelParts[0]}\n${labelParts[1]}',
          style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.2),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$current ',
              style: const TextStyle(color: KonektaColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              '/ $target',
              style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: const Color(0xFFE3EDFA),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0052CC)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfluencerRow({
    required String name,
    required double progress,
    required String progressLabel,
    required Widget actionWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFD2E6FF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: KonektaColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE3EDFA),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF006684)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      progressLabel,
                      style: const TextStyle(color: KonektaColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          actionWidget,
        ],
      ),
    );
  }

  Widget _buildOutlineButton(String text, {VoidCallback? onPressed}) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
