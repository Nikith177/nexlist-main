import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceMuted = onSurface.withValues(alpha: 0.68);
    final logoAsset = isDark
        ? 'assets/branding/nexlist_logo_dark.png'
        : 'assets/branding/nexlist_logo.png';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SizedBox(
          width: 220,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(logoAsset, width: 140),
              const SizedBox(height: 8),
              Text(
                'Campus Marketplace',
                style: TextStyle(fontSize: 14, color: onSurfaceMuted),
              ),
              const SizedBox(height: 20),
              Text(
                'Starting Nexlist...',
                style: TextStyle(
                  fontSize: 12,
                  color: onSurface.withValues(alpha: 0.54),
                ),
              ),
              const SizedBox(height: 6),
              ColoredBox(
                color: onSurface.withValues(alpha: 0.14),
                child: SizedBox(width: 120, height: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
