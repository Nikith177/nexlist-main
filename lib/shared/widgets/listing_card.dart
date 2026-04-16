import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../utils/title_format_utils.dart';
import 'inline_metadata_row.dart';
import 'semantic_pill.dart';

class ListingCard extends StatelessWidget {
  static const double gridChildAspectRatio = 0.95;

  final String title;
  final String priceText;
  final List<String> imageUrls;
  final String location;
  final String timeAgo;
  final String tagText;
  final Color tagColor;
  final bool isFavorite;
  final bool isNegotiable;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final Widget? topMenu;
  final String? heroTag;
  final bool isPassoutSale;

  const ListingCard({
    super.key,
    required this.title,
    this.priceText = '',
    this.imageUrls = const [],
    required this.location,
    required this.timeAgo,
    required this.tagText,
    required this.tagColor,
    this.isFavorite = false,
    this.isNegotiable = false,
    this.onTap,
    this.onFavoriteTap,
    this.topMenu,
    this.heroTag,
    this.isPassoutSale = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasImage = imageUrls.isNotEmpty;
    final cardBorderColor = colors.outline.withValues(alpha: 0.10);
    final resolvedPriceText = priceText.isEmpty ? 'Free' : priceText;
    final overlayButtonDecoration = BoxDecoration(
      shape: BoxShape.circle,
      color: isDark
          ? colors.surface.withValues(alpha: 0.94)
          : colors.surface.withValues(alpha: 0.98),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : colors.outline.withValues(alpha: 0.14),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.12),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
    final unsavedFavoriteColor = isDark ? Colors.white : colors.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: cardBorderColor) : Border.all(color: Colors.black.withValues(alpha: 0.03)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image section ──
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      hasImage
                          ? Hero(
                              tag: heroTag ?? '__no_hero__',
                              child: Image.network(
                                imageUrls.first,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Container(
                              color: colors.surfaceContainerHighest,
                              child: Icon(
                                Icons.image_outlined,
                                color: colors.onSurface.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: AppPill(
                          label: tagText.toUpperCase() == 'FREE'
                              ? 'FREE'
                              : (isPassoutSale ? 'PASSOUT SALE' : tagText.toUpperCase()),
                          baseColor: tagText.toUpperCase() == 'FREE'
                              ? tagColor
                              : (isPassoutSale
                                  ? const Color(0xFFEC4899)
                                  : tagColor),
                          variant: AppPillVariant.solid,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          textStyle: theme.textTheme.bodySmall,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: onFavoriteTap,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: overlayButtonDecoration,
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite
                                      ? AppColors.error
                                      : unsavedFavoriteColor,
                                  size: 18,
                                ),
                              ),
                            ),
                            if (topMenu != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                decoration: overlayButtonDecoration,
                                child: Theme(
                                  data: theme.copyWith(
                                    iconTheme: IconThemeData(
                                      color: unsavedFavoriteColor,
                                      size: 18,
                                    ),
                                  ),
                                  child: topMenu!,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Metadata section ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatTitle(title.isEmpty ? 'Untitled' : title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MediaQuery.of(context).size.width > 600
                        ? Row(
                            children: [
                              Expanded(
                                child: Text(
                                  resolvedPriceText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isNegotiable) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: _buildNegotiationPill(context),
                                ),
                              ],
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  resolvedPriceText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colors.primary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isNegotiable) ...[
                                const SizedBox(width: 6),
                                _buildCompactNegotiationPill(context),
                              ],
                            ],
                          ),
                    const SizedBox(height: 4),
                    InlineMetadataRow(
                      timeText: timeAgo,
                      locationText: location,
                      textStyle: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.68),
                      ),
                      iconSize: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNegotiationPill(BuildContext context) {
    final style = resolveAppPillStyle(context, 'Negotiable');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: style.borderColor),
      ),
      child: Text(
        "Negotiable",
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
        style: (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
          color: style.textColor,
        ),
      ),
    );
  }

  Widget _buildCompactNegotiationPill(BuildContext context) {
    final style = resolveAppPillStyle(context, 'Negotiable');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: style.borderColor),
      ),
      child: Text(
        "Negotiable",
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
        style: (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: style.textColor,
        ),
      ),
    );
  }
}
