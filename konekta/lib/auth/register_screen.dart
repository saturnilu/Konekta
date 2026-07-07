import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'role_select_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  void _next() {
    if (_password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoleSelectScreen(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 240,
            decoration: const BoxDecoration(gradient: KonektaGradients.primary),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 18),
                const Text('Konekta', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Create your Konekta Account', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Full name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(hintText: 'Your name', prefixIcon: Icon(Icons.person_outline_rounded, color: KonektaColors.primary)),
                      ),
                      const SizedBox(height: 16),
                      const Text('Email address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'name@company.com', prefixIcon: Icon(Icons.mail_outline_rounded, color: KonektaColors.primary)),
                      ),
                      const SizedBox(height: 16),
                      const Text('Create password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _password,
                        obscureText: _obscure1,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: KonektaColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure1 ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: KonektaColors.textMuted),
                            onPressed: () => setState(() => _obscure1 = !_obscure1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Reenter your password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _confirm,
                        obscureText: _obscure2,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: KonektaColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure2 ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: KonektaColors.textMuted),
                            onPressed: () => setState(() => _obscure2 = !_obscure2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GradientButton(label: 'Next', onPressed: _next),
                      const SizedBox(height: 20),
                      const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: KonektaColors.textMuted))), Expanded(child: Divider())]),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                          child: const Text.rich(
                            TextSpan(
                              text: 'Already have account? ',
                              style: TextStyle(color: KonektaColors.textSecondary),
                              children: [TextSpan(text: 'Sign in', style: TextStyle(color: KonektaColors.primary, fontWeight: FontWeight.w700))],
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
