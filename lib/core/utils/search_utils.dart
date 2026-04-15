import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/utils/listing_category_utils.dart';

List<DocumentSnapshot> filterListings(
  List<DocumentSnapshot> docs,
  String query,
) {
  if (query.isEmpty) return docs;

  final q = query.toLowerCase();

  return docs.where((doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final title = (data['title'] ?? '').toString().toLowerCase();
    final description = (data['description'] ?? '').toString().toLowerCase();
    final category = ListingCategoryUtils.resolveCategory(data).toLowerCase();

    return title.contains(q) || description.contains(q) || category.contains(q);
  }).toList();
}
