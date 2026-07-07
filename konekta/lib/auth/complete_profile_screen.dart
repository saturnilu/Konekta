import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/app_scope.dart';
import '../core/widgets.dart';
import '../data/models/influencer.dart';
import '../main_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String role;
  const CompleteProfileScreen({super.key, required this.role});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _tiktokController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyWebsiteController = TextEditingController();

  String _selectedIndustry = '';
  final List<String> _industries = ['Fashion', 'Beauty', 'F&B', 'Tech', 'Tech & Gadgets', 'Lifestyle', 'Travel', 'Others'];

  bool _loading = true;
  bool _saving = false;
  String? _error;
  InfluencerProfile? _profile;

  bool get _isInfluencer => widget.role == 'influencer';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  bool _initialized = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _industryController.dispose();
    _tiktokController.dispose();
    _instagramController.dispose();
    _youtubeController.dispose();
    _companyNameController.dispose();
    _companyWebsiteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final scope = AppScope.of(context);
      final p = await scope.profileRepo.me();
      _hydrate(p);
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load profile: $e';
        _loading = false;
      });
    }
  }

  void _hydrate(InfluencerProfile p) {
    _usernameController.text = p.username ?? '';
    _nameController.text = '';
    _bioController.text = p.bio ?? '';
    _industryController.text = p.industry ?? '';
    _tiktokController.text = p.tiktokAccount ?? '';
    _instagramController.text = p.instagramHandle ?? '';
    _youtubeController.text = p.youtubeHandle ?? '';
    // For brand: username field holds brand_name (via fromJson fallback)
    _companyNameController.text = p.username ?? '';
    if (p.industry != null && p.industry!.isNotEmpty && _industries.contains(p.industry)) {
      _selectedIndustry = p.industry!;
    } else if (p.industry != null && p.industry!.isNotEmpty) {
      _selectedIndustry = 'Others';
      _industryController.text = p.industry!;
    } else {
      _selectedIndustry = '';
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final industry = _selectedIndustry == 'Others'
          ? _industryController.text.trim()
          : _selectedIndustry;

      final patch = <String, dynamic>{
        if (_isInfluencer) ...{
          'username': _usernameController.text.trim(),
          'bio': _bioController.text.trim(),
          'industry': industry,
          'tiktok_account': _tiktokController.text.trim(),
          'instagram_handle': _instagramController.text.trim(),
          'youtube_handle': _youtubeController.text.trim(),
        } else ...{
          'brand_name': _companyNameController.text.trim(),
          'website': _companyWebsiteController.text.trim(),
          'industry': industry,
          'description': _bioController.text.trim(),
        },
      };

      final updated = await scope.profileRepo.updateMe(patch);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _saving = false;
      });
      messenger.showSnackBar(const SnackBar(content: Text('Profile saved')));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to save profile: $e';
        _saving = false;
      });
    }
  }

  Future<void> _addSocial() async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final platform = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text('Choose platform', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            ListTile(
              leading: const Icon(Icons.music_video_rounded),
              title: const Text('TikTok'),
              onTap: () => Navigator.of(ctx).pop('tiktok'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Instagram'),
              onTap: () => Navigator.of(ctx).pop('instagram'),
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_fill_rounded),
              title: const Text('YouTube'),
              onTap: () => Navigator.of(ctx).pop('youtube'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (platform == null || !mounted) return;
    final handle = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: Text('Add ${platform[0].toUpperCase()}${platform.substring(1)} handle'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'username'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('Add')),
          ],
        );
      },
    );
    if (handle == null || handle.isEmpty || !mounted) return;
    try {
      await scope.profileRepo.addSocialMedia(platform: platform, handle: handle);
      if (!mounted) return;
      final p = await scope.profileRepo.me();
      if (!mounted) return;
      setState(() => _profile = p);
      messenger.showSnackBar(const SnackBar(content: Text('Social account added')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: ${e.message}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    final isInfluencer = _isInfluencer;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3EA3EC), Color(0xFF2676D0)],
          stops: [0.0, 0.4],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              isInfluencer ? 'Complete your creator\nprofile' : 'Complete your brand\nprofile',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Brands match faster with a complete profile.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8E8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFE5484D)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(color: Color(0xFFB81F23), fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (isInfluencer) ..._buildInfluencerFields() else ..._buildBrandFields(),
                    const SizedBox(height: 24),
                    if (isInfluencer) _buildSocialAccounts(),
                    const SizedBox(height: 40),
                    GradientButton(
                      label: _saving ? 'Saving...' : 'Continue',
                      onPressed: _saving ? null : _save,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInfluencerFields() {
    return [
      _buildInputLabel('Username'),
      _buildTextField(
        controller: _usernameController,
        hintText: 'username',
      ),
      const SizedBox(height: 16),
      _buildInputLabel('TikTok account'),
      _buildTextField(
        controller: _tiktokController,
        hintText: 'tiktok.com/@username',
      ),
      const SizedBox(height: 16),
      _buildInputLabel('Instagram handle'),
      _buildTextField(
        controller: _instagramController,
        hintText: 'instagram.com/username',
      ),
      const SizedBox(height: 16),
      _buildInputLabel('YouTube handle'),
      _buildTextField(
        controller: _youtubeController,
        hintText: 'youtube.com/@channel',
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInputLabel('Bio'),
          Text(
            '${_bioController.text.length}/150',
            style: const TextStyle(color: Colors.black38, fontSize: 12),
          ),
        ],
      ),
      _buildTextField(
        controller: _bioController,
        hintText: 'Short bio about your content',
        maxLines: 4,
        onChanged: (_) => setState(() {}),
        maxLength: 150,
      ),
      const SizedBox(height: 16),
      _buildInputLabel('Industry'),
      const SizedBox(height: 8),
      _buildIndustryChips(),
      if (_selectedIndustry == 'Others') ...[
        const SizedBox(height: 12),
        TextField(
          controller: _industryController,
          decoration: const InputDecoration(
            hintText: 'Type your industry here',
            hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black54),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF3EA3EC)),
            ),
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildBrandFields() {
    return [
      _buildInputLabel('Company name'),
      _buildTextField(
        controller: _companyNameController,
        hintText: 'Your brand name',
      ),
      const SizedBox(height: 16),
      _buildInputLabel('Company website'),
      _buildTextField(
        controller: _companyWebsiteController,
        hintText: 'https://example.com',
      ),
      const SizedBox(height: 16),
      _buildInputLabel('Industry'),
      const SizedBox(height: 8),
      _buildIndustryChips(),
      if (_selectedIndustry == 'Others') ...[
        const SizedBox(height: 12),
        TextField(
          controller: _industryController,
          decoration: const InputDecoration(
            hintText: 'Type your industry here',
            hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black54),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF3EA3EC)),
            ),
          ),
        ),
      ],
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInputLabel('About the brand'),
          Text(
            '${_bioController.text.length}/150',
            style: const TextStyle(color: Colors.black38, fontSize: 12),
          ),
        ],
      ),
      _buildTextField(
        controller: _bioController,
        hintText: 'Tell influencers about your brand',
        maxLines: 4,
        onChanged: (_) => setState(() {}),
        maxLength: 150,
      ),
    ];
  }

  Widget _buildIndustryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _industries.map((industry) {
        final isSelected = _selectedIndustry == industry;
        return GestureDetector(
          onTap: () => setState(() => _selectedIndustry = industry),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3EA3EC) : const Color(0xFFE8F1F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              industry,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF7CA1C1),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSocialAccounts() {
    final socials = _profile?.socialMedia ?? const <SocialMedia>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInputLabel('Social media accounts'),
            TextButton.icon(
              onPressed: _addSocial,
              icon: const Icon(Icons.add, size: 16, color: Color(0xFF3EA3EC)),
              label: const Text('Add', style: TextStyle(color: Color(0xFF3EA3EC))),
            ),
          ],
        ),
        if (socials.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF2F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No social accounts linked yet. Add TikTok, Instagram, or YouTube.',
              style: TextStyle(color: Color(0xFF7CA1C1), fontSize: 13),
            ),
          )
        else
          ...socials.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF2F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(_iconFor(s.platform), color: const Color(0xFF3EA3EC), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${s.platform[0].toUpperCase()}${s.platform.substring(1)}: ${s.handle}',
                        style: const TextStyle(color: Color(0xFF0E1B33), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  IconData _iconFor(String platform) {
    switch (platform.toLowerCase()) {
      case 'tiktok':
        return Icons.music_video_rounded;
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'youtube':
        return Icons.play_circle_fill_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    int? maxLength,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEBF2F8),
        borderRadius: BorderRadius.circular(maxLines > 1 ? 16 : 24),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        onChanged: onChanged,
        decoration: InputDecoration(
          counterText: '',
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF9CB1C9),
            fontSize: 15,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
