with open('lib/features/home/presentation/widgets/home_widgets.dart', 'r') as f:
    text = f.read()

import re
# Find FilterPill class
pill_match = re.search(r'class FilterPill extends StatelessWidget \{.*?\n\}', text, re.DOTALL)
if pill_match:
    print(pill_match.group(0))

# Find StickyFilterHeader class
sticky_match = re.search(r'class StickyFilterHeader extends SliverPersistentHeaderDelegate \{.*?shouldRebuild[^}]*\}', text, re.DOTALL)
if sticky_match:
    print(sticky_match.group(0) + '\n}')

