import 'package:flutter/material.dart';

import '../../config/listing_categories.dart';
import 'listing_data_utils.dart';

class ListingCategoryUtils {
  static String normalizeCategoryValue(String? category, {String? type}) {
    final normalizedType = (type ?? '').trim().toLowerCase();
    if (normalizedType.isEmpty) {
      return (category ?? '').trim();
    }
    return ListingCategories.normalizeCategory(category, type: normalizedType);
  }

  static String resolveCategory(Map<String, dynamic> data) {
    final type = ListingDataUtils.resolveType(data);
    return normalizeCategoryValue(data['category']?.toString(), type: type);
  }

  static String normalizeCategoryForWrite(
    String? category, {
    required String type,
  }) {
    return normalizeCategoryValue(category, type: type);
  }

  static bool matchesCategory(Map<String, dynamic> data, String selected) {
    final type = ListingDataUtils.resolveType(data);
    final resolved = resolveCategory(data);
    if (resolved.isEmpty) {
      return false;
    }
    return resolved == normalizeCategoryValue(selected, type: type);
  }

  static List<String> categoriesForType(String type) {
    return ListingCategories.categoriesForType(type);
  }

  static List<String> queryValuesForCategory(
    String category, {
    required String type,
  }) {
    return ListingCategories.queryValuesForCategory(category, type: type);
  }

  static IconData categoryIcon(String category) {
    return ListingCategories.iconForCategory(category);
  }
}
