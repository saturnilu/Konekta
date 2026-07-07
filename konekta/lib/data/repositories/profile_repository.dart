import '../../core/api_client.dart';
import '../models/influencer.dart';
import '../models/user.dart';

class ProfileRepository {
  final ApiClient api;
  ProfileRepository(this.api);

  /// Fetch the current user's profile. The backend returns a nested
  /// { user, profile, social_media? } shape. We flatten it so that
  /// [InfluencerProfile.fromJson] can parse it correctly regardless of role.
  Future<InfluencerProfile> me() async {
    final data = await api.get('/profile/me');
    return InfluencerProfile.fromJson(_flatten(data));
  }

  Future<InfluencerProfile> updateMe(Map<String, dynamic> patch) async {
    final data = await api.put('/profile/me', patch);
    return InfluencerProfile.fromJson(_flatten(data));
  }

  /// Flattens the nested { user, profile, social_media? } backend response
  /// into a single map that [InfluencerProfile.fromJson] can consume.
  Map<String, dynamic> _flatten(dynamic data) {
    final map = Map<String, dynamic>.from(data as Map);
    // If already flat (no 'user' key), return as-is
    if (!map.containsKey('user')) return map;
    final user = Map<String, dynamic>.from(map['user'] as Map? ?? {});
    final profile = Map<String, dynamic>.from(map['profile'] as Map? ?? {});
    final social = map['social_media'] as List?;
    return {
      ...user,
      ...profile,
      if (social != null) 'social_media': social,
    };
  }

  /// Add a social media account to the current influencer's profile.
  Future<SocialMedia> addSocialMedia({required String platform, required String handle, String? url}) async {
    final data = await api.post('/profile/influencer/social-media', {
      'platform': platform,
      'handle': handle,
      if (url != null && url.isNotEmpty) 'url': url,
    });
    return SocialMedia.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Return the basic user row, useful for non-influencer views.
  Future<AppUser> user() async {
    final data = await api.get('/profile/me');
    return AppUser.fromJson(_flatten(data));
  }
}
