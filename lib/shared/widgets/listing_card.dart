import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';

class ListingCard extends StatelessWidget {
  final String title;
  final String price;
  final String location;
  final String type;
  final bool isUrgent;
  final String timeAgo;

  const ListingCard({
    Key? key,
    required this.title,
    required this.price,
    required this.location,
    required this.type,
    this.isUrgent = false,
    required this.timeAgo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Placeholder Header
          Stack(
            children: [
              Container(
                height: 160,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusLg),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.image_outlined, size: 48, color: AppColors.border),
                ),
              ),
              // Type Badge
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppSpacing.defaultBorderRadius,
                  ),
                  child: Text(type.toUpperCase(), style: AppTypography.label),
                ),
              ),
              // Urgent Badge
              if (isUrgent)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: AppSpacing.defaultBorderRadius,
                    ),
                    child: Text(
                      'URGENT', 
                      style: AppTypography.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
            ],
          ),
          
          // Card Details Body
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppSpacing.gapSm,
                    Text(
                      price,
                      style: AppTypography.h2.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                AppSpacing.gapSm,
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                    AppSpacing.gapXs,
                    Text(location, style: AppTypography.bodyMedium),
                    const Spacer(),
                    Text(timeAgo, style: AppTypography.bodySmall),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
