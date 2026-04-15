import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/utils/firestore_trace_utils.dart';

class FavoriteService {
  static Future<void> toggle(String uid, String listingId) async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('saved_items')
        .doc(listingId);

    final doc = await ref.tracedGet(
      'users/$uid/saved_items/$listingId favorite',
    );

    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'listing_id': listingId,
        'saved_at': FieldValue.serverTimestamp(),
      });
    }
  }
}
