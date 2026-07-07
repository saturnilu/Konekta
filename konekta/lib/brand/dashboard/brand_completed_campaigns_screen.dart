import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../data/models/campaign.dart';
import '../../data/repositories/campaign_repository.dart';
import 'brand_influencer_progress_screen.dart';

class BrandCompletedCampaignsScreen extends StatefulWidget {
  const BrandCompletedCampaignsScreen({super.key});

  @override
  State<BrandCompletedCampaignsScreen> createState() => _BrandCompletedCampaignsScreenState();
}

class _BrandCompletedCampaignsScreenState extends State<BrandCompletedCampaignsScreen> {
  static const _blue = Color(0xFF3B82F6);
  static const _bg = Color(0xFFEDF4FC);

  bool _loading = true;
  String? _error;
  // List of campaigns with their approved applicants
  List<_CampaignWithApplicants> _items = const [];

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

      // Fetch all brand campaigns
      final res = await scope.api.get('/offers/mine');
      final campaigns = (res as List)
          .whereType<Map>()
          .map((e) => Campaign.fromJson(e.cast<String, dynamic>()))
          .toList();

      // For each campaign, get approved/completed applicants
      final results = await Future.wait(
        campaigns.map((c) async {
          try {
            final applicants = await repo.listApplicants(c.id);
            final approved = applicants
                .where((a) => a.status == 'approved' || a.status == 'completed')
                .toList();
            return _CampaignWithApplicants(campaign: c, applicants: approved);
          } catch (_) {
            return _CampaignWithApplicants(campaign: c, applicants: []);
          }
        }),
      );

      if (!mounted) return;
      // Show campaigns that have at least one approved/completed influencer
      setState(() {
        _items = results.where((r) => r.applicants.isNotEmpty).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

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
          'Active Collaborations',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E293B)),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : _error != null
              ? _ErrorBlock(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? _EmptyBlock()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final item = _items[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _CampaignSection(
                              item: item,
                              onTapInfluencer: (applicant) {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => BrandInfluencerProgressScreen(
                                    offerId: item.campaign.id,
                                    influencerId: applicant.influencerId,
                                  ),
                                ));
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _CampaignWithApplicants {
  final Campaign campaign;
  final List<Applicant> applicants;
  const _CampaignWithApplicants({required this.campaign, required this.applicants});
}

// ── Campaign section ──────────────────────────────────────────────────────────

class _CampaignSection extends StatelessWidget {
  final _CampaignWithApplicants item;
  final void Function(Applicant) onTapInfluencer;
  const _CampaignSection({required this.item, required this.onTapInfluencer});

  @override
  Widget build(BuildContext context) {
    final c = item.campaign;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campaign header
        Container(
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E40AF)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: c.status == 'completed'
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '${item.applicants.length} influencer${item.applicants.length > 1 ? 's' : ''}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: c.status == 'completed'
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF3B82F6)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Influencer list
        ...item.applicants.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InfluencerCard(
                applicant: a,
                onTap: () => onTapInfluencer(a),
              ),
            )),
      ],
    );
  }
}

// ── Influencer card ───────────────────────────────────────────────────────────

class _InfluencerCard extends StatelessWidget {
  final Applicant applicant;
  final VoidCallback onTap;
  const _InfluencerCard({required this.applicant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = applicant;
    final isPaid = a.status == 'completed';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isPaid
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFE2E8F0),
              width: 1.2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              backgroundImage:
                  a.avatarUrl != null && a.avatarUrl!.isNotEmpty
                      ? NetworkImage(a.avatarUrl!)
                      : null,
              child: a.avatarUrl == null || a.avatarUrl!.isEmpty
                  ? Text(
                      a.name.isNotEmpty ? a.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3B82F6),
                          fontSize: 16))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.name,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B))),
                  if ((a.username ?? '').isNotEmpty)
                    Text('@${a.username}',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: const Color(0xFF64748B))),
                  if (a.followersCount != null)
                    Text(
                      '${Format.compact(a.followersCount!)} followers',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: const Color(0xFF94A3B8)),
                    ),
                ],
              ),
            ),
            if (isPaid)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 11, color: Color(0xFF16A34A)),
                    const SizedBox(width: 3),
                    Text('PAID',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF16A34A))),
                  ],
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8), size: 20),
          ],
        ),
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
            const Icon(Icons.people_outline_rounded,
                size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              'No approved influencers yet',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 6),
            Text(
              'Approved influencers from your campaigns will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: const Color(0xFFCBD5E1)),
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
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}