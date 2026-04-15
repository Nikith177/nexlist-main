import 'package:flutter/material.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/utils/listing_data_utils.dart';
import '../../../shared/utils/listing_location_utils.dart';
import '../../../shared/utils/time_utils.dart';
import '../../../shared/widgets/inline_metadata_row.dart';
import '../../../shared/widgets/semantic_pill.dart';
import '../../../shared/widgets/urgent_request_pill.dart';

class RequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;
  final Widget? topMenu;
  final int descriptionMaxLines;

  const RequestCard({
    super.key,
    required this.data,
    this.onTap,
    this.topMenu,
    this.descriptionMaxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardBorderColor = colors.outline.withValues(alpha: 0.10);
    final title = (data['title'] as String? ?? 'Untitled request').trim();
    final description = (data['description'] as String? ?? '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final num? rawBudget = (data['budget'] ?? data['price']) as num?;
    final int? budgetInt = rawBudget?.toInt();
    final bool hasBudget = budgetInt != null && budgetInt > 0;
    
    final location = ListingLocationUtils.resolveShortLocation(data);
    final timeAgo = TimeUtils.formatTimeAgo(
      ListingDataUtils.resolveCreatedAt(data),
    );
    final cleanTimeText =
        (timeAgo.isNotEmpty && timeAgo != 'Unknown' && timeAgo != 'Posting...')
        ? timeAgo
        : '';
    final isUrgent = ListingDataUtils.isUrgent(data);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorderColor),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: isDark ? 0.35 : 0.08),
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
                  backgroundColor: colors.primary.withValues(alpha: 0.08),
                  child: Icon(
                    Icons.person_outline_rounded,
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
                        title.isEmpty ? 'Untitled Request' : title,
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
                        timeText: cleanTimeText,
                        locationText: location,
                        textStyle: AppTypography.bodySmall.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                        iconSize: 12,
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
                        if (isUrgent)
                          const UrgentRequestPill()
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
                    if (hasBudget)
                      Text(
                        'Budget ₹$budgetInt',
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
