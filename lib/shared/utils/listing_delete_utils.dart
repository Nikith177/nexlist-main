import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'firestore_trace_utils.dart';
import 'listing_data_utils.dart';

class ListingDeleteUtils {
  static const int _maxDeleteAttempts = 3;

  static Future<void> deleteListing(String listingId) async {
    Object? lastError;

    for (var attempt = 1; attempt <= _maxDeleteAttempts; attempt++) {
      try {
        await _deleteListingOnce(listingId);
        return;
      } catch (error) {
        lastError = error;

        final shouldRetry =
            error is FirebaseException &&
            (error.code == 'unavailable' || error.code == 'deadline-exceeded');
        if (!shouldRetry || attempt == _maxDeleteAttempts) {
          break;
        }

        await Future.delayed(Duration(milliseconds: 400 * attempt));
      }
    }

    throw Exception(_formatDeleteError(lastError));
  }

  static Future<void> _deleteListingOnce(String listingId) async {
    final docRef = FirebaseFirestore.instance
        .collection('listings')
        .doc(listingId);
    final snap = await docRef.tracedGet('listings/$listingId delete lookup');

    if (!snap.exists) return;

    final data = snap.data() ?? const <String, dynamic>{};
    final imageUrls = ListingDataUtils.resolveImages(data);

    await docRef.delete();
    await _deleteImagesBestEffort(imageUrls);
    await _cleanupSavedItemsBestEffort(listingId);
  }

  static String _formatDeleteError(Object? error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
        case 'deadline-exceeded':
          return 'Delete failed because the network is unavailable. Please try again.';
        case 'permission-denied':
          return 'Delete was rejected. Please refresh and try again.';
        default:
          final message = error.message?.trim();
          if (message != null && message.isNotEmpty) {
            return 'Delete failed: $message';
          }
          return 'Delete failed: ${error.code}';
      }
    }

    return 'Delete failed. Please try again.';
  }

  static Future<void> _deleteImagesBestEffort(List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        await FirebaseStorage.instance.refFromURL(url).delete();
      } catch (e, stack) {
        debugPrint('ERROR: $e');
        debugPrint('STACK: $stack');
      }
    }
  }

  static Future<void> _cleanupSavedItemsBestEffort(String listingId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collectionGroup('saved_items')
          .where('listing_id', isEqualTo: listingId)
          .tracedGet(
            'collectionGroup(saved_items) listing_id=$listingId cleanup',
          );

      for (final doc in query.docs) {
        try {
          await doc.reference.delete();
        } catch (e, stack) {
          debugPrint('ERROR: $e');
          debugPrint('STACK: $stack');
        }
      }
    } catch (e, stack) {
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stack');
    }
  }
}
