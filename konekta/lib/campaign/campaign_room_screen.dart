import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/format.dart';
import '../core/app_scope.dart';
import '../data/models/campaign.dart';
import '../data/repositories/campaign_repository.dart';

class CampaignRoomScreen extends StatefulWidget {
  final Campaign campaign;
  const CampaignRoomScreen({super.key, required this.campaign});

  @override
  State<CampaignRoomScreen> createState() => _CampaignRoomScreenState();
}

class _CampaignRoomScreenState extends State<CampaignRoomScreen> {
  final List<TextEditingController> _controllers = [TextEditingController()];

  bool _loadingData = true;
  bool _submitting = false;
  String? _error;

  VideoListResult? _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loadingData = true; _error = null; });
    try {
      final scope = AppScope.of(context);
      final repo = CampaignRepository(scope.api);
      final result = await repo.listVideos(widget.campaign.id);
      if (!mounted) return;
      setState(() { _data = result; _loadingData = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loadingData = false; });
    }
  }

  void _addField() => setState(() => _controllers.add(TextEditingController()));

  Future<void> _submitOne(int index) async {
    final url = _controllers[index].text.trim();
    if (url.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final scope = AppScope.of(context);
      final repo = CampaignRepository(scope.api);
      final result = await repo.submitVideo(widget.campaign.id, url);
      if (!mounted) return;

      // Refresh the full list so totals update
      await _loadData();
      if (!mounted) return;

      _controllers[index].clear();

      final v = result.stats.views;
      final l = result.stats.likes;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          v > 0 || l > 0
              ? 'Video submitted! ${Format.compact(v)} views · ${Format.compact(l)} likes'
              : 'Video submitted! Stats will update once TikTok is reachable.',
        ),
        backgroundColor: const Color(0xFF22C55E),
        duration: const Duration(seconds: 4),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _refresh(int videoId) async {
    try {
      final scope = AppScope.of(context);
      final repo = CampaignRepository(scope.api);
      await repo.refreshVideo(widget.campaign.id, videoId);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stats refreshed'), backgroundColor: Color(0xFF3B82F6)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refresh failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.campaign;
    final daysLeft = c.daysLeft;

    // Use live data if loaded, else fallback to campaign model values
    final totals = _data?.totals;
    final targets = _data?.targets;
    final progress = totals?.progress ?? (c.progress ?? 0).toInt();
    final progressFraction = (progress / 100.0).clamp(0.0, 1.0);
    final totalViews  = totals?.views  ?? 0;
    final totalLikes  = totals?.likes  ?? 0;
    final targetViews = targets?.views ?? c.targetViews ?? 0;
    final targetLikes = targets?.likes ?? c.targetLikes ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFEDF4FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Campaign Room',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            onPressed: _loadingData ? null : _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ──────────────────────────────────────────────
              const Text(
                'ACTIVE CAMPAIGN',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF3B82F6), letterSpacing: 0.8),
              ),
              const SizedBox(height: 6),
              Text(
                c.title,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1.1),
              ),
              const SizedBox(height: 10),
              if (daysLeft != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: daysLeft <= 3 ? const Color(0xFFFFE4E4) : const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.alarm_rounded, size: 16,
                        color: daysLeft <= 3 ? const Color(0xFFDC2626) : const Color(0xFFEA580C)),
                      const SizedBox(width: 6),
                      Text(
                        daysLeft > 0 ? 'Deadline: $daysLeft Days Left' : daysLeft == 0 ? 'Due Today' : 'Deadline Passed',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: daysLeft <= 3 ? const Color(0xFFDC2626) : const Color(0xFFEA580C)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              const SizedBox(height: 20),

              // ── PROGRESS ────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: _loadingData
                    ? const Center(child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                      ))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Your Progress',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                              Text('$progress%',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF3B82F6))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progressFraction,
                              minHeight: 10,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _TargetStat(label: 'Total\nViews',  actual: totalViews,  target: targetViews)),
                              Container(width: 1, height: 50, color: const Color(0xFFE2E8F0)),
                              Expanded(child: _TargetStat(label: 'Total\nLikes',  actual: totalLikes,  target: targetLikes)),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              // ── SUBMITTED VIDEOS LIST ───────────────────────────────
              if (_data != null && _data!.videos.isNotEmpty) ...[
                const Text('Submitted Videos',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                const SizedBox(height: 10),
                ..._data!.videos.map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SubmittedVideoCard(video: v, onRefresh: () => _refresh(v.id)),
                )),
                const SizedBox(height: 6),
              ],

              // ── SUBMIT VIDEO FORM ───────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Submit your video',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                              SizedBox(height: 2),
                              Text('Paste your TikTok video link below',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_controllers.length, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _VideoLinkField(
                        controller: _controllers[i],
                        submitting: _submitting,
                        onSend: () => _submitOne(i),
                      ),
                    )),
                    const SizedBox(height: 4),

                    // Add another
                    GestureDetector(
                      onTap: _addField,
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        child: CustomPaint(
                          painter: _DashedBorderPainter(),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded, size: 18, color: Color(0xFF94A3B8)),
                                SizedBox(width: 6),
                                Text('Add another video',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                              ],
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
      ),
    );
  }
}

// ── Target stat ───────────────────────────────────────────────────────────────

class _TargetStat extends StatelessWidget {
  final String label;
  final int actual;
  final int target;
  const _TargetStat({required this.label, required this.actual, required this.target});

  @override
  Widget build(BuildContext context) {
    final pct = target > 0 ? (actual / target).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              children: [
                TextSpan(text: Format.compact(actual), style: const TextStyle(fontSize: 13)),
                TextSpan(
                  text: ' / ${Format.compact(target)}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
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
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Submitted video card ──────────────────────────────────────────────────────

class _SubmittedVideoCard extends StatelessWidget {
  final SubmittedVideo video;
  final VoidCallback onRefresh;
  const _SubmittedVideoCard({required this.video, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final short = video.videoUrl.length > 40
        ? '${video.videoUrl.substring(0, 40)}...'
        : video.videoUrl;
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
              const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF3B82F6), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(short,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
              ),
              GestureDetector(
                onTap: onRefresh,
                child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatPill(icon: Icons.visibility_rounded, value: Format.compact(video.viewsCount), color: const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _StatPill(icon: Icons.favorite_rounded,   value: Format.compact(video.likesCount),  color: const Color(0xFFE11D74)),
              const SizedBox(width: 8),
              _StatPill(icon: Icons.share_rounded,      value: Format.compact(video.sharesCount), color: const Color(0xFF22C55E)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _StatPill({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ── Video link input ──────────────────────────────────────────────────────────

class _VideoLinkField extends StatelessWidget {
  final TextEditingController controller;
  final bool submitting;
  final VoidCallback? onSend;
  const _VideoLinkField({required this.controller, required this.submitting, this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              decoration: const InputDecoration(
                hintText: 'https://www.tiktok.com/@c...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFFB0B8C4)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: submitting ? null : onSend,
            child: submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)))
                : const Icon(Icons.send_rounded, size: 20, color: Color(0xFF3B82F6)),
          ),
        ],
      ),
    );
  }
}

// ── Dashed border painter ─────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashSpace = 5.0;
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(14),
      ));

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter _) => false;
}
