import sys

filepath = 'lib/features/home/presentation/widgets/home_widgets.dart'
with open(filepath, 'r') as f:
    text = f.read()

target = """              children: [
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
              ],"""

replacement = """              children: [
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
                if (isDesktop) ...[
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
              ],"""


if target in text:
    text = text.replace(target, replacement)
    with open(filepath, 'w') as f:
        f.write(text)
    print(f"Patched {filepath} safely.")
else:
    print(f"target not found in {filepath}!")
