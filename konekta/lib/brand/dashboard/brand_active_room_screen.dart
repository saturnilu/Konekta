import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_scope.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/format.dart';
import '../../data/models/campaign.dart';
import '../../data/repositories/campaign_repository.dart';

class BrandActiveRoomScreen extends StatefulWidget {
  final Campaign campaign;
  const BrandActiveRoomScreen({super.key, required this.campaign});

  @override
  State<BrandActiveRoomScreen> createState() => _BrandActiveRoomScreenState();
}

class _BrandActiveRoomScreenState extends State<BrandActiveRoomScreen> {
  static const _blue = Color(0xFF3B82F6);
  static const _bg = Color(0xFFEDF4FC);

  bool _loading = true;
  String? _error;
  List<Applicant> _applicants = const [];
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
    setState(() { _loading = true; _error = null; });
    try {
      final scope = AppScope.of(context);
      final repo = CampaignRepository(scope.api);
      final list = await repo.listApplicants(widget.campaign.id);
      if (!mounted) return;
      setState(() { _applicants = list; _loading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _setStatus(Applicant applicant, String status) async {
    try {
      final scope = AppScope.of(context);
      final repo = CampaignRepository(scope.api);
      await repo.setApplicantStatus(widget.campaign.id, applicant.id, status);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status == 'approved' ? '${applicant.name} approved!' : '${applicant.name} rejected')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  List<Applicant> get _pending   => _applicants.where((a) => a.status == 'pending').toList();
  List<Applicant> get _approved  => _applicants.where((a) => a.status == 'approved' || a.status == 'completed').toList();
  List<Applicant> get _completed => _applicants.where((a) => a.status == 'completed').toList();

  @override
  Widget build(BuildContext context) {
    final c = widget.campaign;
    final rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          c.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E293B)),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CampaignInfoCard(campaign: c, rupiah: rupiah),
              const SizedBox(height: 16),

              // ── CAMPAIGN PROGRESS CARD ──────────────────────────────
              if (!_loading) _CampaignProgressCard(
                approved:  _approved.length,
                completed: _completed.length,
              ),
              if (!_loading) const SizedBox(height: 20),

              _SectionHeader(
                title: 'Action Required',
                badge: _loading ? null : _pending.length,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 10),
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (_error != null)
                _ErrorCard(message: _error!, onRetry: _load)
              else if (_pending.isEmpty)
                _EmptyCard(
                  icon: Icons.how_to_reg_outlined,
                  message: 'No pending applicants',
                  sub: 'When influencers apply, they will appear here for your review.',
                )
              else
                ..._pending.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ApplicantCard(
                        applicant: a,
                        onApprove: () => _setStatus(a, 'approved'),
                        onReject: () => _setStatus(a, 'rejected'),
                      ),
                    )),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Participating Influencers',
                badge: _loading ? null : _approved.length,
                color: const Color(0xFF22C55E),
              ),
              const SizedBox(height: 10),
              if (!_loading && _approved.isEmpty)
                _EmptyCard(
                  icon: Icons.people_outline_rounded,
                  message: 'No approved influencers yet',
                  sub: 'Approved applicants will appear here.',
                )
              else if (!_loading)
                ..._approved.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ParticipantCard(applicant: a),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Campaign progress card ────────────────────────────────────────────────────

class _CampaignProgressCard extends StatelessWidget {
  final int approved;
  final int completed;
  const _CampaignProgressCard({required this.approved, required this.completed});

  @override
  Widget build(BuildContext context) {
    // total = approved (active) + completed (paid)
    final total = approved + completed;
    final progress = total > 0 ? (completed / total) : 0.0;
    final pct = (progress * 100).round();
    final isComplete = total > 0 && completed >= total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Campaign Progress',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
              Text('$pct%',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isComplete ? const Color(0xFF22C55E) : const Color(0xFF3B82F6))),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(
                  isComplete ? const Color(0xFF22C55E) : const Color(0xFF3B82F6)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ProgressStat(
                label: 'Paid',
                value: '$completed',
                color: const Color(0xFF22C55E),
                icon: Icons.payments_rounded,
              ),
              const SizedBox(width: 16),
              _ProgressStat(
                label: 'In Progress',
                value: '$approved',
                color: const Color(0xFF3B82F6),
                icon: Icons.pending_rounded,
              ),
              const SizedBox(width: 16),
              _ProgressStat(
                label: 'Total',
                value: '$total',
                color: const Color(0xFF64748B),
                icon: Icons.people_rounded,
              ),
            ],
          ),
          if (isComplete) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: Color(0xFF16A34A), size: 16),
                  const SizedBox(width: 8),
                  Text('All influencers have been paid!',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: const Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _ProgressStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
            Text(label,
                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF94A3B8))),
          ],
        ),
      ],
    );
  }
}

