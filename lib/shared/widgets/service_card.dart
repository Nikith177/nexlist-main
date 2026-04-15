import 'package:flutter/material.dart';

import '../../core/theme/typography.dart';
import '../../shared/utils/listing_category_utils.dart';
import '../../shared/utils/listing_data_utils.dart';
import '../../shared/utils/listing_location_utils.dart';
import '../../shared/utils/listing_price_utils.dart';
import '../../shared/utils/time_utils.dart';
import 'inline_metadata_row.dart';
import 'semantic_pill.dart';

class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;
  final Widget? topMenu;

  const ServiceCard({
    super.key,
    required this.data,
    required this.docId,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
    this.topMenu,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cardBorderColor = colors.outline.withValues(alpha: 0.10);
    final isDark = theme.brightness == Brightness.dark;
    final title = data['title'] as String? ?? 'Untitled Service';
    final description = (data['description'] as String? ?? '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final priceDisplay = ListingPriceUtils.resolveDisplayPrice(data);
    final allowNegotiation = data['allow_negotiation'] as bool? ?? false;

    final category = ListingCategoryUtils.resolveCategory(data);
    final displayLocation = ListingLocationUtils.resolveDisplayLocation(data);
    final timeAgo = TimeUtils.formatTimeAgo(
      ListingDataUtils.resolveCreatedAt(data),
    );
    final hasLocation = displayLocation.isNotEmpty;
    final hasTime = timeAgo.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: cardBorderColor) : null,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // LEFT ICON
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  child: Icon(
                    ListingCategoryUtils.categoryIcon(category),
                    color: colors.primary,
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
                        title.isEmpty ? 'Untitled Service' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      // META ROW
                      InlineMetadataRow(
                        timeText: hasTime ? timeAgo : '',
                        locationText: hasLocation ? displayLocation : '',
                        textStyle: AppTypography.bodySmall.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                        iconSize: 16,
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
                        if (allowNegotiation)
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
                            label: 'SERVICE',
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
                      priceDisplay.hasPrice ? priceDisplay.text : 'Free',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
