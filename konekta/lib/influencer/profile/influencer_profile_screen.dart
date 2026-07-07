import 'package:flutter/material.dart';
import '../../auth/login_screen.dart';
import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../data/models/influencer.dart';
import '../../data/models/subscription.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/subscription_repository.dart';

class InfluencerProfileScreen extends StatefulWidget {
  const InfluencerProfileScreen({super.key});

  static const _avatarBg = Color(0xFFFFAEAE);
  static const _badgeBlue = Color(0xFF38B6FF);
  static const _textPrimary = Color(0xFF2D2353);
  static const _textMuted = Color(0xFF6B7280);
  static const _textLabel = Color(0xFF7A8B9E);
  static const _divider = Color(0xFFF3F4F6);
  static const _iconBlue = Color(0xFF1E75FF);
  static const _chevron = Color(0xFFB0B0D0);
  static const _danger = Color(0xFFDC2626);
  static const _bgScreen = Color(0xFFEFF5FA);

  @override
  State<InfluencerProfileScreen> createState() => _InfluencerProfileScreenState();
}

class _InfluencerProfileScreenState extends State<InfluencerProfileScreen> {
  bool _loading = true;
  String? _error;
  InfluencerProfile? _profile;
  UserSubscription? _subscription;
  AppScope? _scope;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = AppScope.of(context);
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  Future<void> _load() async {
    if (_scope == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ProfileRepository(_scope!.api);
      final profile = await _scope!.run<InfluencerProfile>(() => repo.me());
      UserSubscription? sub;
      try {
        sub = await _scope!.run<UserSubscription?>(() => SubscriptionRepository(_scope!.api).meDetailed());
      } catch (_) {
        sub = null;
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _subscription = sub;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _ProfileLoadingScaffold();
    }
    if (_error != null || _profile == null) {
      return Scaffold(
        backgroundColor: InfluencerProfileScreen._bgScreen,
        body: _ProfileErrorState(
          message: _error ?? 'Unknown error',
          onRetry: _load,
        ),
      );
    }
    final profile = _profile!;
    return _ProfileBody(
      profile: profile,
      subscription: _subscription,
      onEdit: () => _editProfile(profile),
      onAddSocial: () => _addSocial(profile),
      onRefresh: _load,
      onLogout: _logout,
    );
  }

  Future<void> _logout() async {
    final scope = AppScope.of(context);
    await scope.session.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _editProfile(InfluencerProfile current) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _EditProfileSheet(profile: current),
    );
    if (result == null) return;
    final scope = AppScope.of(context);
    try {
      final updated = await scope.run<InfluencerProfile>(
        () => ProfileRepository(scope.api).updateMe(result),
      );
      if (!mounted) return;
      setState(() => _profile = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _addSocial(InfluencerProfile current) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _AddSocialSheet(),
    );
    if (result == null) return;
    final scope = AppScope.of(context);
    try {
      await scope.run(
        () => ProfileRepository(scope.api).addSocialMedia(
          platform: result['platform'] as String,
          handle: result['handle'] as String,
          url: result['url'] as String?,
        ),
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Social account added')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add: $e')),
      );
    }
  }
}

// ---- BODY ----

