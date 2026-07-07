import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pc = PageController();
  int _idx = 0;

  final _pages = const [
    _PageData(
      icon: Icons.diversity_3_rounded,
      iconColor: Color(0xFF7FB8FF),
      gradient: KonektaGradients.pillBlue,
      title: 'Discover premium brands',
      desc: 'Find brands actively looking for creators like you. Build authentic partnerships in minutes.',
    ),
    _PageData(
      icon: Icons.task_alt_rounded,
      iconColor: Color(0xFF8EE3B7),
      gradient: KonektaGradients.success,
      title: 'Track every deliverable',
      desc: 'Track every deliverable, deadline, and milestone in one clean dashboard. Stay in control end-to-end.',
    ),
    _PageData(
      icon: Icons.account_balance_wallet_rounded,
      iconColor: Color(0xFFFFA86B),
      gradient: KonektaGradients.orange,
      title: 'Fast, transparent payouts',
      desc: 'Fast payouts, transparent metrics, and tools that help you scale. Your influence, professionally managed.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isLast = _idx == _pages.length - 1;
    final p = _pages[_idx];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: Text('Skip', style: TextStyle(color: KonektaColors.textMuted, fontWeight: FontWeight.w600)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _idx = i),
                  itemBuilder: (_, i) {
                    final pd = _pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 220, height: 220,
                          decoration: BoxDecoration(color: Color(0xFFF1F6FF), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(gradient: pd.gradient, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Icon(pd.icon, color: Colors.white, size: 48),
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          pd.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: KonektaColors.textPrimary),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            pd.desc,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, height: 1.5, color: KonektaColors.textSecondary),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = _idx == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: active ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: active ? KonektaColors.primary : const Color(0xFFCFD8E5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: isLast ? 'Get Started' : 'Next',
                icon: isLast ? Icons.arrow_forward_rounded : null,
                onPressed: () {
                  if (isLast) {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                  } else {
                    _pc.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text.rich(
                  TextSpan(text: 'New here? ', style: TextStyle(color: KonektaColors.textSecondary),
                      children: [TextSpan(text: 'Create Account', style: TextStyle(color: KonektaColors.primary, fontWeight: FontWeight.w700))]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageData {
  final IconData icon;
  final Color iconColor;
  final LinearGradient gradient;
  final String title;
  final String desc;
  const _PageData({required this.icon, required this.iconColor, required this.gradient, required this.title, required this.desc});
}
