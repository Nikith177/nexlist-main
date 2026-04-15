import sys

with open('lib/features/home/presentation/home_screen.dart', 'r') as f:
    text = f.read()

target = """  List<DocumentSnapshot> _applyFeedFilters(List<DocumentSnapshot> docs) {
    return docs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? const {};
          final type = ListingDataUtils.resolveType(data);

          bool matchesType = type == 'sell' || type == 'rent';
          if (selectedFilter == 'all') {
            matchesType = type == 'sell' || type == 'rent'; // FIX: EXCLUDE requests & services
          } else if (selectedFilter == 'sell') {
            matchesType = type == 'sell';
          } else if (selectedFilter == 'rent') {
            matchesType = type == 'rent';
          } else if (selectedFilter == 'services') {
            matchesType = type == 'service';
          } else if (selectedFilter == 'requests') {
            matchesType = type == 'request';
          }

          bool matchesCategory = true;
          final categoryId = selectedCategoryId;
          if (categoryId != null && categoryId != 'All') {
            matchesCategory = ListingCategoryUtils.matchesCategory(
              data,
              categoryId,
            );
          }

          return matchesType && matchesCategory;
        })
        .toList(growable: false);
  }"""

replacement = """  List<DocumentSnapshot> _applyFeedFilters(List<DocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? const {};
      final type = ListingDataUtils.resolveType(data);

      // TYPE FILTER
      bool matchesType;

      switch (selectedFilter) {
        case 'sell':
          matchesType = type == 'sell';
          break;
        case 'rent':
          matchesType = type == 'rent';
          break;
        case 'services':
          matchesType = type == 'service';
          break;
        case 'requests':
          matchesType = type == 'request';
          break;
        case 'all':
        default:
          // IMPORTANT: Only sell + rent allowed in feed
          matchesType = type == 'sell' || type == 'rent';
      }

      // CATEGORY FILTER (unchanged)
      bool matchesCategory = true;
      final categoryId = selectedCategoryId;

      if (categoryId != null && categoryId != 'All') {
        matchesCategory = ListingCategoryUtils.matchesCategory(
          data,
          categoryId,
        );
      }

      return matchesType && matchesCategory;
    }).toList(growable: false);
  }"""

if target in text:
    text = text.replace(target, replacement)
    print("Replaced _applyFeedFilters successfully.")
else:
    print("Could not find target function.")

with open('lib/features/home/presentation/home_screen.dart', 'w') as f:
    f.write(text)

