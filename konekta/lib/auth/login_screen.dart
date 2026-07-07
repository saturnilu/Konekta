import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../core/app_scope.dart';
import 'register_screen.dart';
import '../main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;

  void _login() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
      return;
    }
    final scope = AppScope.of(context);
    final api = scope.api;
    final session = scope.session;
    setState(() => _loading = true);
    try {
      final res = await api.post('/auth/login', {'email': email, 'password': password}, auth: false);
      final resMap = Map<String, dynamic>.from(res as Map);
      final userMap = Map<String, dynamic>.from(resMap['user'] as Map);
      await session.save(
        token: (resMap['token'] ?? '') as String,
        role: (userMap['role'] ?? 'influencer') as String,
        userId: (userMap['id'] is num) ? (userMap['id'] as num).toInt() : int.tryParse('${userMap['id']}') ?? 0,
        name: (userMap['name'] ?? '') as String,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainScreen()), (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Login dengan Google (fully automatic, no manual copy-paste).
  /// Alur: `google_sign_in` membuka native Google account picker di device ->
  /// user pilih akun -> dapat `idToken` -> POST ke backend
  /// `/auth/google/idtoken` -> backend verifikasi token & buat/ambil user
  /// -> dapat {token, user} -> simpan session & navigate ke MainScreen.
  Future<void> _loginWithGoogle() async {
    final scope = AppScope.of(context);
    final api = scope.api;
    final session = scope.session;

    setState(() => _googleLoading = true);
    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: '1087118947875-7fb8pd3jeo37nna5tfv4bpi9n4gngecl.apps.googleusercontent.com',
      );

      // 1) Buka native Google account picker.
      final account = await googleSignIn.signIn();
      if (account == null) return;

      // 2) Ambil auth details (idToken).
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google idToken not available');
      }

      // 3) Kirim idToken ke backend untuk verifikasi & login.
      final res = await api.post('/auth/google/idtoken', {'idToken': idToken}, auth: false);

      await session.save(
        token: res['token'] ?? '',
        role: res['user']?['role'] ?? 'influencer',
        userId: res['user']?['id'] ?? 0,
        name: res['user']?['name'] ?? account.displayName ?? '',
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 280,
            decoration: const BoxDecoration(gradient: KonektaGradients.primary),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                const Text('Konekta', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sign In', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: KonektaColors.textPrimary)),
                      const SizedBox(height: 4),
                      const Text('Welcome back', style: TextStyle(color: KonektaColors.textSecondary, fontSize: 14)),
                      const SizedBox(height: 24),
                      const Text('Email address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'name@company.com', prefixIcon: Icon(Icons.mail_outline_rounded, color: KonektaColors.primary)),
                      ),
                      const SizedBox(height: 16),
                      const Text('Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: KonektaColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: KonektaColors.textMuted),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GradientButton(
                        label: _loading ? 'Signing in...' : 'Sign in',
                        onPressed: _loading ? null : _login,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: (_loading || _googleLoading) ? null : _loginWithGoogle,
                          icon: _googleLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const _GoogleLogo(size: 20),
                          label: Text(_googleLoading ? 'Connecting...' : 'Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: KonektaColors.border),
                            foregroundColor: KonektaColors.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: KonektaColors.textMuted))), Expanded(child: Divider())]),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: const Text.rich(
                            TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(color: KonektaColors.textSecondary),
                              children: [TextSpan(text: 'Sign up', style: TextStyle(color: KonektaColors.primary, fontWeight: FontWeight.w700))],
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
        ],
      ),
    );
  }
}

/// Logo Google "G" 4-warna, digambar manual (tanpa asset) agar tidak menambah
/// dependency asset.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide;
    final c = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.18
      ..color = const Color(0xFF4285F4);

    final rect = Rect.fromCircle(center: c, radius: r * 0.42);
    canvas.drawArc(rect, -1.5708, 1.5708, false, paint..color = const Color(0xFFEA4335));
    canvas.drawArc(rect, 0, 1.5708, false, paint..color = const Color(0xFFFBBC05));
    canvas.drawArc(rect, 1.5708, 1.5708, false, paint..color = const Color(0xFF34A853));
    canvas.drawArc(rect, 3.1416, 1.5708, false, paint..color = const Color(0xFF4285F4));

    // Batang horizontal "G"
    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - r * 0.09, r * 0.42, r * 0.18),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