// ── Campaign info card ────────────────────────────────────────────────────────

class _CampaignInfoCard extends StatelessWidget {
  final Campaign campaign;
  final NumberFormat rupiah;
  const _CampaignInfoCard({required this.campaign, required this.rupiah});

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: _avatarColor(c.id),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    Text(c.brandName ?? '',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              _StatusBadge(status: c.status),
            ],
          ),
          if ((c.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Text('Brief', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
            const SizedBox(height: 4),
            Text(c.description!,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF334155), height: 1.5)),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (c.budget != null && c.budget! > 0)
                _InfoChip(icon: Icons.payments_outlined, label: rupiah.format(c.budget!)),
              if (c.endDate != null && c.endDate!.isNotEmpty)
                _InfoChip(icon: Icons.calendar_today_outlined, label: 'Deadline: ${c.endDate}'),
              _InfoChip(
                icon: Icons.people_alt_outlined,
                label: '${c.applicantsCount ?? 0} applicants',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _avatarColor(int id) {
    const palette = [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF10B981), Color(0xFFF59E0B)];
    return palette[id.abs() % palette.length];
  }
}

// ── Applicant card (pending — approve/reject) ────────────────────────────────

class _ApplicantCard extends StatelessWidget {
  final Applicant applicant;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _ApplicantCard({required this.applicant, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final a = applicant;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEF3C7), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: a.name, avatarUrl: a.avatarUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.name,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                    if ((a.username ?? '').isNotEmpty)
                      Text('@${a.username}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('PENDING',
                    style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFFD97706))),
              ),
            ],
          ),
          if ((a.niche ?? '').isNotEmpty || a.followersCount != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if ((a.niche ?? '').isNotEmpty)
                  _InfoChip(icon: Icons.tag_rounded, label: a.niche!),
                if (a.followersCount != null)
                  _InfoChip(icon: Icons.people_outline, label: '${Format.compact(a.followersCount!)} followers'),
                if (a.engagementRate != null)
                  _InfoChip(icon: Icons.trending_up_rounded, label: '${a.engagementRate!.toStringAsFixed(1)}% eng.'),
              ],
            ),
          ],
          if ((a.message ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '"${a.message}"',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B), fontStyle: FontStyle.italic, height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
                  label: Text('Reject',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                  label: Text('Approve',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Participant card (approved) ───────────────────────────────────────────────

class _ParticipantCard extends StatelessWidget {
  final Applicant applicant;
  const _ParticipantCard({required this.applicant});

  @override
  Widget build(BuildContext context) {
    final a = applicant;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          _Avatar(name: a.name, avatarUrl: a.avatarUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                if ((a.username ?? '').isNotEmpty)
                  Text('@${a.username}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                if (a.followersCount != null)
                  Text('${Format.compact(a.followersCount!)} followers',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: a.status == 'completed' ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  a.status == 'completed' ? Icons.payments_rounded : Icons.check_circle_rounded,
                  size: 12,
                  color: a.status == 'completed' ? const Color(0xFF16A34A) : const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 4),
                Text(
                  a.status == 'completed' ? 'PAID' : 'APPROVED',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: a.status == 'completed' ? const Color(0xFF16A34A) : const Color(0xFF3B82F6),
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

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? badge;
  final Color color;
  const _SectionHeader({required this.title, this.badge, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
        if (badge != null && badge! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Text('$badge',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  const _Avatar({required this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(radius: 22, backgroundImage: NetworkImage(avatarUrl!));
    }
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
      child: Text(initials,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF3B82F6), fontSize: 16)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, dynamic>> map = {
      'open': {'label': 'OPEN', 'bg': Color(0xFFDBEAFE), 'fg': Color(0xFF246FE0)},
      'in_progress': {'label': 'IN PROGRESS', 'bg': Color(0xFFFEF3C7), 'fg': Color(0xFFD97706)},
      'completed': {'label': 'COMPLETED', 'bg': Color(0xFFDCFCE7), 'fg': Color(0xFF16A34A)},
    };
    final s = map[status] ?? {'label': status.toUpperCase(), 'bg': const Color(0xFFF1F5F9), 'fg': const Color(0xFF64748B)};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: s['bg'] as Color, borderRadius: BorderRadius.circular(20)),
      child: Text(s['label'] as String,
          style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: s['fg'] as Color, letterSpacing: 0.4)),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyCard({required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 10),
          Text(message,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          Text(sub,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFFCBD5E1), height: 1.4)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Color(0xFFCBD5E1), size: 40),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
