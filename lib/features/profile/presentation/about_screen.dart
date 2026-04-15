import 'package:flutter/material.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import 'about_iframe.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  void initState() {
    super.initState();
    if (isIframeAvailable) {
      registerLandingIframe();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'About',
                    style: AppTypography.h3.copyWith(color: colors.onSurface),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: Builder(builder: (context) {
                print('DEBUG: AboutScreen build triggered');
                print('DEBUG: isIframeAvailable = $isIframeAvailable');
                if (isIframeAvailable) {
                  print('DEBUG: Rendering iframe widget');
                  return const HtmlElementView(viewType: 'landing-iframe');
                } else {
                  print('DEBUG: Rendering fallback UI');
                  return _buildStaticContent(colors, theme);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Fallback for mobile / non-web platforms.
  Widget _buildStaticContent(ColorScheme colors, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final logoAsset = isDark
        ? 'assets/branding/nexlist_logo_dark.png'
        : 'assets/branding/nexlist_logo.png';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // ── Hero ──
              Image.asset(logoAsset, height: 40),
              const SizedBox(height: 20),
              Text(
                'Connect. Exchange. Secure.',
                style: AppTypography.h1.copyWith(
                  color: colors.onSurface,
                  fontSize: 30,
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'A verified campus marketplace where students buy, sell, rent, and exchange — safely and locally.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.65),
                    fontSize: 15,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 40),

              // ── Trust section ──
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Built for trust on campus v2',
                  style: AppTypography.h3.copyWith(color: colors.onSurface),
                ),
              ),
              const SizedBox(height: 16),
              _buildTrustCard(
                colors,
                icon: Icons.lock_rounded,
                title: 'Campus-only access',
                description:
                    'Only approved students and faculty can participate in the marketplace.',
              ),
              const SizedBox(height: 12),
              _buildTrustCard(
                colors,
                icon: Icons.verified_rounded,
                title: 'Verified students',
                description:
                    'Interactions stay local and trusted because every account is identity-gated.',
              ),
              const SizedBox(height: 12),
              _buildTrustCard(
                colors,
                icon: Icons.visibility_off_rounded,
                title: 'No public marketplace',
                description:
                    'Listings stay inside your campus ecosystem instead of being exposed publicly.',
              ),

              const SizedBox(height: 40),

              // ── How it works ──
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'How it works',
                  style: AppTypography.h3.copyWith(color: colors.onSurface),
                ),
              ),
              const SizedBox(height: 16),
              _buildStep(colors, 1,
                  'Post an item, rental, request, or service.'),
              const SizedBox(height: 14),
              _buildStep(colors, 2,
                  'Connect only with verified students on your campus.'),
              const SizedBox(height: 14),
              _buildStep(colors, 3,
                  'Meet locally and exchange directly on campus.'),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustCard(
    ColorScheme colors, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: colors.outline.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(ColorScheme colors, int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primary.withValues(alpha: 0.10),
          ),
          child: Text(
            '$number',
            style: AppTypography.label.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: AppTypography.bodyLarge.copyWith(
                color: colors.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
