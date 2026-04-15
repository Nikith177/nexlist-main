import 'package:flutter/material.dart';
import '../../../../config/listing_categories.dart';
import '../../../../shared/utils/listing_data_utils.dart';
import '../../../../shared/utils/listing_location_utils.dart';
import '../../../../shared/utils/time_utils.dart';
import '../../../../shared/utils/title_format_utils.dart';
import '../../../../shared/widgets/inline_metadata_row.dart';
import '../../../../shared/widgets/urgent_request_pill.dart';

class FilterPill extends StatefulWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterPill({
    super.key,
    required this.text,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  State<FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<FilterPill> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color getBgColor() {
      if (!isDesktop) {
        return widget.isSelected ? colors.primary : colors.surfaceContainerHighest;
      }
      if (widget.isSelected) {
        return Colors.blueAccent;
      }
      return _isHovering ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.08);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHover: isDesktop ? (val) => setState(() => _isHovering = val) : null,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: getBgColor(),
            borderRadius: BorderRadius.circular(20),
            border: (isDark && !widget.isSelected) ? Border.all(color: colors.outline.withValues(alpha: 0.08)) : null,
          ),
          child: Text(
            widget.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
              color: widget.isSelected ? colors.onPrimary : colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryIconRow extends StatelessWidget {
  final void Function(String category) onCategoryTap;
  final String? selectedCategory;

  const CategoryIconRow({
    super.key,
    required this.onCategoryTap,
    this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final categories = ListingCategories.getSellCategoryDefinitions();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 90,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: categories.map((category) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CategoryIconItem(
                icon: category.icon,
                label: category.name,
                isSelected: selectedCategory == category.name,
                onTap: () => onCategoryTap(category.name),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class CategoryIconItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const CategoryIconItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: 84, // optimal width to prevent text truncation while keeping items tightly clustered
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: primary.withValues(alpha: 0.1),
          highlightColor: primary.withValues(alpha: 0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: isSelected
                      ? primary.withValues(alpha: isDark ? 0.15 : 0.10)
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F4F9)),
                  border: isSelected
                      ? Border.all(
                          color: primary.withValues(alpha: 0.6),
                          width: 1.5,
                        )
                      : (isDark
                          ? Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            )
                          : null),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 26,
                    color: isSelected
                        ? primary
                        : (isDark ? Colors.white : const Color(0xFF3C4043)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                  letterSpacing: 0.2,
                  color: isSelected
                      ? primary
                      : (isDark ? Colors.white70 : const Color(0xFF4A5568)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityPill extends StatelessWidget {
  final String text;
  final Color dotColor;
  final VoidCallback onTap;

  const ActivityPill({
    super.key,
    required this.text,
    required this.dotColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: isDark
              ? colors.primary.withValues(alpha: 0.12)
              : colors.primary.withValues(alpha: 0.08),
          border: Border.all(
            color: isDark
                ? colors.primary.withValues(alpha: 0.25)
                : colors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.primary, // Force blue dot to match reference
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.blue.shade200 : colors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeRequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const HomeRequestCard({
    super.key,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = colors.onSurface;
    final onSurfaceMuted = onSurface.withValues(alpha: 0.72);
    final title = ((data['title'] as String?) ?? 'Untitled request').trim();
    final location = ListingLocationUtils.resolveShortCleanLocation(data);
    final timeAgo = TimeUtils.formatTimeAgo(
      ListingDataUtils.resolveCreatedAt(data),
    );
    final displayTitle = formatTitle(
      title.isEmpty ? 'Untitled request' : title,
    );
    final cleanTimeText =
        (timeAgo.isNotEmpty && timeAgo != 'Unknown' && timeAgo != 'Posting...')
        ? timeAgo
        : '';
    final isUrgent = ListingDataUtils.isUrgent(data);
    final num? rawBudget = (data['budget'] ?? data['price']) as num?;
    final int? budgetInt = rawBudget?.toInt();
    final bool hasBudget = budgetInt != null && budgetInt > 0;
    final hasRightColumn = isUrgent || hasBudget;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: isDark ? colors.surfaceContainerHighest.withValues(alpha: 0.72) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isDark 
                  ? Border.all(color: colors.outline.withValues(alpha: 0.08)) 
                  : Border.all(color: Colors.black.withValues(alpha: 0.04)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 15,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: onSurface,
                          ),
                        ),
                        if (cleanTimeText.isNotEmpty || location.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          InlineMetadataRow(
                            timeText: cleanTimeText,
                            locationText: location,
                            textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: onSurfaceMuted,
                            ),
                            iconSize: 12,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasRightColumn) ...[
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isUrgent) const UrgentRequestPill(),
                        if (isUrgent && hasBudget) const SizedBox(height: 2),
                        if (hasBudget)
                          Text(
                            'Budget ₹$budgetInt',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
