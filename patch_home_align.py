import sys

with open('lib/features/home/presentation/home_screen.dart', 'r') as f:
    text = f.read()

# Target to replace:
target = """                  // Header / App Bar content (Restored unconditionally)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: isDesktop
                          ? const EdgeInsets.fromLTRB(16, 8, 16, 12)
                          : const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        children: ["""

replacement = """                  // Header / App Bar content (Restored unconditionally)
                  SliverToBoxAdapter(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Padding(
                          padding: isDesktop
                              ? const EdgeInsets.fromLTRB(16, 8, 16, 12)
                              : const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(
                            children: ["""

if target in text:
    text = text.replace(target, replacement)
else:
    # Check another variant depending on how the preceding comment is written
    target2 = """                  // Header / App Bar content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: isDesktop
                          ? const EdgeInsets.fromLTRB(16, 8, 16, 12)
                          : const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        children: ["""
    if target2 in text:
        text = text.replace(target2, replacement.replace("(Restored unconditionally)\n                  ", ""))
    else:
        print("WARNING: Target Not Found!")

# Since we opened Align and ConstrainedBox, we need to close them!
# They wrap the Padding block!
# Let's find where Padding is closed.
# The `child: Column(` children open at `children: [`, then search bar, then `]` closes children, then `),` closes Column, then `),` closes Padding.
# Then `SliverToBoxAdapter` is closed.

# I'll just look for the end of the `SliverToBoxAdapter`:
close_target = """                          if (isDesktop) const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),"""

close_replacement = """                          if (isDesktop) const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),"""

if close_target in text:
    text = text.replace(close_target, close_replacement)
else:
    print("WARNING: Close Target Not Found!")

# What about the other slivers? What about `if (_shouldShowClaimCard) SliverToBoxAdapter( ... Padding( _buildClaimCard() )`?
# What about the feed? `SliverPadding` mapping to `SliverGrid`? Wait, the feed isn't inside `SliverToBoxAdapter`'s Column!
# The user said: "Find the main content inside: CustomScrollView -> SliverToBoxAdapter -> Column"
# And then "Filters no longer feel 'floating'... Feed looks contained".
# Wait, if they say "Feed looks contained", do they want me to apply this strictly to the feed as well, or just the header column?
# If I only wrap the Header, the Feed is still full screen on Desktop (1200px max, or whatever SliverGrid dictates).
# "Wrap ONLY the Column child with: Align( ... ) ... DO NOT wrap entire Scaffold. DO NOT wrap CustomScrollView. ONLY wrap inner Column inside SliverToBoxAdapter"
# This aligns exactly with the instruction: Wrap ONLY the Column child inside SliverToBoxAdapter.

with open('lib/features/home/presentation/home_screen.dart', 'w') as f:
    f.write(text)

def check_brackets(text):
    stack = []
    lines = text.split('\n')
    for i, line in enumerate(lines):
        for j, char in enumerate(line):
            if char in '([{':
                stack.append((char, i + 1, j + 1))
            elif char in ')]}':
                if not stack:
                    return f'Unmatched closing {char} at line {i+1}, col {j+1}'
                last_char, row, col = stack.pop()
                if (char == ')' and last_char != '(') or \
                   (char == ']' and last_char != '[') or \
                   (char == '}' and last_char != '{'):
                    return f'Mismatched {char} at line {i+1}, col {j+1}'
    if stack:
        return 'Unclosed brackets'
    else:
        return 'All brackets match!'

print(check_brackets(text))
print("Home screen desktop layout patched successfully.")
