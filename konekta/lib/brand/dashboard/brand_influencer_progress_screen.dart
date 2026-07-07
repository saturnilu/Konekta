import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_scope.dart';
import '../../core/format.dart';

class BrandInfluencerProgressScreen extends StatefulWidget {
  final int offerId;
  final int influencerId;
  const BrandInfluencerProgressScreen({
    super.key,
    required this.offerId,
    required this.influencerId,
  });

  @override
  State<BrandInfluencerProgressScreen> createState() =>
      _BrandInfluencerProgressScreenState();
}

class _BrandInfluencerProgressScreenState
    extends State<BrandInfluencerProgressScreen> {
  static const _blue = Color(0xFF3B82F6);
  static const _bg = Color(0xFFEDF4FC);

  bool _loading = true;
  bool _paying = false;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final scope = AppScope.of(context);
      // First recalculate from submitted_videos to ensure fresh totals
      try {
        await scope.api.post(
          '/offers/${widget.offerId}/videos/brand/${widget.influencerId}/recalculate',
          {},
        );
      } catch (_) {
        // Non-fatal — still proceed to load the data
      }
      final res = await scope.api.get(
        '/offers/${widget.offerId}/videos/brand/${widget.influencerId}',
      );
      if (!mounted) return;
      setState(() {
        _data = (res as Map).cast<String, dynamic>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _pay() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confirm Payment',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: Text(
          'Are you sure you want to mark this influencer as paid? '
          'This action cannot be undone.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Pay Now',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _paying = true);
    try {
      final scope = AppScope.of(context);
      await scope.api.post(
        '/offers/${widget.offerId}/videos/brand/${widget.influencerId}/pay',
        {},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment recorded successfully!'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Influencer Progress',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
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
              : _buildContent(rupiah),
    );
  }

  Widget _buildContent(NumberFormat rupiah) {
    final d = _data!;
    final influencer = (d['influencer'] as Map).cast<String, dynamic>();
    final totals = (d['totals'] as Map).cast<String, dynamic>();
    final targets = (d['targets'] as Map).cast<String, dynamic>();
    final videos = (d['videos'] as List? ?? [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    final reward = d['reward'] is num ? (d['reward'] as num) : 0;
    final applicantStatus = d['applicant_status'] as String? ?? 'approved';
    final isPaid = applicantStatus == 'completed';

    final progress = (totals['progress'] as num? ?? 0).toInt();
    final totalViews = (totals['views'] as num? ?? 0).toInt();
    final totalLikes = (totals['likes'] as num? ?? 0).toInt();
    final targetViews = (targets['views'] as num? ?? 0).toInt();
    final targetLikes = (targets['likes'] as num? ?? 0).toInt();
    final targetReached = progress >= 100;

    final name = influencer['name'] as String? ?? 'Influencer';
    final username = influencer['username'] as String?;
    final avatarUrl = influencer['avatar_url'] as String?;
    final followers = (influencer['followers_count'] as num? ?? 0).toInt();

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── INFLUENCER CARD ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  _Avatar(name: name, avatarUrl: avatarUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B))),
                        if (username != null && username.isNotEmpty)
                          Text('@$username',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, color: const Color(0xFF64748B))),
                        Text(
                          '${Format.compact(followers)} followers',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  if (isPaid)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 12, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Text('PAID',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF16A34A))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── PROGRESS CARD ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Campaign Progress',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B))),
                      Text('$progress%',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: targetReached
                                  ? const Color(0xFF22C55E)
                                  : _blue)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (progress / 100.0).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation(
                          targetReached
                              ? const Color(0xFF22C55E)
                              : _blue),
                    ),
                  ),
                  if (targetReached) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded,
                              color: Color(0xFF16A34A), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Target reached! You can now pay the influencer.',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF16A34A),
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Views & Likes stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatColumn(
                          label: 'Total Views',
                          actual: totalViews,
                          target: targetViews,
                          icon: Icons.visibility_rounded,
                          color: _blue,
                        ),
                      ),
                      Container(width: 1, height: 60, color: const Color(0xFFE2E8F0)),
                      Expanded(
                        child: _StatColumn(
                          label: 'Total Likes',
                          actual: totalLikes,
                          target: targetLikes,
                          icon: Icons.favorite_rounded,
                          color: const Color(0xFFE11D74),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── SUBMITTED VIDEOS ──────────────────────────────────────
            Text('Submitted Videos',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B))),
            const SizedBox(height: 10),
            if (videos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    const Icon(Icons.video_library_outlined,
                        size: 36, color: Color(0xFFCBD5E1)),
                    const SizedBox(height: 8),
                    Text('No videos submitted yet',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else
              ...videos.map((v) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _VideoCard(video: v),
                  )),
            const SizedBox(height: 16),

            // ── REWARD & PAY BUTTON ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Reward per creator',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, color: const Color(0xFF64748B))),
                      Text(
                        rupiah.format(reward),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isPaid)
                    Container(
                      width: double.infinity,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF16A34A), size: 20),
                          const SizedBox(width: 8),
                          Text('Paid',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF16A34A))),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: targetReached
                              ? const LinearGradient(
                                  colors: [Color(0xFF4ADE80), Color(0xFF22C55E)])
                              : const LinearGradient(
                                  colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: (targetReached && !_paying) ? _pay : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: _paying
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Icon(Icons.payments_rounded,
                                  color: targetReached
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                  size: 20),
                          label: Text(
                            _paying
                                ? 'Processing...'
                                : targetReached
                                    ? 'Pay Influencer'
                                    : 'Target not reached yet',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: targetReached
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat column ───────────────────────────────────────────────────────────────

class _StatColumn extends StatelessWidget {
  final String label;
  final int actual;
  final int target;
  final IconData icon;
  final Color color;
  const _StatColumn({
    required this.label,
    required this.actual,
    required this.target,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = target > 0 ? (actual / target).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: const Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: Format.compact(actual),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B)),
                ),
                TextSpan(
                  text: ' / ${Format.compact(target)}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Video card ────────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final Map<String, dynamic> video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    final url = (video['video_url'] as String? ?? '');
    final short = url.length > 42 ? '${url.substring(0, 42)}...' : url;
    final views = (video['views_count'] as num? ?? 0).toInt();
    final likes = (video['likes_count'] as num? ?? 0).toInt();
    final shares = (video['shares_count'] as num? ?? 0).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_outline_rounded,
                  color: Color(0xFF3B82F6), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(short,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Pill(
                  icon: Icons.visibility_rounded,
                  value: Format.compact(views),
                  color: const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _Pill(
                  icon: Icons.favorite_rounded,
                  value: Format.compact(likes),
                  color: const Color(0xFFE11D74)),
              const SizedBox(width: 8),
              _Pill(
                  icon: Icons.share_rounded,
                  value: Format.compact(shares),
                  color: const Color(0xFF22C55E)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _Pill({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  const _Avatar({required this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(radius: 26, backgroundImage: NetworkImage(avatarUrl!));
    }
    return CircleAvatar(
      radius: 26,
      backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            fontWeight: FontWeight.w800, color: Color(0xFF3B82F6), fontSize: 18),
      ),
    );
  }
}

// ── Error / retry ─────────────────────────────────────────────────────────────

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
