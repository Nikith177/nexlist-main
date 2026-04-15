class ListingConditionUtils {
  static const List<String> orderedValues = [
    'like_new',
    'good',
    'fair',
    'poor',
  ];

  static const Map<String, String> _displayValues = {
    'like_new': 'Like New',
    'good': 'Good',
    'fair': 'Fair',
    'poor': 'Poor',
  };

  static String? normalizeCondition(dynamic raw) {
    if (raw == null) return null;

    final normalized = raw.toString().trim().toLowerCase().replaceAll(
      RegExp(r'[\s-]+'),
      '_',
    );

    if (_displayValues.containsKey(normalized)) {
      return normalized;
    }

    switch (normalized) {
      case 'like_new_condition':
        return 'like_new';
      default:
        return null;
    }
  }

  static String getDisplayCondition(dynamic raw) {
    final normalized = normalizeCondition(raw);
    if (normalized == null) return '';
    return _displayValues[normalized] ?? '';
  }
}
