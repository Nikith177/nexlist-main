import 'package:cloud_firestore/cloud_firestore.dart';

class ListingDataUtils {
  static String resolveType(Map<String, dynamic> data) {
    return (data['type'] ?? data['listing_type'] ?? '').toString();
  }

  static bool isMarketplaceListingType(Map<String, dynamic> data) {
    final type = resolveType(data);
    return type == 'sell' || type == 'rent';
  }

  static bool isServiceType(Map<String, dynamic> data) {
    return resolveType(data) == 'service';
  }

  static bool isRequestType(Map<String, dynamic> data) {
    return resolveType(data) == 'request';
  }

  static bool isUrgent(Map<String, dynamic> data) {
    final raw = data['is_urgent'] ?? data['urgent'];
    if (raw == true) return true;
    if (raw is String && raw.toLowerCase() == 'true') return true;
    if (raw == 1) return true;
    return false;
  }

  static DateTime resolveCreatedAt(Map<String, dynamic> data) {
    final dynamic createdAt = data['createdAt'];
    final dynamic createdAtOld = data['created_at'];

    final value = createdAt ?? createdAtOld;

    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static List<String> resolveImages(Map<String, dynamic> data) {
    final raw = data['imageUrls'] ?? data['image_urls'];
    if (raw is Iterable) {
      final urls = raw
          .map((value) => value?.toString().trim() ?? '')
          .where((url) => url.isNotEmpty && url != 'placeholder')
          .toList();
      if (urls.isNotEmpty) {
        return urls;
      }
    }

    final singleImage = (data['imageUrl'] ?? data['image_url'])
        ?.toString()
        .trim();
    if (singleImage != null && singleImage.isNotEmpty) {
      return [singleImage];
    }

    return const [];
  }

  static List<T> sortDocsByCreatedAtDesc<T extends DocumentSnapshot>(
    Iterable<T> docs,
  ) {
    final sorted = docs.toList();
    sorted.sort(compareDocsByCreatedAtDesc);
    return sorted;
  }

  static List<T> sortDocsByUrgentThenCreatedAtDesc<T extends DocumentSnapshot>(
    Iterable<T> docs,
  ) {
    final sorted = docs.toList();
    sorted.sort(compareDocsByUrgentThenCreatedAtDesc);
    return sorted;
  }

  static int compareDocsByCreatedAtDesc(
    DocumentSnapshot a,
    DocumentSnapshot b,
  ) {
    final aData = a.data() as Map<String, dynamic>? ?? const {};
    final bData = b.data() as Map<String, dynamic>? ?? const {};
    final aMillis = resolveCreatedAt(aData).millisecondsSinceEpoch;
    final bMillis = resolveCreatedAt(bData).millisecondsSinceEpoch;
    return bMillis.compareTo(aMillis);
  }

  static int compareDocsByUrgentThenCreatedAtDesc(
    DocumentSnapshot a,
    DocumentSnapshot b,
  ) {
    final aData = a.data() as Map<String, dynamic>? ?? const {};
    final bData = b.data() as Map<String, dynamic>? ?? const {};
    final aUrgent = isUrgent(aData);
    final bUrgent = isUrgent(bData);

    if (aUrgent != bUrgent) {
      return aUrgent ? -1 : 1;
    }

    final aMillis = resolveCreatedAt(aData).millisecondsSinceEpoch;
    final bMillis = resolveCreatedAt(bData).millisecondsSinceEpoch;
    return bMillis.compareTo(aMillis);
  }
}
