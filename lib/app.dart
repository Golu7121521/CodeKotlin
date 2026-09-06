import 'package:flutter/material.dart';

import 'screens/root_shell.dart';
import 'theme/app_motion.dart';
import 'theme/app_theme.dart';

class MovieStreamApp extends StatelessWidget {
  const MovieStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = AppTheme.dark();
    return MaterialApp(
      title: 'MovieStream',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: AppPageTransitionsBuilder(),
            TargetPlatform.iOS: AppPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const RootShell(),
    );
  }
}

/// Custom page transitions builder applying the design system's motion
/// tokens (emphasized-decelerate curve, per the macro/hero-transition
/// spec) to standard Material page routes.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: AppMotion.emphasizedDecelerate);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
