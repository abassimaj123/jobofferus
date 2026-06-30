import 'package:flutter/material.dart';
import 'package:calcwise_core/calcwise_core.dart';
import '../core/theme/app_theme.dart';
import '../core/language/language_notifier.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => CalcwiseSplash(
        appName: 'Job Offer',
        appSuffix: 'US',
        tagline: isSpanishNotifier.value ? 'Compara ofertas con confianza' : 'Compare offers with confidence',
        chips: isSpanishNotifier.value
            ? const ['Salario neto', 'Beneficios', 'RSUs']
            : const ['Net Salary', 'Benefits', 'RSUs'],
        badgeSymbol: r'J$',
        badgeIcon: Icons.work_rounded,
        backgroundColor: AppTheme.primary,
        onComplete: () async {
          final done = await isOnboardingComplete('joboffer');
          if (!context.mounted) return;
          if (!done) {
            Navigator.of(context).pushReplacement(PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (_, __, ___) => const OnboardingScreen(),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
            ));
          } else {
            Navigator.of(context).pushReplacement(PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (_, __, ___) => const HomeScreen(),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
            ));
          }
        },
      );
}
