import sys

with open('lib/features/home/presentation/widgets/home_widgets.dart', 'r') as f:
    text = f.read()

# 1. Update FilterPill padding + remove isDesktop
pill_target = """        child: Ink(
          padding: isDesktop
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
          decoration: BoxDecoration(
            color: getBgColor(),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: borderColor),
          ),"""

pill_replacement = """        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: getBgColor(),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: borderColor),
          ),"""

if pill_target in text:
    text = text.replace(pill_target, pill_replacement)
    print("Patched FilterPill padding.")
else:
    print("WARNING: FilterPill target not found.")

# 2. Update StickyFilterHeader layout
header_target = """            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: isDesktop
                          ? Center(
                              child: SizedBox(
                                height: 44, // FIXED HEIGHT → prevents overflow
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  children: [
                                    const SizedBox(width: 8),
                                    FilterPill(
                                      text: 'All',
                                      isSelected: selectedFilter == 'all',
                                      onTap: () => onFilterChange('all'),
                                    ),
                                    const SizedBox(width: 10),
                                    FilterPill(
                                      text: 'Sale',
                                      isSelected: selectedFilter == 'sell',
                                      onTap: () => onFilterChange('sell'),
                                    ),
                                    const SizedBox(width: 10),
                                    FilterPill(
                                      text: 'Rent',
                                      isSelected: selectedFilter == 'rent',
                                      onTap: () => onFilterChange('rent'),
                                    ),
                                    const SizedBox(width: 10),
                                    FilterPill(
                                      text: 'Services',
                                      isSelected: selectedFilter == 'services',
                                      onTap: () => onFilterChange('services'),
                                    ),
                                    const SizedBox(width: 10),
                                    FilterPill(
                                      text: 'Requests',
                                      isSelected: selectedFilter == 'requests',
                                      onTap: () => onFilterChange('requests'),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
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
                                const SizedBox(width: 6),
                                FilterPill(
                                  text: 'Sale',
                                  isSelected: selectedFilter == 'sell',
                                  onTap: () => onFilterChange('sell'),
                                ),
                                const SizedBox(width: 6),
                                FilterPill(
                                  text: 'Rent',
                                  isSelected: selectedFilter == 'rent',
                                  onTap: () => onFilterChange('rent'),
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),"""

header_replacement = """            child: Wrap(
              spacing: 10,
              runSpacing: 8,
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
            ),"""

if header_target in text:
    text = text.replace(header_target, header_replacement)
    print("Patched StickyFilterHeader layout.")
else:
    print("WARNING: StickyFilterHeader layout target not found.")

with open('lib/features/home/presentation/widgets/home_widgets.dart', 'w') as f:
    f.write(text)

