import sys

with open('lib/features/home/presentation/home_screen.dart', 'r') as f:
    text = f.read()

target = """          bool matchesType = type == 'sell' || type == 'rent';
          if (selectedFilter == 'all') {
            matchesType = true;
          } else if (selectedFilter == 'sell') {"""

replacement = """          bool matchesType = type == 'sell' || type == 'rent';
          if (selectedFilter == 'all') {
            matchesType = type == 'sell' || type == 'rent';
          } else if (selectedFilter == 'sell') {"""

if target in text:
    text = text.replace(target, replacement)
    print("Patched _applyFeedFilters successfully.")
else:
    print("WARNING: Could not find target in _applyFeedFilters.")

with open('lib/features/home/presentation/home_screen.dart', 'w') as f:
    f.write(text)

