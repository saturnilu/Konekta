class AppUser {
  final int id;
  final String name;
  final String? email;
  final String? role;
  final String? avatarUrl;
  final String? username;
  final String? bio;
  final String? industry;
  final String? tiktokAccount;
  final String? instagramHandle;
  final String? youtubeHandle;
  final String? companyName;
  final String? companyWebsite;
  final String? description;
  final List<Map<String, dynamic>> socialMedia;

  AppUser({
    required this.id,
    required this.name,
    this.email,
    this.role,
    this.avatarUrl,
    this.username,
    this.bio,
    this.industry,
    this.tiktokAccount,
    this.instagramHandle,
    this.youtubeHandle,
    this.companyName,
    this.companyWebsite,
    this.description,
    this.socialMedia = const [],
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final rawSocials = json['social_media'] ?? json['socials'];
    final list = rawSocials is List
        ? rawSocials
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : const <Map<String, dynamic>>[];
    return AppUser(
      id: (json['id'] ?? json['user_id'] ?? 0) as int,
      name: (json['name'] ?? json['username'] ?? '') as String,
      email: json['email'] as String?,
      role: json['role'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      username: (json['username'] as String?) ?? (json['handle'] as String?),
      bio: (json['bio'] as String?) ?? (json['description'] as String?),
      industry: json['industry'] as String?,
      tiktokAccount: (json['tiktok_account'] as String?) ?? (json['tiktok'] as String?),
      instagramHandle: (json['instagram_handle'] as String?) ?? (json['instagram'] as String?),
      youtubeHandle: (json['youtube_handle'] as String?) ?? (json['youtube'] as String?),
      companyName: (json['company_name'] as String?) ?? (json['brand_name'] as String?),
      companyWebsite: (json['company_website'] as String?) ?? (json['website'] as String?),
      description: json['description'] as String?,
      socialMedia: list,
    );
  }
}
