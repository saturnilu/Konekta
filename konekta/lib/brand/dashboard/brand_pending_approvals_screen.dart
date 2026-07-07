import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../data/models/campaign.dart';
import '../../data/repositories/campaign_repository.dart';
import 'brand_active_room_screen.dart';

class BrandPendingApprovalsScreen extends StatefulWidget {
  const BrandPendingApprovalsScreen({super.key});

  @override
  State<BrandPendingApprovalsScreen> createState() => _BrandPendingApprovalsScreenState();
}

class _BrandPendingApprovalsScreenState extends State<BrandPendingApprovalsScreen> {
  static const _blue = Color(0xFF3B82F6);
  static const _bg = Color(0xFFEDF4FC);

  bool _loading = true;
  String? _error;

  // Map of offerId -> list of pending applicants
  List<_OfferWithApplicants> _offers = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final scope = AppScope.of(context);
      final repo = CampaignRepository(scope.api);

      // Use /offers/mine which is properly authenticated for brand role
      final res = await scope.api.get('/offers/mine');
      final campaigns = (res as List)
          .whereType<Map>()
          .map((e) => Campaign.fromJson(e.cast<String, dynamic>()))
          .where((c) => !c.isCompletedStatus)
          .toList();

      // Fetch applicants for each campaign concurrently
      final results = await Future.wait(
        campaigns.map((c) async {
          try {
            final applicants = await repo.listApplicants(c.id);
            final pending = applicants.where((a) => a.status == 'pending').toList();
            return _OfferWithApplicants(campaign: c, applicants: pending);
          } catch (_) {
            return _OfferWithApplicants(campaign: c, applicants: []);
          }
        }),
      );

      if (!mounted) return;
      // Only keep offers that actually have pending applicants
      final withPending = results.where((o) => o.applicants.isNotEmpty).toList();
      setState(() {
        _offers = withPending;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _setStatus(Campaign campaign, Applicant applicant, String status) async {
    try {
      final scope = AppScope.of(context);
      final repo = CampaignRepository(scope.api);
      await repo.setApplicantStatus(campaign.id, applicant.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'approved' ? '${applicant.name} approved!' : '${applicant.name} rejected'),
          backgroundColor: status == 'approved' ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  int get _totalPending => _offers.fold(0, (sum, o) => sum + o.applicants.length);

  @override
  Widget build(BuildContext context) {
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
          'Pending Approvals',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
        ),
        actions: [
          if (!_loading && _totalPending > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(20)),
              child: Text(
                '$_totalPending pending',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFFD97706)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : _error != null
              ? _ErrorBlock(message: _error!, onRetry: _load)
              : _offers.isEmpty
                  ? _EmptyBlock()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        itemCount: _offers.length,
                        itemBuilder: (context, i) {
                          final o = _offers[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _OfferSection(
                              offer: o,
                              onTapCampaign: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => BrandActiveRoomScreen(campaign: o.campaign)),
                              ),
                              onApprove: (a) => _setStatus(o.campaign, a, 'approved'),
                              onReject: (a) => _setStatus(o.campaign, a, 'rejected'),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _OfferWithApplicants {
  final Campaign campaign;
  final List<Applicant> applicants;
  const _OfferWithApplicants({required this.campaign, required this.applicants});
}

// ── Offer section with its pending applicants ─────────────────────────────────

class _OfferSection extends StatelessWidget {
  final _OfferWithApplicants offer;
  final VoidCallback onTapCampaign;
  final void Function(Applicant) onApprove;
  final void Function(Applicant) onReject;

  const _OfferSection({
    required this.offer,
    required this.onTapCampaign,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final c = offer.campaign;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campaign header row
        InkWell(
          onTap: onTapCampaign,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.campaign_rounded, size: 18, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E40AF),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '${offer.applicants.length} pending',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFD97706)),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 16, color: Color(0xFF3B82F6)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Applicant cards
        ...offer.applicants.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PendingApplicantCard(
                applicant: a,
                onApprove: () => onApprove(a),
                onReject: () => onReject(a),
              ),
            )),
      ],
    );
  }
}

// ── Applicant card ─────────────────────────────────────────────────────────────

class _PendingApplicantCard extends StatelessWidget {
  final Applicant applicant;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _PendingApplicantCard({required this.applicant, required this.onApprove, required this.onReject});

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
            ],
          ),
          if ((a.niche ?? '').isNotEmpty || a.followersCount != null || a.engagementRate != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if ((a.niche ?? '').isNotEmpty) _Chip(icon: Icons.tag_rounded, label: a.niche!),
                if (a.followersCount != null)
                  _Chip(icon: Icons.people_outline, label: '${Format.compact(a.followersCount!)} followers'),
                if (a.engagementRate != null)
                  _Chip(icon: Icons.trending_up_rounded, label: '${a.engagementRate!.toStringAsFixed(1)}% eng.'),
              ],
            ),
          ],
          if ((a.message ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
              child: Text(
                '"${a.message}"',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: const Color(0xFF64748B), fontStyle: FontStyle.italic, height: 1.4,
                ),
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

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  const _Avatar({required this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(radius: 22, backgroundImage: NetworkImage(avatarUrl!));
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF3B82F6), fontSize: 16),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

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

class _EmptyBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_turned_in_outlined, size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              'No pending approvals',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 6),
            Text(
              'Influencer applications awaiting review will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFFCBD5E1)),
            ),
          ],
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
