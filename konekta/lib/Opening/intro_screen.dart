import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../Opening/splash_screen.dart';
import 'onboarding_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  @override
  void initState() {
    super.initState();
    // Already handled by splash screen navigation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 320,
            decoration: const BoxDecoration(gradient: KonektaGradients.primary),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(34)),
                    child: const Icon(Icons.link_rounded, color: Colors.white, size: 56),
                  ),
                  const SizedBox(height: 28),
                  const Text('Konekta', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  const Text('Where brands & creators connect', style: TextStyle(color: Colors.white70, fontSize: 15)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Where Brands and Creators\nconnect effortlessly', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: KonektaColors.textPrimary, height: 1.2)),
                  const SizedBox(height: 8),
                  const Text('Konekta is the smarter way for brands and creators to find, collaborate, and measure campaign performance in one place.', style: TextStyle(color: KonektaColors.textSecondary, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 20),
                  const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: KonektaColors.textMuted))), Expanded(child: Divider())]),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GradientButton(label: 'Sign in', onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => KonektaSplashScreen()))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GradientButton(label: 'Sign up', onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OnboardingScreen())), outlined: true, foreground: KonektaColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