class _ProfileBody extends StatelessWidget {
  final InfluencerProfile profile;
  final UserSubscription? subscription;
  final VoidCallback onEdit;
  final VoidCallback onAddSocial;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  const _ProfileBody({
    required this.profile,
    required this.subscription,
    required this.onEdit,
    required this.onAddSocial,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    final name = (profile.username ?? session.name ?? 'Creator').trim();
    final displayName = name.isEmpty ? 'Creator' : name;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final followers = profile.followersCount ?? 0;
    final engagement = profile.engagementRate ?? 0;
    final campaigns = 0; // Computed elsewhere; we leave it contextual per dashboard
    return Scaffold(
      backgroundColor: InfluencerProfileScreen._bgScreen,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: const BoxDecoration(
                              color: InfluencerProfileScreen._avatarBg,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: InfluencerProfileScreen._badgeBlue,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                              ),
                              child: const Icon(
                                Icons.verified_user_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: InfluencerProfileScreen._textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _bioOrDefault(profile.bio),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: InfluencerProfileScreen._textMuted, height: 1.4),
                      ),
                      if (profile.location != null && profile.location!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: InfluencerProfileScreen._textMuted),
                            const SizedBox(width: 4),
                            Text(
                              profile.location!,
                              style: const TextStyle(fontSize: 12, color: InfluencerProfileScreen._textMuted),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(icon: Icons.people_alt_outlined, label: 'Followers', value: Format.compact(followers)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.trending_up_rounded,
                        label: 'Engagement',
                        value: '${engagement.toStringAsFixed(1)}%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.emoji_events_outlined,
                        label: 'Campaigns',
                        value: campaigns.toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const _SectionTitle('Subscription'),
                const SizedBox(height: 12),
                _SubscriptionCard(subscription: subscription),
                const SizedBox(height: 28),
                const _SectionTitle('Social Accounts'),
                const SizedBox(height: 12),
                _SocialAccountsBlock(
                  profile: profile,
                  onAdd: onAddSocial,
                ),
                const SizedBox(height: 28),
                const _SectionTitle('Account'),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _SettingsItem(
                        icon: Icons.edit_rounded,
                        title: 'Edit Profile',
                        onTap: onEdit,
                      ),
                      const _SettingsItem(icon: Icons.lock_outline_rounded, title: 'Security'),
                      const _SettingsItem(icon: Icons.notifications_none_rounded, title: 'Notifications'),
                      const _SettingsItem(icon: Icons.help_outline_rounded, title: 'Help Center'),
                      _SettingsItem(
                        icon: Icons.logout_rounded,
                        title: 'Log Out',
                        iconColor: InfluencerProfileScreen._danger,
                        textColor: InfluencerProfileScreen._danger,
                        isLast: true,
                        onTap: onLogout,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _bioOrDefault(String? bio) {
    if (bio == null || bio.trim().isEmpty) {
      return 'Lifestyle creator. Always open to new collaborations.';
    }
    return bio;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Icon(icon, color: InfluencerProfileScreen._badgeBlue, size: 26),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: InfluencerProfileScreen._textLabel, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: InfluencerProfileScreen._textPrimary),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: InfluencerProfileScreen._textLabel),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final UserSubscription? subscription;
  const _SubscriptionCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final sub = subscription;
    final isActive = sub?.isActive ?? false;
    final plan = sub?.planName ?? 'Free Tier';
    final status = (sub?.status ?? 'inactive').toUpperCase();
    final color = isActive ? const Color(0xFF1FB76A) : const Color(0xFF7A8B9E);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2FA2EE), Color(0xFF408CFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? 'Active · $status'
                      : 'Upgrade to Pro for unlimited campaigns',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                ),
                if (sub?.expiresAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Renews ${Format.date(sub!.expiresAt)}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'ACTIVE' : 'FREE',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialAccountsBlock extends StatelessWidget {
  final InfluencerProfile profile;
  final VoidCallback onAdd;
  const _SocialAccountsBlock({required this.profile, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final items = <_SocialRow>[];
    if (profile.instagramHandle != null && profile.instagramHandle!.isNotEmpty) {
      items.add(_SocialRow(
        icon: Icons.camera_alt_rounded,
        color: const Color(0xFFE1306C),
        label: 'Instagram',
        handle: profile.instagramHandle!,
      ));
    }
    if (profile.tiktokAccount != null && profile.tiktokAccount!.isNotEmpty) {
      items.add(_SocialRow(
        icon: Icons.music_note_rounded,
        color: const Color(0xFF111111),
        label: 'TikTok',
        handle: profile.tiktokAccount!,
      ));
    }
    if (profile.youtubeHandle != null && profile.youtubeHandle!.isNotEmpty) {
      items.add(_SocialRow(
        icon: Icons.play_circle_outline_rounded,
        color: const Color(0xFFFF0000),
        label: 'YouTube',
        handle: profile.youtubeHandle!,
      ));
    }
    for (final s in profile.socialMedia) {
      items.add(_SocialRow(
        icon: _iconForPlatform(s.platform),
        color: const Color(0xFF1E75FF),
        label: s.platform,
        handle: s.handle,
      ));
    }
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'No social accounts linked yet',
                      style: TextStyle(color: InfluencerProfileScreen._textMuted, fontSize: 13),
                    ),
                  ),
                  TextButton(onPressed: onAdd, child: const Text('Add')),
                ],
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              return Column(
                children: [
                  _SocialRowTile(row: row, onAdd: onAdd),
                  if (i < items.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(left: 60, right: 20),
                      child: Divider(color: InfluencerProfileScreen._divider, thickness: 1, height: 1),
                    ),
                ],
              );
            }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 16, color: InfluencerProfileScreen._iconBlue),
              label: const Text(
                'Add social account',
                style: TextStyle(
                  color: InfluencerProfileScreen._iconBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'tiktok':
        return Icons.music_note_rounded;
      case 'youtube':
        return Icons.play_circle_outline_rounded;
      case 'twitter':
        return Icons.alternate_email_rounded;
      case 'facebook':
        return Icons.facebook_rounded;
      default:
        return Icons.link_rounded;
    }
  }
}

class _SocialRow {
  final IconData icon;
  final Color color;
  final String label;
  final String handle;
  _SocialRow({required this.icon, required this.color, required this.label, required this.handle});
}

class _SocialRowTile extends StatelessWidget {
  final _SocialRow row;
  final VoidCallback onAdd;
  const _SocialRowTile({required this.row, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: row.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(row.icon, color: row.color, size: 18),
      ),
      title: Text(
        row.label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: InfluencerProfileScreen._textPrimary),
      ),
      subtitle: Text(
        '@${row.handle}',
        style: const TextStyle(fontSize: 12, color: InfluencerProfileScreen._textLabel),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Color textColor;
  final bool isLast;
  final VoidCallback? onTap;
  const _SettingsItem({
    required this.icon,
    required this.title,
    this.iconColor = InfluencerProfileScreen._iconBlue,
    this.textColor = InfluencerProfileScreen._textPrimary,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Icon(icon, color: iconColor, size: 22),
          title: Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
          ),
          trailing: isLast
              ? null
              : const Icon(Icons.chevron_right_rounded, color: InfluencerProfileScreen._chevron, size: 20),
          onTap: onTap,
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.only(left: 60, right: 20),
            child: Divider(color: InfluencerProfileScreen._divider, thickness: 1, height: 1),
          ),
      ],
    );
  }
}

