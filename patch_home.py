import sys

with open('lib/features/home/presentation/home_screen.dart', 'r') as f:
    text = f.read()

target = """          bool matchesType = type == 'sell' || type == 'rent';
          if (selectedFilter == 'sell') {
            matchesType = type == 'sell';
          } else if (selectedFilter == 'rent') {
            matchesType = type == 'rent';
          }"""

replacement = """          bool matchesType = type == 'sell' || type == 'rent';
          if (selectedFilter == 'all') {
            matchesType = true;
          } else if (selectedFilter == 'sell') {
            matchesType = type == 'sell';
          } else if (selectedFilter == 'rent') {
            matchesType = type == 'rent';
          } else if (selectedFilter == 'services') {
            matchesType = type == 'service';
          } else if (selectedFilter == 'requests') {
            matchesType = type == 'request';
          }"""

if target in text:
    text = text.replace(target, replacement)
else:
    print("WARNING: feed logic target not found.")

with open('lib/features/home/presentation/home_screen.dart', 'w') as f:
    f.write(text)

print("Home screen logic patched successfully.")
