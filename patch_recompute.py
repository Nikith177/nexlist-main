import sys

with open('lib/features/home/presentation/home_screen.dart', 'r') as f:
    text = f.read()

target = """  void _recomputeFeedSections() {
    final filteredDocs = ListingDataUtils.sortDocsByCreatedAtDesc(
      _applyFeedFilters(_allDocs),
    );

    _finalDocs = filterListings(
      filteredDocs,
      searchQuery,
    ).take(50).toList(growable: false);

    final showBrowseSections = searchQuery.isEmpty && selectedFilter == 'all';
    _activityItems = showBrowseSections
        ? _buildCampusActivityItems(_allDocs)
        : const <_CampusActivityItemData>[];
    _studentsNeedItems = showBrowseSections
        ? _buildStudentsNeedItems(_allDocs)
        : const <_StudentsNeedItemData>[];
  }"""

replacement = """  void _recomputeFeedSections() {
    final showBrowseSections = searchQuery.isEmpty && selectedFilter == 'all';
    
    _activityItems = showBrowseSections
        ? _buildCampusActivityItems(_allDocs)
        : const <_CampusActivityItemData>[];
        
    _studentsNeedItems = showBrowseSections
        ? _buildStudentsNeedItems(_allDocs)
        : const <_StudentsNeedItemData>[];

    _finalDocs = _applyFeedFilters(_allDocs);

    if (selectedFilter == 'all') {
      for (final doc in _finalDocs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final type = ListingDataUtils.resolveType(data);
        if (type != 'sell' && type != 'rent') {
          debugPrint('INVALID TYPE IN FEED: $type');
        }
      }
    }
  }"""

if target in text:
    text = text.replace(target, replacement)
    print("Replaced _recomputeFeedSections safely.")
else:
    print("target not found")

with open('lib/features/home/presentation/home_screen.dart', 'w') as f:
    f.write(text)
