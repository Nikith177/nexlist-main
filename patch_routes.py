import sys

with open('lib/features/home/presentation/home_screen.dart', 'r') as f:
    text = f.read()

target = """                      delegate: StickyFilterHeader(
                        selectedFilter: selectedFilter,
                        onFilterChange: (value) {
                          setState(() {
                            selectedFilter = value;
                            selectedCategoryId = null;
                            searchQuery = '';
                            _recomputeFeedSections();
                          });
                        },
                      ),"""

replacement = """                      delegate: StickyFilterHeader(
                        selectedFilter: selectedFilter,
                        onFilterChange: (value) {
                          if (value == 'services') {
                            context.push('/services');
                            return;
                          }

                          if (value == 'requests') {
                            context.push('/requests');
                            return;
                          }

                          setState(() {
                            selectedFilter = value;
                            selectedCategoryId = null;
                            searchQuery = '';
                            _recomputeFeedSections();
                          });
                        },
                      ),"""

# NOTE: Using context.push() instead of context.go() to allow back navigation.
# Oh wait, the prompt says "context.go()". I will use go.

replacement = replacement.replace("context.push", "context.go")

if target in text:
    text = text.replace(target, replacement)
    print("Replaced StickyFilterHeader correctly.")
else:
    print("target not found")

with open('lib/features/home/presentation/home_screen.dart', 'w') as f:
    f.write(text)
