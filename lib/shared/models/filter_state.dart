class FilterState {
  final String sort;
  final int? minPrice;
  final int? maxPrice;
  final List<String> locations;

  const FilterState({
    this.sort = 'newest',
    this.minPrice,
    this.maxPrice,
    this.locations = const [],
  });

  bool get isActive =>
      sort != 'newest' ||
      minPrice != null ||
      maxPrice != null ||
      locations.isNotEmpty;
}

