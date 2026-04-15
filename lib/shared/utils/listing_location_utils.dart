class ListingLocationUtils {
  static String resolveDisplayLocation(Map<String, dynamic> data) {
    final locationType = _clean(data['location_type'])?.toLowerCase();

    switch (locationType) {
      case 'hostel':
        return _clean(data['location_tag']) ?? '';
      case 'campus':
        return _clean(data['location_detail']) ?? '';
      case 'anywhere':
        return 'Anywhere';
      case 'online':
        return 'Online';
      default:
        return '';
    }
  }

  static bool hasDisplayLocation(Map<String, dynamic> data) {
    return resolveDisplayLocation(data).isNotEmpty;
  }

  static String resolveShortLocation(Map<String, dynamic> data) {
    final locationType = _clean(data['location_type'])?.toLowerCase();

    switch (locationType) {
      case 'hostel':
        final hostel = _clean(data['location_tag']);
        if (hostel == null) {
          return '';
        }
        final stripped = hostel
            .replaceAll(RegExp(r'hostel', caseSensitive: false), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        return _clean(stripped) ?? '';
      case 'campus':
        return _clean(data['location_detail']) ?? '';
      case 'anywhere':
      case 'online':
      default:
        return '';
    }
  }

  static String resolveShortCleanLocation(Map<String, dynamic> data) {
    final locationType = _clean(data['location_type'])?.toLowerCase();

    if (locationType == null ||
        locationType.isEmpty ||
        locationType == 'anywhere' ||
        locationType == 'online') {
      return '';
    }

    if (locationType == 'tag' || locationType == 'hostel') {
      return resolveShortLocation(data);
    }

    if (locationType == 'custom' || locationType == 'campus') {
      final raw = _clean(data['location_detail']);
      if (raw == null || raw.isEmpty) {
        return '';
      }

      const stopWords = {
        'near',
        'in',
        'at',
        'behind',
        'beside',
        'by',
        'next',
        'to',
        'of',
        'on',
        'outside',
        'under',
        'front',
      };

      final words = raw
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .split(' ')
          .where((w) => w.isNotEmpty)
          .where((w) => !stopWords.contains(w.toLowerCase()))
          .toList();

      if (words.isEmpty) {
        return '';
      }

      final selected = words.length >= 2
          ? words.sublist(words.length - 2)
          : [words.last];
      final result = selected.join(' ');

      return result[0].toUpperCase() + result.substring(1);
    }

    return '';
  }

  static String? _clean(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    final normalized = text.toLowerCase();
    if (normalized == 'unknown' ||
        normalized == 'null' ||
        normalized == 'undefined' ||
        normalized == 'n/a') {
      return null;
    }
    return text;
  }
}
