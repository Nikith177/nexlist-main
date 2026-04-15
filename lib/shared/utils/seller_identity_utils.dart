import 'package:cloud_firestore/cloud_firestore.dart';

class SellerIdentityUtils {
  static String? resolveSellerId(Map<String, dynamic> data) {
    final sellerId = _clean(data['sellerId']);
    if (sellerId != null) {
      return sellerId;
    }

    // TODO: Remove seller_id fallback after full data migration
    return _clean(data['seller_id']);
  }

  static Query<Map<String, dynamic>> queryListingsForSeller(String userId) {
    return FirebaseFirestore.instance
        .collection('listings')
        .where(
          Filter.or(
            Filter('sellerId', isEqualTo: userId),
            // TODO: Remove seller_id fallback after full data migration
            Filter('seller_id', isEqualTo: userId),
          ),
        );
  }

  static String? _clean(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}
