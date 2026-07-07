// Safe parse helpers for MySQL DECIMAL/INT returned as String
num? _n(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}

int? _i(dynamic v) => _n(v)?.toInt();
double? _d(dynamic v) => _n(v)?.toDouble();

class SocialMedia {
  final int id;
  final String platform;
  final String handle;
  final String? url;

  SocialMedia({required this.id, required this.platform, required this.handle, this.url});

  factory SocialMedia.fromJson(Map<String, dynamic> json) {
    return SocialMedia(
      id: _i(json['id']) ?? 0,
      platform: (json['platform'] ?? '') as String,
      handle: (json['handle'] ?? json['username'] ?? '') as String,
      url: json['url'] as String?,
    );
  }
}

class InfluencerProfile {
  final int id;
  final int userId;
  final String? username;
  final String? bio;
  final String? niche;
  final String? industry;
  final String? location;
  final String? tiktokAccount;
  final String? instagramHandle;
  final String? youtubeHandle;
  final int? followersCount;
  final double? engagementRate;
  final num? rateCard;
  final String? mediaKitUrl;
  final String? avatarUrl;
  final List<SocialMedia> socialMedia;
  final int? completedCampaigns;
  final int? activeCampaigns;

  InfluencerProfile({
    required this.id,
    required this.userId,
    this.username,
    this.bio,
    this.niche,
    this.industry,
    this.location,
    this.tiktokAccount,
    this.instagramHandle,
    this.youtubeHandle,
    this.followersCount,
    this.engagementRate,
    this.rateCard,
    this.mediaKitUrl,
    this.avatarUrl,
    this.socialMedia = const [],
    this.completedCampaigns,
    this.activeCampaigns,
  });

  factory InfluencerProfile.fromJson(Map<String, dynamic> json) {
    final social = (json['social_media'] as List?)
            ?.map((e) => SocialMedia.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const <SocialMedia>[];
    return InfluencerProfile(
      id: _i(json['id'] ?? json['influencer_id']) ?? 0,
      userId: _i(json['user_id'] ?? json['id']) ?? 0,
      username: (json['username'] ?? json['brand_name']) as String?,
      bio: json['bio'] as String?,
      niche: json['niche'] as String?,
      industry: json['industry'] as String?,
      location: json['location'] as String?,
      tiktokAccount: json['tiktok_account'] as String?,
      instagramHandle: json['instagram_handle'] as String?,
      youtubeHandle: json['youtube_handle'] as String?,
      followersCount: _i(json['followers_count']),
      engagementRate: _d(json['engagement_rate']),
      rateCard: _n(json['rate_card']),
      mediaKitUrl: json['media_kit_url'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      socialMedia: social,
      completedCampaigns: _i(json['completed_campaigns']),
      activeCampaigns: _i(json['active_campaigns']),
    );
  }
}
