import 'package:flutter/material.dart';

import '../services/download_service.dart';
import '../services/settings_service.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7));
  late final Animation<double> _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final settingsService = SettingsService();
    final downloadService = DownloadService();

    // Cleanup orphaned temp preview files from previous sessions, per
    // spec section 35.
    final cleanup = downloadService.cleanupOrphanedTempFiles();
    final minSplash = Future.delayed(const Duration(milliseconds: 1400));
    final onboardingDone = settingsService.isOnboardingComplete();

    final results = await Future.wait([cleanup, minSplash, onboardingDone]);
    final isOnboardingComplete = results[2] as bool;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            isOnboardingComplete ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [scheme.primary, scheme.tertiary],
                    ),
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'All Video Downloader',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
