import sys

with open('lib/features/home/presentation/widgets/home_widgets.dart', 'r') as f:
    text = f.read()

target = """                        FilterPill(
                          text: 'Rent',
                          isSelected: selectedFilter == 'rent',
                          onTap: () => onFilterChange('rent'),
                        ),
                      ],"""

replacement = """                        FilterPill(
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
                      ],"""

if target in text:
    text = text.replace(target, replacement)
else:
    print("WARNING: target not found.")

target_build = """  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);"""

replacement_build = """  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;"""

if target_build in text:
    text = text.replace(target_build, replacement_build)
else:
    print("WARNING: target_build not found.")

with open('lib/features/home/presentation/widgets/home_widgets.dart', 'w') as f:
    f.write(text)

print("Widgets patched successfully.")