class _ProfileLoadingScaffold extends StatelessWidget {
  const _ProfileLoadingScaffold();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InfluencerProfileScreen._bgScreen,
      body: const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E75FF)),
      ),
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ProfileErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: Color(0xFFB0B8C4)),
            const SizedBox(height: 12),
            const Text('Could not load profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: InfluencerProfileScreen._textPrimary)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: InfluencerProfileScreen._textMuted)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E75FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- EDIT SHEET ----

class _EditProfileSheet extends StatefulWidget {
  final InfluencerProfile profile;
  const _EditProfileSheet({required this.profile});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _username;
  late final TextEditingController _bio;
  late final TextEditingController _niche;
  late final TextEditingController _industry;
  late final TextEditingController _location;
  late final TextEditingController _tiktok;
  late final TextEditingController _instagram;
  late final TextEditingController _youtube;
  late final TextEditingController _followers;
  late final TextEditingController _engagement;
  late final TextEditingController _rateCard;
  late final TextEditingController _mediaKit;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _username = TextEditingController(text: p.username ?? '');
    _bio = TextEditingController(text: p.bio ?? '');
    _niche = TextEditingController(text: p.niche ?? '');
    _industry = TextEditingController(text: p.industry ?? '');
    _location = TextEditingController(text: p.location ?? '');
    _tiktok = TextEditingController(text: p.tiktokAccount ?? '');
    _instagram = TextEditingController(text: p.instagramHandle ?? '');
    _youtube = TextEditingController(text: p.youtubeHandle ?? '');
    _followers = TextEditingController(text: (p.followersCount ?? 0).toString());
    _engagement = TextEditingController(text: (p.engagementRate ?? 0).toString());
    _rateCard = TextEditingController(text: p.rateCard?.toString() ?? '');
    _mediaKit = TextEditingController(text: p.mediaKitUrl ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _username, _bio, _niche, _industry, _location, _tiktok, _instagram, _youtube,
      _followers, _engagement, _rateCard, _mediaKit,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final patch = <String, dynamic>{
      if (_username.text.trim().isNotEmpty) 'username': _username.text.trim(),
      'bio': _bio.text.trim(),
      'niche': _niche.text.trim(),
      'industry': _industry.text.trim(),
      'location': _location.text.trim(),
      'tiktok_account': _tiktok.text.trim(),
      'instagram_handle': _instagram.text.trim(),
      'youtube_handle': _youtube.text.trim(),
    };
    final followers = int.tryParse(_followers.text.trim());
    if (followers != null) patch['followers_count'] = followers;
    final engagement = double.tryParse(_engagement.text.trim());
    if (engagement != null) patch['engagement_rate'] = engagement;
    final rate = double.tryParse(_rateCard.text.trim());
    if (rate != null) patch['rate_card'] = rate;
    if (_mediaKit.text.trim().isNotEmpty) patch['media_kit_url'] = _mediaKit.text.trim();
    Navigator.of(context).pop(patch);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E9F2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Edit Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: InfluencerProfileScreen._textPrimary)),
            const SizedBox(height: 14),
            _field('Username', _username),
            _field('Bio', _bio, maxLines: 3),
            _field('Niche', _niche),
            _field('Industry', _industry),
            _field('Location', _location),
            const SizedBox(height: 8),
            const Text('Social Handles',
                style: TextStyle(fontWeight: FontWeight.w700, color: InfluencerProfileScreen._textLabel)),
            const SizedBox(height: 8),
            _field('Instagram', _instagram),
            _field('TikTok', _tiktok),
            _field('YouTube', _youtube),
            const SizedBox(height: 8),
            const Text('Stats',
                style: TextStyle(fontWeight: FontWeight.w700, color: InfluencerProfileScreen._textLabel)),
            const SizedBox(height: 8),
            _field('Followers', _followers, keyboardType: TextInputType.number),
            _field('Engagement rate (%)', _engagement, keyboardType: TextInputType.number),
            _field('Rate card (IDR)', _rateCard, keyboardType: TextInputType.number),
            _field('Media kit URL', _mediaKit, keyboardType: TextInputType.url),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E75FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Save changes', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: InfluencerProfileScreen._textLabel)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: label,
              fillColor: const Color(0xFFEFF5FA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- ADD SOCIAL SHEET ----

class _AddSocialSheet extends StatefulWidget {
  const _AddSocialSheet();
  @override
  State<_AddSocialSheet> createState() => _AddSocialSheetState();
}

class _AddSocialSheetState extends State<_AddSocialSheet> {
  String _platform = 'Instagram';
  final TextEditingController _handle = TextEditingController();
  final TextEditingController _url = TextEditingController();

  @override
  void dispose() {
    _handle.dispose();
    _url.dispose();
    super.dispose();
  }

  void _save() {
    if (_handle.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Handle is required')),
      );
      return;
    }
    Navigator.of(context).pop({
      'platform': _platform,
      'handle': _handle.text.trim(),
      'url': _url.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final platforms = const ['Instagram', 'TikTok', 'YouTube', 'Twitter', 'Facebook', 'Other'];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: const Color(0xFFE3E9F2), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('Add Social Account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: InfluencerProfileScreen._textPrimary)),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _platform,
              items: platforms
                  .map((p) => DropdownMenuItem<String>(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _platform = v ?? 'Instagram'),
              decoration: const InputDecoration(labelText: 'Platform'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _handle,
              decoration: const InputDecoration(labelText: 'Handle (without @)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _url,
              decoration: const InputDecoration(labelText: 'Profile URL (optional)'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E75FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Add account', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
