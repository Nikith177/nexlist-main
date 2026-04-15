import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import 'semantic_pill.dart';

class RequestCard extends StatelessWidget {
  final String title;
  final String budget;
  final String location;
  final String timeAgo;
  final String category;
  final bool isFavorite;
  final bool isNegotiable;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final Widget? topMenu;

  const RequestCard({
    super.key,
    required this.title,
    required this.budget,
    required this.location,
    required this.timeAgo,
    required this.category,
    this.isFavorite = false,
    this.isNegotiable = false,
    this.onTap,
    this.onFavoriteTap,
    this.topMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: AppColors.border.withValues(alpha: 0.5)) : Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LEFT ICON
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                child: Icon(
                  _getRequestIcon(category),
                  color: AppColors.primary.withValues(alpha: 0.8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TITLE
                    Text(
                      title.isEmpty ? 'Untitled Request' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // META ROW
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                        Text(
                          timeAgo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // RIGHT SIDE
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // BADGE / TOP MENU
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isNegotiable)
                        AppPill(
                          label: 'NEGOTIABLE',
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          textStyle: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        AppPill(
                          label: 'REQUEST',
                          variant: AppPillVariant.solid,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          textStyle: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (topMenu != null) ...[
                        const SizedBox(width: 4),
                        topMenu!,
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // PRICE
                  Text(
                    budget.trim().isEmpty ? 'Negotiable' : budget,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRequestIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('cycle')) return Icons.pedal_bike;
    if (c.contains('electric')) return Icons.bolt;
    if (c.contains('furniture')) return Icons.chair;
    if (c.contains('book')) return Icons.menu_book;
    if (c.contains('tech')) return Icons.laptop;
    return Icons.campaign;
  }
}
