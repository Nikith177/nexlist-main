import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

enum AppPillVariant { subtle, solid }

class AppPill extends StatelessWidget {
  final String label;
  final Color? baseColor;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final TextStyle? textStyle;
  final AppPillVariant variant;

  const AppPill({
    super.key,
    required this.label,
    this.baseColor,
    required this.padding,
    required this.borderRadius,
    this.textStyle,
    this.variant = AppPillVariant.subtle,
  });

  @override
  Widget build(BuildContext context) {
    final style = resolveAppPillStyle(
      context,
      label,
      fallbackColor: baseColor,
      variant: variant,
    );

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(color: style.borderColor),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: (textStyle ?? const TextStyle()).copyWith(
          color: style.textColor,
        ),
      ),
    );
  }
}

class AppPillStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const AppPillStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}

AppPillStyle resolveAppPillStyle(
  BuildContext context,
  String label, {
  Color? fallbackColor,
  AppPillVariant variant = AppPillVariant.subtle,
}) {
  final colors = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final normalizedLabel = label.trim().toUpperCase();

  final baseColor = switch (normalizedLabel) {
    'SELL' => AppColors.sellPill,
    'RENT' => AppColors.rentPill,
    'REQUEST' => AppColors.requestPill,
    'SERVICE' => AppColors.servicePill,
    'FREE' => isDark ? const Color(0xFF6B7280) : const Color(0xFF64748B),
    'NEGOTIABLE' => colors.primary,
    'URGENT' => colors.error,
    _ => fallbackColor ?? colors.primary,
  };

  final isNeutral = normalizedLabel == 'FREE';

  if (variant == AppPillVariant.solid) {
    return AppPillStyle(
      backgroundColor: baseColor,
      borderColor: baseColor,
      textColor: Colors.white,
    );
  }

  return AppPillStyle(
    backgroundColor: baseColor.withValues(alpha: isNeutral ? 0.10 : 0.12),
    borderColor: baseColor.withValues(alpha: isNeutral ? 0.18 : 0.24),
    textColor: baseColor,
  );
}
