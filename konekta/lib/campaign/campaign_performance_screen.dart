import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/format.dart';

class CampaignPerformanceScreen extends StatelessWidget {
  const CampaignPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // --- Campaign data (mirrors seed data: offer id 1 = Summer Iced Latte Launch) ---
    const campaignTitle = 'Summer Iced Latte Launch';
    const brandName = 'Kopi Susu Co.';
    const status = CampaignStatus.inProgress;
    const rewardPerCreator = 150000;

    // --- Target & actuals ---
    const int targetViews = 50000;
    const int targetLikes = 5000;
    const int targetShares = 200;
    const int actualViews = 39000;
    const int actualLikes = 3900;
    const int actualShares = 156;
    const int progressPercent = 78;

    // --- Timeline ---
    const startDate = 'Jul 1, 2025';
    const endDate = 'Jul 14, 2025';

    return Scaffold(
      backgroundColor: KonektaColors.bg,
      appBar: AppBar(
        backgroundColor: KonektaColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: KonektaColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Campaign Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: KonektaColors.textDark)),
        actions: [
          IconButton(icon: const Icon(Icons.trending_up_rounded, color: KonektaColors.textSecondary), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert_rounded, color: KonektaColors.textSecondary), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ---- Campaign card ----
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Brand logo placeholder
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5E3C),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_cafe_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(campaignTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: KonektaColors.textDark)),
                              const SizedBox(height: 2),
                              Text(brandName, style: const TextStyle(fontSize: 12, color: KonektaColors.textMuted)),
                            ],
                          ),
                        ),
                        _StatusChip(status),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Reward per creator
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.card_giftcard_rounded, size: 18, color: KonektaColors.primary),
                          const SizedBox(width: 8),
                          const Text('Reward per creator: ', style: TextStyle(fontSize: 12, color: KonektaColors.textMuted)),
                          Text(rupiah.format(rewardPerCreator), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: KonektaColors.textDark)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campaign period
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16, color: KonektaColors.primary),
                        const SizedBox(width: 8),
                        const Text('Campaign Period: ', style: TextStyle(fontSize: 12, color: KonektaColors.textMuted)),
                        Text('$startDate - $endDate', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: KonektaColors.textDark)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ---- Progress ring + overall progress ----
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progressPercent / 100,
                            strokeWidth: 10,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation(KonektaColors.primary),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$progressPercent%', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: KonektaColors.textDark)),
                              const Text('Complete', style: TextStyle(fontSize: 11, color: KonektaColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Progress bar for timeline
                    const _ProgressTrack(label: 'Timeline Progress', percent: 0.65),
                    const SizedBox(height: 10),
                    const _ProgressTrack(label: 'Content Delivery', percent: 0.78),
                    const SizedBox(height: 10),
                    const _ProgressTrack(label: 'Quality Score', percent: 0.92),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ---- Performance metrics ----
              const Text('Performance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: KonektaColors.textDark)),
              const SizedBox(height: 10),

              // Views metric card
              _MetricCard(
                icon: Icons.visibility_rounded,
                label: 'VIEWS',
                actual: actualViews,
                target: targetViews,
                color: KonektaColors.primary,
              ),
              const SizedBox(height: 10),

              // Likes metric card
              _MetricCard(
                icon: Icons.favorite_rounded,
                label: 'LIKES',
                actual: actualLikes,
                target: targetLikes,
                color: const Color(0xFFE11D74),
              ),
              const SizedBox(height: 10),

              // Shares metric card
              _MetricCard(
                icon: Icons.share_rounded,
                label: 'SHARES',
                actual: actualShares,
                target: targetShares,
                color: const Color(0xFF22C55E),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------

enum CampaignStatus { draft, open, offered, negotiation, accepted, inProgress, submitted, completed, rejected, cancelled }

class _StatusChip extends StatelessWidget {
  final CampaignStatus status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: config['bgColor'] as Color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        config['label'] as String,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: config['textColor'] as Color, letterSpacing: 0.5),
      ),
    );
  }

  Map<String, dynamic> _statusConfig(CampaignStatus s) {
    switch (s) {
      case CampaignStatus.inProgress:
        return {'label': 'IN PROGRESS', 'bgColor': const Color(0xFFDBEAFE), 'textColor': const Color(0xFF246FE0)};
      case CampaignStatus.completed:
        return {'label': 'COMPLETED', 'bgColor': const Color(0xFFD1FAE5), 'textColor': const Color(0xFF0E9F6E)};
      case CampaignStatus.draft:
        return {'label': 'DRAFT', 'bgColor': const Color(0xFFF3F4F6), 'textColor': KonektaColors.textMuted};
      case CampaignStatus.open:
        return {'label': 'OPEN', 'bgColor': const Color(0xFFD1FAE5), 'textColor': const Color(0xFF0E9F6E)};
      case CampaignStatus.accepted:
        return {'label': 'ACCEPTED', 'bgColor': const Color(0xFFDBEAFE), 'textColor': const Color(0xFF246FE0)};
      case CampaignStatus.negotiation:
        return {'label': 'NEGOTIATION', 'bgColor': const Color(0xFFFEE2E2), 'textColor': const Color(0xFFE5484D)};
      case CampaignStatus.submitted:
        return {'label': 'SUBMITTED', 'bgColor': const Color(0xFFFDE68A), 'textColor': const Color(0xFF92400E)};
      case CampaignStatus.rejected:
        return {'label': 'REJECTED', 'bgColor': const Color(0xFFFEE2E2), 'textColor': const Color(0xFFE5484D)};
      case CampaignStatus.cancelled:
        return {'label': 'CANCELLED', 'bgColor': const Color(0xFFF3F4F6), 'textColor': KonektaColors.textMuted};
      case CampaignStatus.offered:
        return {'label': 'OFFERED', 'bgColor': const Color(0xFFEDE9FE), 'textColor': const Color(0xFF6D28D9)};
    }
  }
}

// ---------------------------------------------------------------------------
// Progress track bar
// ---------------------------------------------------------------------------

class _ProgressTrack extends StatelessWidget {
  final String label;
  final double percent;
  const _ProgressTrack({required this.label, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: KonektaColors.textMuted)),
            Text('${(percent * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: KonektaColors.textDark)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation(KonektaColors.primary),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Metric card (VIEWS / LIKES / SHARES)
// ---------------------------------------------------------------------------

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int actual;
  final int target;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.actual,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = target > 0 ? (actual / target) : 0.0;
    final compactActual = Format.compact(actual);
    final compactTarget = Format.compact(target);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: KonektaColors.textMuted, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text('$compactActual / $compactTarget', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: KonektaColors.textDark)),
                const SizedBox(height: 8),
                // Mini progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          // Percentage
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(
              '${(pct * 100).toInt()}%',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
