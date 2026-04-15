import 'package:flutter/material.dart';

class Category {
  final String name;
  final IconData icon;

  const Category(this.name, this.icon);
}

class ListingCategories {
  static const List<Category> _sellCategoryDefinitions = [
    Category('Electronics', Icons.devices),
    Category('Books & Study', Icons.menu_book),
    Category('Furniture & Hostel', Icons.bed),
    Category('Vehicles & Cycles', Icons.directions_bike),
    Category('Clothing & Fashion', Icons.checkroom),
    Category('Accessories & Misc', Icons.category),
    Category('Travel', Icons.luggage),
    Category('Other', Icons.more_horiz),
  ];

  static const List<Category> _serviceCategoryDefinitions = [
    Category('Academic & Tutoring', Icons.school),
    Category('Tech & Design', Icons.build),
    Category('Errands & Help', Icons.delivery_dining),
    Category('Creative & Media', Icons.palette),
    Category('Other', Icons.more_horiz),
  ];

  static const Map<String, String> _marketplaceCategoryMap = {
    'Electronics': 'Electronics',
    'Books & Study': 'Books & Study',
    'Books': 'Books & Study',
    'Notes': 'Books & Study',
    'Study Material': 'Books & Study',
    'Notes & Study Material': 'Books & Study',
    'Stationery': 'Books & Study',
    'Furniture & Hostel': 'Furniture & Hostel',
    'Furniture': 'Furniture & Hostel',
    'Hostel': 'Furniture & Hostel',
    'Hostel Essentials': 'Furniture & Hostel',
    'Vehicles & Cycles': 'Vehicles & Cycles',
    'Vehicles': 'Vehicles & Cycles',
    'Cycles': 'Vehicles & Cycles',
    'Clothing & Fashion': 'Clothing & Fashion',
    'Clothing': 'Clothing & Fashion',
    'Footwear': 'Clothing & Fashion',
    'Accessories & Misc': 'Accessories & Misc',
    'Accessories': 'Accessories & Misc',
    'Misc': 'Accessories & Misc',
    'Travel': 'Travel',
    'Travel / Tickets': 'Travel',
    'Travel Tickets': 'Travel',
    'Trip': 'Travel',
    'Other': 'Other',
    'Others': 'Other',
    'General': 'Other',
  };

  static const Map<String, String> _serviceCategoryMap = {
    'Academic & Tutoring': 'Academic & Tutoring',
    'Academic Help': 'Academic & Tutoring',
    'Tutoring': 'Academic & Tutoring',
    'Tech & Design': 'Tech & Design',
    'Tech Help': 'Tech & Design',
    'Design': 'Tech & Design',
    'Errands & Help': 'Errands & Help',
    'Delivery': 'Errands & Help',
    'Hostel Help': 'Errands & Help',
    'Creative & Media': 'Creative & Media',
    'Photography': 'Creative & Media',
    'Event Work': 'Creative & Media',
    'Other': 'Other',
    'Others': 'Other',
    'General': 'Other',
  };

  static final Map<String, IconData> _iconMap = {
    for (final category in [
      ..._sellCategoryDefinitions,
      ..._serviceCategoryDefinitions,
    ])
      category.name.toLowerCase(): category.icon,
  };

  static List<Category> getSellCategoryDefinitions() =>
      List.unmodifiable(_sellCategoryDefinitions);

  static List<Category> getServiceCategoryDefinitions() =>
      List.unmodifiable(_serviceCategoryDefinitions);

  static List<String> getSellCategories() => List.unmodifiable(
    _sellCategoryDefinitions.map((category) => category.name).toList(),
  );

  static List<String> getServiceCategories() => List.unmodifiable(
    _serviceCategoryDefinitions.map((category) => category.name).toList(),
  );

  static List<String> categoriesForType(String type) {
    switch (type.trim().toLowerCase()) {
      case 'sell':
      case 'rent':
        return getSellCategories();
      case 'service':
        return getServiceCategories();
      default:
        return const [];
    }
  }

  static bool typeUsesCategories(String type) {
    final normalizedType = type.trim().toLowerCase();
    return normalizedType == 'sell' ||
        normalizedType == 'rent' ||
        normalizedType == 'service';
  }

  static String defaultCategoryForType(String type) {
    final categories = categoriesForType(type);
    if (categories.isEmpty) {
      return '';
    }
    return categories.first;
  }

  static String normalizeCategory(String? rawCategory, {required String type}) {
    final normalizedType = type.trim().toLowerCase();
    if (!typeUsesCategories(normalizedType)) {
      return '';
    }

    final raw = (rawCategory ?? '').trim();
    final categoryMap = _categoryMapForType(normalizedType);

    if (raw.isEmpty) {
      return 'Other';
    }

    for (final entry in categoryMap.entries) {
      if (entry.key.toLowerCase() == raw.toLowerCase()) {
        return entry.value;
      }
    }

    return 'Other';
  }

  static List<String> queryValuesForCategory(
    String category, {
    required String type,
  }) {
    final normalized = normalizeCategory(category, type: type);
    if (normalized.isEmpty) {
      return const [];
    }

    final values = <String>{normalized};
    final categoryMap = _categoryMapForType(type.trim().toLowerCase());

    for (final entry in categoryMap.entries) {
      if (entry.value == normalized) {
        values.add(entry.key);
      }
    }

    return values.toList();
  }

  static IconData iconForCategory(String category) {
    return _iconMap[category.trim().toLowerCase()] ?? Icons.more_horiz;
  }

  static Map<String, String> _categoryMapForType(String type) {
    switch (type) {
      case 'sell':
      case 'rent':
        return _marketplaceCategoryMap;
      case 'service':
        return _serviceCategoryMap;
      default:
        return const {};
    }
  }
}
