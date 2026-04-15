import sys

with open('lib/features/home/presentation/home_screen.dart', 'r') as f:
    text = f.read()

# Add isDesktop
target_decl = """            final isDark = theme.brightness == Brightness.dark;"""
if "final isDesktop =" not in text:
    text = text.replace(target_decl, f"final isDesktop = MediaQuery.of(context).size.width >= 800;\n{target_decl}")

lines = text.split('\n')

start_idx = -1
end_idx = -1

for i, line in enumerate(lines):
    if "SliverToBoxAdapter(" in line and "Header / App Bar content" in lines[i-1]:
        start_idx = i - 1
    
    if "if (showBrowseSections && _activityItems.isNotEmpty)" in line:
        end_idx = i - 1
        break

print(f"Start: {start_idx}, End: {end_idx}")
for idx in range(end_idx - 3, end_idx + 3):
    print(lines[idx])

