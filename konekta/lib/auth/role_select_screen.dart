import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../core/app_scope.dart';
import 'complete_profile_screen.dart';

class RoleSelectScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  const RoleSelectScreen({super.key, required this.name, required this.email, required this.password});
  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  String _role = 'influencer';
  bool _loading = false;

  void _signUp() async {
    final scope = AppScope.of(context);
    final api = scope.api;
    final session = scope.session;
    setState(() => _loading = true);
    try {
      final res = await api.post('/auth/register', {
        'name': widget.name,
        'email': widget.email,
        'password': widget.password,
        'role': _role,
      }, auth: false);
      final resMap = Map<String, dynamic>.from(res as Map);
      final userMap = Map<String, dynamic>.from(resMap['user'] as Map);
      await session.save(
        token: (resMap['token'] ?? '') as String,
        role: (userMap['role'] ?? _role) as String,
        userId: (userMap['id'] is num) ? (userMap['id'] as num).toInt() : int.tryParse('${userMap['id']}') ?? 0,
        name: (userMap['name'] ?? widget.name) as String,
      );
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CompleteProfileScreen(role: _role)));
    } catch (e) {
      if (!mounted) return;
      // Pop back to register screen so user can fix their input
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign up failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _roleCard({required String value, required IconData icon, required String title, required String desc, required String cta}) {
    final selected = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? KonektaColors.primary : KonektaColors.border, width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: const Color(0xFFEFF5FF), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: KonektaColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
              ],
            ),
            const SizedBox(height: 10),
            Text(desc, style: const TextStyle(color: KonektaColors.textSecondary, fontSize: 13, height: 1.4)),
            const SizedBox(height: 10),
            Row(children: [Text(cta, style: const TextStyle(color: KonektaColors.primary, fontWeight: FontWeight.w700, fontSize: 13)), const SizedBox(width: 4), const Icon(Icons.arrow_forward_rounded, color: KonektaColors.primary, size: 16)]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: KonektaColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KonektaColors.border),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: KonektaColors.textPrimary),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'How are you planning\nto use Konekta?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: KonektaColors.textPrimary, height: 1.2),
              ),
              const SizedBox(height: 24),
              _roleCard(
                value: 'influencer',
                icon: Icons.diversity_3_rounded,
                title: "I'm an Influencer",
                desc: 'Connect with premium brands, manage your campaigns, and scale your influence with advanced analytics.',
                cta: 'Continue as Influencer',
              ),
              const SizedBox(height: 18),
              const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: KonektaColors.textMuted))), Expanded(child: Divider())]),
              const SizedBox(height: 18),
              _roleCard(
                value: 'brand',
                icon: Icons.storefront_rounded,
                title: "I'm a Brand",
                desc: 'Discover authentic creators, launch high-impact campaigns, and track performance in real-time.',
                cta: 'Continue as Brand',
              ),
              const Spacer(),
              GradientButton(label: _loading ? 'Signing up...' : 'Sign up', onPressed: _loading ? null : _signUp),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'You can always change your role later\nin account settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: KonektaColors.textMuted, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
