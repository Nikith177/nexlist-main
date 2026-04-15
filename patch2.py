import sys

with open('lib/shared/widgets/custom_bottom_nav_bar.dart', 'r') as f:
    orig = f.read()

# Replace condition
orig = orig.replace('(isDesktop && widget.currentIndex == 0)', 'isDesktop')

# Replace onPressed in the AppBar Row
# I'll search for the specific IconButton snippet
add_button_old = """                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.add),
                          ),"""

add_button_new = """                          IconButton(
                            onPressed: widget.onPostTap,
                            icon: const Icon(Icons.add),
                          ),"""

if add_button_old in orig:
    orig = orig.replace(add_button_old, add_button_new)
else:
    print("Could not find the add button string exactly as written.")

with open('lib/shared/widgets/custom_bottom_nav_bar.dart', 'w') as f:
    f.write(orig)

print("Patch applied successfully.")
