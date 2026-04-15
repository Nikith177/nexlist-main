import sys

with open('lib/features/home/presentation/widgets/home_widgets.dart', 'r') as f:
    text = f.read()

# 1. Update FilterPill
pill_target = """class FilterPill extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderColor = colors.outline.withValues(alpha: isSelected ? 0 : 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}"""

pill_replacement = """class FilterPill extends StatefulWidget {
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
    
    final borderColor = colors.outline.withValues(alpha: widget.isSelected ? 0 : 0.08);

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
        borderRadius: BorderRadius.circular(9),
        child: Ink(
          padding: isDesktop
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
          decoration: BoxDecoration(
            color: getBgColor(),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              color: widget.isSelected ? colors.onPrimary : colors.onSurfaceVariant,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}"""

if pill_target in text:
    text = text.replace(pill_target, pill_replacement)
    print("Patched FilterPill.")
else:
    print("WARNING: FilterPill target not found.")

# 2. Update StickyFilterHeader
header_target = """                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilterPill(
                          text: 'All',
                          isSelected: selectedFilter == 'all',
                          onTap: () => onFilterChange('all'),
                        ),
                        const SizedBox(width: 3),
                        FilterPill(
                          text: 'Sale',
                          isSelected: selectedFilter == 'sell',
                          onTap: () => onFilterChange('sell'),
                        ),
                        const SizedBox(width: 3),
                        FilterPill(
                          text: 'Rent',
                          isSelected: selectedFilter == 'rent',
                          onTap: () => onFilterChange('rent'),
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 3),
                          FilterPill(
                            text: 'Services',
                            isSelected: selectedFilter == 'services',
                            onTap: () => onFilterChange('services'),
                          ),
                          const SizedBox(width: 3),
                          FilterPill(
                            text: 'Requests',
                            isSelected: selectedFilter == 'requests',
                            onTap: () => onFilterChange('requests'),
                          ),
                        ],
                      ],
                    ),"""

header_replacement = """                      child: isDesktop
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  FilterPill(
                                    text: 'All',
                                    isSelected: selectedFilter == 'all',
                                    onTap: () => onFilterChange('all'),
                                  ),
                                  FilterPill(
                                    text: 'Sale',
                                    isSelected: selectedFilter == 'sell',
                                    onTap: () => onFilterChange('sell'),
                                  ),
                                  FilterPill(
                                    text: 'Rent',
                                    isSelected: selectedFilter == 'rent',
                                    onTap: () => onFilterChange('rent'),
                                  ),
                                  FilterPill(
                                    text: 'Services',
                                    isSelected: selectedFilter == 'services',
                                    onTap: () => onFilterChange('services'),
                                  ),
                                  FilterPill(
                                    text: 'Requests',
                                    isSelected: selectedFilter == 'requests',
                                    onTap: () => onFilterChange('requests'),
                                  ),
                                ],
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FilterPill(
                                  text: 'All',
                                  isSelected: selectedFilter == 'all',
                                  onTap: () => onFilterChange('all'),
                                ),
                                const SizedBox(width: 3),
                                FilterPill(
                                  text: 'Sale',
                                  isSelected: selectedFilter == 'sell',
                                  onTap: () => onFilterChange('sell'),
                                ),
                                const SizedBox(width: 3),
                                FilterPill(
                                  text: 'Rent',
                                  isSelected: selectedFilter == 'rent',
                                  onTap: () => onFilterChange('rent'),
                                ),
                              ],
                            ),"""

if header_target in text:
    text = text.replace(header_target, header_replacement)
    print("Patched StickyFilterHeader.")
else:
    print("WARNING: StickyFilterHeader target not found.")

with open('lib/features/home/presentation/widgets/home_widgets.dart', 'w') as f:
    f.write(text)

print("Patch script finished.")
