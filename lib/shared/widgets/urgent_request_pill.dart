import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import 'semantic_pill.dart';

class UrgentRequestPill extends StatelessWidget {
  const UrgentRequestPill({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPill(
      label: 'URGENT',
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      baseColor: AppColors.error,
      variant: AppPillVariant.solid,
      borderRadius: BorderRadius.circular(999),
      textStyle: AppTypography.label.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}
