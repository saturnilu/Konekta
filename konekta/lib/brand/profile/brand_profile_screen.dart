import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../auth/login_screen.dart';
import '../../brand/subscription/subscription_screen.dart';

class BrandProfileScreen extends StatefulWidget {
  const BrandProfileScreen({super.key});

  @override
  State<BrandProfileScreen> createState() => _BrandProfileScreenState();
}

class _BrandProfileScreenState extends State<BrandProfileScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _subscription;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _industryCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _logoCtrl;
  String? _logoUrl;
  AppScope? _scope;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _industryCtrl = TextEditingController();
    _websiteCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _logoCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = AppScope.of(context);
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _industryCtrl.dispose();
    _websiteCtrl.dispose();
    _locationCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final scope = _scope;
    if (scope == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await scope.run(() async {
        Map<String, dynamic>? me;
        Map<String, dynamic>? sub;
        try {
          me = ((await scope.api.get('/profile/me')) as Map).cast<String, dynamic>();
        } catch (_) {
          me = null;
        }
        try {
          sub = ((await scope.api.get('/subscriptions/me')) as Map).cast<String, dynamic>();
        } catch (_) {
          sub = null;
        }
        return {'me': me, 'sub': sub};
      });
      if (!mounted) return;
      final me = results['me'] as Map<String, dynamic>?;
      final profile = (me?['profile'] as Map?)?.cast<String, dynamic>() ?? me ?? const {};
      _nameCtrl.text = (profile['brand_name'] ?? profile['name'] ?? '').toString();
      _descCtrl.text = (profile['description'] ?? '').toString();
      _industryCtrl.text = (profile['industry'] ?? '').toString();
      _websiteCtrl.text = (profile['website'] ?? '').toString();
      _locationCtrl.text = (profile['location'] ?? '').toString();
      _logoUrl = (profile['logo_url'] ?? profile['avatar_url'])?.toString();
      _logoCtrl.text = _logoUrl ?? '';
      setState(() {
        _profile = profile;
        _subscription = results['sub'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final scope = _scope;
    if (scope == null) return;
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'brand_name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'industry': _industryCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'logo_url': _logoCtrl.text.trim(),
      };
      await scope.run(() => scope.api.put('/profile/me', body));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openEdit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _EditProfileSheet(
          nameCtrl: _nameCtrl,
          descCtrl: _descCtrl,
          industryCtrl: _industryCtrl,
          websiteCtrl: _websiteCtrl,
          locationCtrl: _locationCtrl,
          logoCtrl: _logoCtrl,
          onSave: () {
            Navigator.of(ctx).pop();
            _save();
          },
          saving: _saving,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _scope?.session ?? AppScope.of(context).session;
    final fallback = (session.name ?? '').isNotEmpty ? session.name! : 'Brand Name';
    final brandName = _nameCtrl.text.isNotEmpty ? _nameCtrl.text : fallback;
    final description = _descCtrl.text.isNotEmpty
        ? _descCtrl.text
        : 'Tell brands and influencers about your company.';
    final initial = brandName.isNotEmpty ? brandName[0].toUpperCase() : 'B';

    return Scaffold(
      backgroundColor: const Color(0xFFEDF4FC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280))),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  )
                else ...[
                  // 1. Logo Brand
                  Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF82B1EF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: _logoUrl != null && _logoUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _logoUrl!,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Text(
                                  initial,
                                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                          : Text(
                              initial,
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Nama Brand & Deskripsi
                  Center(
                    child: Column(
                      children: [
                        Text(
                          brandName,
                          style: const TextStyle(color: Color(0xFF2D2353), fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color.fromARGB(255, 71, 67, 67), fontSize: 14, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 19),

                  // 3. Row Grid Statistik (3 Kolom)
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Campaigns', _profile?['campaigns_count']?.toString() ?? '0', Icons.emoji_events_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Total Reach', _formatReach(_profile?['total_reach']), Icons.trending_up_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Creators', _profile?['creators_hired']?.toString() ?? '0', Icons.people_alt_rounded)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. Bagian Billing & Subscription
                  _buildSectionHeader('Billing & Subscription'),
                  const SizedBox(height: 12),
                  _buildBillingCard(),
                  const SizedBox(height: 19),

                  // 5. Bagian Settings & Privacy
                  _buildSectionHeader('Settings & Privacy'),
                  const SizedBox(height: 12),
                  _buildSettingsMenu(context),
                  const SizedBox(height: 19),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatReach(dynamic v) {
    if (v == null) return '0';
    final n = v is num ? v : num.tryParse(v.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(color: Color(0xFF2D2353), fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFE3EFFD), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF4A90E2), size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingCard() {
    final sub = _subscription;
    String planName = 'Konekta Pro Plan';
    String status = 'Inactive';
    Color statusColor = const Color(0xFF6B7280);
    if (sub != null) {
      final plan = (sub['plan'] as Map?)?.cast<String, dynamic>();
      if (plan != null && plan['name'] != null) {
        planName = plan['name'].toString();
      } else if (sub['plan_name'] != null) {
        planName = sub['plan_name'].toString();
      }
      final s = (sub['status'] ?? '').toString().toLowerCase();
      if (s == 'active' || s == 'trialing') {
        status = 'Active';
        statusColor = const Color(0xFF059669);
      } else if (s == 'cancelled' || s == 'canceled' || s == 'expired') {
        status = 'Cancelled';
        statusColor = const Color(0xFFD02B49);
      } else if (s.isNotEmpty) {
        status = s[0].toUpperCase() + s.substring(1);
      }
    }
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      ),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFE3EFFD), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.account_balance_rounded, color: Color(0xFF4A90E2), size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planName,
                    style: const TextStyle(color: Color(0xFF2D2353), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFC7C7D4), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsMenu(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuTile(Icons.person_outline_rounded, 'Edit Profile', onTap: _openEdit),
          _buildDivider(),
          _buildMenuTile(Icons.lock_open_rounded, 'Security'),
          _buildDivider(),
          _buildMenuTile(Icons.notifications_none_rounded, 'Notifications'),
          _buildDivider(),
          _buildMenuTile(Icons.help_outline_rounded, 'Help Center'),
          _buildDivider(),
          _buildMenuTile(
            Icons.logout_rounded,
            'Log Out',
            textColor: const Color(0xFFD02B49),
            iconColor: const Color(0xFFD02B49),
            showArrow: false,
            onTap: () async {
              await AppScope.of(context).session.clear();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String title, {
    Color textColor = const Color(0xFF2D2353),
    Color iconColor = const Color(0xFF75749E),
    bool showArrow = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            if (showArrow)
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFC7C7D4), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      color: const Color(0xFFF3F3F8),
    );
  }
}

class _EditProfileSheet extends StatelessWidget {
  const _EditProfileSheet({
    required this.nameCtrl,
    required this.descCtrl,
    required this.industryCtrl,
    required this.websiteCtrl,
    required this.locationCtrl,
    required this.logoCtrl,
    required this.onSave,
    required this.saving,
  });

  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final TextEditingController industryCtrl;
  final TextEditingController websiteCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController logoCtrl;
  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E9F2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Edit Brand Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2353)),
            ),
            const SizedBox(height: 16),
            _field('Brand name', nameCtrl),
            const SizedBox(height: 12),
            _field('Description', descCtrl, maxLines: 3),
            const SizedBox(height: 12),
            _field('Industry', industryCtrl),
            const SizedBox(height: 12),
            _field('Website', websiteCtrl),
            const SizedBox(height: 12),
            _field('Location', locationCtrl),
            const SizedBox(height: 12),
            _field('Logo URL', logoCtrl),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF3F6FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
