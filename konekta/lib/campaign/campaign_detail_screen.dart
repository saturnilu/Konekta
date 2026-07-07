import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/app_scope.dart';
import '../data/models/campaign.dart';
import '../data/repositories/campaign_repository.dart';

class CampaignDetailScreen extends StatefulWidget {
  final Campaign campaign;
  const CampaignDetailScreen({super.key, required this.campaign});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  bool _applying = false;

  Future<void> _apply() async {
    final scope = AppScope.of(context);
    final repo = CampaignRepository(scope.api);
    setState(() => _applying = true);
    try {
      await repo.apply(widget.campaign.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted!'), backgroundColor: Color(0xFF1FB76A)),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final c = widget.campaign;
    final brand = c.brandName ?? 'Brand';
    final budget = c.budget != null ? rupiah.format(c.budget) : '—';

    String _formatDate(String? raw) {
      if (raw == null || raw.isEmpty) return '—';
      try {
        final dt = DateTime.parse(raw);
        return DateFormat('d MMM yyyy', 'en').format(dt);
      } catch (_) {
        return raw;
      }
    }

    final statusLabel = c.status.replaceAll('_', ' ').toUpperCase();
    final statusColor = c.isOpen
        ? const Color(0xFF246FE0)
        : c.isCompletedStatus
            ? const Color(0xFF1FB76A)
            : const Color(0xFFF6A623);
    final statusBg = c.isOpen
        ? const Color(0xFFDBEAFE)
        : c.isCompletedStatus
            ? const Color(0xFFD6F8E8)
            : const Color(0xFFFFF3CD);

    final brandColors = [
      const Color(0xFF6A534E),
      const Color(0xFF4A7DFF),
      const Color(0xFF2FA2EE),
      const Color(0xFF1FB76A),
      const Color(0xFFF6A623),
      const Color(0xFFE5484D),
    ];
    final avatarColor = brandColors[brand.hashCode.abs() % brandColors.length];

    return Scaffold(
      backgroundColor: KonektaColors.bg,
      appBar: AppBar(
        backgroundColor: KonektaColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: KonektaColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Campaign Detail',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: KonektaColors.textDark),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Campaign header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: avatarColor, borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: Text(
                        brand.isEmpty ? 'B' : brand[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            brand,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: KonektaColors.textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c.title,
                            style: const TextStyle(fontSize: 12, color: KonektaColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        statusLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Campaign brief
              const Text('Campaign Brief', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: KonektaColors.textDark)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE3E9F2)),
                ),
                child: Text(
                  (c.description != null && c.description!.isNotEmpty)
                      ? c.description!
                      : 'No brief provided.',
                  style: const TextStyle(fontSize: 13, color: KonektaColors.textSecondary, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),

              // Campaign details
              const Text('Campaign Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: KonektaColors.textDark)),
              const SizedBox(height: 8),
              _DetailRow(label: 'Budget', value: budget),
              _DetailRow(label: 'Start Date', value: _formatDate(c.startDate)),
              _DetailRow(label: 'End Date', value: _formatDate(c.endDate)),
              if (c.deliverables != null && c.deliverables!.isNotEmpty)
                _DetailRow(label: 'Deliverables', value: c.deliverables!),
              _DetailRow(label: 'Applicants', value: '${c.applicantsCount ?? 0}'),
              if ((c.maxCreators ?? 0) > 0)
                _DetailRow(
                  label: 'Slots',
                  value: c.isFull
                      ? 'Full (${c.maxCreators} / ${c.maxCreators})'
                      : '${c.slotsLeft} left of ${c.maxCreators}',
                ),
              if (c.daysLeft != null)
                _DetailRow(
                  label: 'Days Left',
                  value: c.daysLeft! > 0 ? '${c.daysLeft} days' : c.daysLeft == 0 ? 'Due today' : 'Closed',
                ),
              const SizedBox(height: 24),

              // Apply / Applied button
              if (c.isOpen || c.isInProgress)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: c.hasApplied
                      ? Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6F8E8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Already Applied',
                            style: TextStyle(color: Color(0xFF1FB76A), fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        )
                      : c.isFull
                          ? Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.block_rounded, size: 18, color: Color(0xFF94A3B8)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Campaign Full',
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            )
                          : DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [KonektaColors.primaryGradientStart, KonektaColors.primaryGradientEnd],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ElevatedButton(
                                onPressed: _applying ? null : _apply,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _applying
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text(
                                        'Apply Now',
                                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                                      ),
                              ),
                            ),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: KonektaColors.textMuted)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: KonektaColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
