import '../../core/api_client.dart';
import '../models/campaign.dart';

class Applicant {
  final int id;
  final int influencerId;
  final String name;
  final String? username;
  final String? avatarUrl;
  final String? niche;
  final int? followersCount;
  final double? engagementRate;
  final String? message;
  final num? proposedRate;
  final String status;

  Applicant({
    required this.id,
    required this.influencerId,
    required this.name,
    this.username,
    this.avatarUrl,
    this.niche,
    this.followersCount,
    this.engagementRate,
    this.message,
    this.proposedRate,
    required this.status,
  });

  factory Applicant.fromJson(Map<String, dynamic> json) {
    num? _n(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(v.toString());
    }
    return Applicant(
      id: (_n(json['id']) ?? 0).toInt(),
      influencerId: (_n(json['influencer_id']) ?? 0).toInt(),
      name: (json['name'] ?? '') as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      niche: json['niche'] as String?,
      followersCount: _n(json['followers_count'])?.toInt(),
      engagementRate: _n(json['engagement_rate'])?.toDouble(),
      message: json['message'] as String?,
      proposedRate: _n(json['proposed_rate']),
      status: (json['status'] ?? 'pending') as String,
    );
  }
}

class CampaignRepository {
  final ApiClient api;
  CampaignRepository(this.api);

  /// Returns all campaigns the current influencer has applied to
  /// (includes approved/in_progress with correct progress & targets).
  Future<List<Campaign>> listMine() async {
    final data = await api.get('/offers/mine');
    final list = (data as List).cast<Map>();
    return list.map((e) => Campaign.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Campaign>> listOffers({
    String role = 'influencer',
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final data = await api.get('/offers', query: {
      'role': role,
      if (status != null && status.isNotEmpty) 'status': status,
      'page': page,
      'limit': limit,
    });
    final list = (data as List).cast<Map>();
    return list.map((e) => Campaign.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Campaign> offer(int id) async {
    final data = await api.get('/offers/$id');
    return Campaign.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Campaign> create(Map<String, dynamic> body) async {
    final data = await api.post('/offers', body);
    return Campaign.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<Applicant>> listApplicants(int offerId) async {
    final data = await api.get('/offers/$offerId/applicants');
    final list = (data as List).cast<Map>();
    return list.map((e) => Applicant.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> setApplicantStatus(int offerId, int appId, String status) async {
    await api.patch('/offers/$offerId/applicants/$appId/status', {'status': status});
  }

  Future<void> apply(int offerId, {String? message}) async {
    await api.post('/offers/$offerId/applicants', {
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }

  Future<VideoSubmitResult> submitVideo(int offerId, String videoUrl) async {
    final data = await api.post('/offers/$offerId/videos', {'video_url': videoUrl});
    return VideoSubmitResult.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<VideoListResult> listVideos(int offerId) async {
    final data = await api.get('/offers/$offerId/videos');
    return VideoListResult.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<VideoSubmitResult> refreshVideo(int offerId, int videoId) async {
    final data = await api.post('/offers/$offerId/videos/$videoId/refresh', {});
    return VideoSubmitResult.fromJson(Map<String, dynamic>.from(data as Map));
  }
}

// ── Result models ─────────────────────────────────────────────────────────────

class VideoStats {
  final int views;
  final int likes;
  final int shares;
  final String title;
  final String author;

  VideoStats({required this.views, required this.likes, required this.shares, required this.title, required this.author});

  factory VideoStats.fromJson(Map<String, dynamic> j) {
    num? n(dynamic v) => v == null ? null : v is num ? v : num.tryParse(v.toString());
    return VideoStats(
      views:  n(j['views'])?.toInt()  ?? 0,
      likes:  n(j['likes'])?.toInt()  ?? 0,
      shares: n(j['shares'])?.toInt() ?? 0,
      title:  j['title']  as String? ?? '',
      author: j['author'] as String? ?? '',
    );
  }
}

class VideoTotals {
  final int views;
  final int likes;
  final int shares;
  final int progress;

  VideoTotals({required this.views, required this.likes, required this.shares, required this.progress});

  factory VideoTotals.fromJson(Map<String, dynamic> j) {
    num? n(dynamic v) => v == null ? null : v is num ? v : num.tryParse(v.toString());
    return VideoTotals(
      views:    n(j['views']    ?? j['total_views'])?.toInt()  ?? 0,
      likes:    n(j['likes']    ?? j['total_likes'])?.toInt()  ?? 0,
      shares:   n(j['shares']   ?? j['total_shares'])?.toInt() ?? 0,
      progress: n(j['progress'])?.toInt() ?? 0,
    );
  }
}

class VideoTargets {
  final int views;
  final int likes;
  final int shares;

  VideoTargets({required this.views, required this.likes, required this.shares});

  factory VideoTargets.fromJson(Map<String, dynamic> j) {
    num? n(dynamic v) => v == null ? null : v is num ? v : num.tryParse(v.toString());
    return VideoTargets(
      views:  n(j['views'])?.toInt()  ?? 0,
      likes:  n(j['likes'])?.toInt()  ?? 0,
      shares: n(j['shares'])?.toInt() ?? 0,
    );
  }
}

class SubmittedVideo {
  final int id;
  final String videoUrl;
  final int viewsCount;
  final int likesCount;
  final int sharesCount;
  final String? fetchedAt;

  SubmittedVideo({required this.id, required this.videoUrl, required this.viewsCount, required this.likesCount, required this.sharesCount, this.fetchedAt});

  factory SubmittedVideo.fromJson(Map<String, dynamic> j) {
    num? n(dynamic v) => v == null ? null : v is num ? v : num.tryParse(v.toString());
    return SubmittedVideo(
      id:          n(j['id'])?.toInt() ?? 0,
      videoUrl:    j['video_url'] as String? ?? '',
      viewsCount:  n(j['views_count'])?.toInt()  ?? 0,
      likesCount:  n(j['likes_count'])?.toInt()  ?? 0,
      sharesCount: n(j['shares_count'])?.toInt() ?? 0,
      fetchedAt:   j['fetched_at'] as String?,
    );
  }
}

class VideoSubmitResult {
  final VideoStats stats;
  final VideoTotals totals;
  final int progress;

  VideoSubmitResult({required this.stats, required this.totals, required this.progress});

  factory VideoSubmitResult.fromJson(Map<String, dynamic> j) {
    num? n(dynamic v) => v == null ? null : v is num ? v : num.tryParse(v.toString());
    return VideoSubmitResult(
      stats:    VideoStats.fromJson(Map<String, dynamic>.from(j['stats'] as Map? ?? {})),
      totals:   VideoTotals.fromJson(Map<String, dynamic>.from(j['totals'] as Map? ?? {})),
      progress: n(j['progress'])?.toInt() ?? 0,
    );
  }
}

class VideoListResult {
  final List<SubmittedVideo> videos;
  final VideoTotals totals;
  final VideoTargets targets;

  VideoListResult({required this.videos, required this.totals, required this.targets});

  factory VideoListResult.fromJson(Map<String, dynamic> j) {
    final vList = (j['videos'] as List? ?? [])
        .whereType<Map>()
        .map((e) => SubmittedVideo.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return VideoListResult(
      videos:  vList,
      totals:  VideoTotals.fromJson(Map<String, dynamic>.from(j['totals'] as Map? ?? {})),
      targets: VideoTargets.fromJson(Map<String, dynamic>.from(j['targets'] as Map? ?? {})),
    );
  }
}
