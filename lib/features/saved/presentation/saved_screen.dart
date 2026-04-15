import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/favorite_service.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/utils/firestore_trace_utils.dart';
import '../../../shared/utils/listing_data_utils.dart';
import '../../../shared/utils/listing_location_utils.dart';
import '../../../shared/utils/navigation_trace_utils.dart';
import '../../../shared/utils/listing_price_utils.dart';
import '../../../shared/utils/time_utils.dart';
import '../../../shared/widgets/listing_card.dart';
import '../../../shared/widgets/service_card.dart';
import '../../requests/widgets/request_detail_sheet.dart';
import '../../services/widgets/service_detail_sheet.dart';

class SavedScreen extends StatelessWidget {
  final List<Map<String, dynamic>>? initialSavedItems;
  const SavedScreen({super.key, this.initialSavedItems});

  Future<void> _toggleFavorite(String listingId, bool isCurrentlySaved) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FavoriteService.toggle(user.uid, listingId);
  }

  Future<void> _cleanupMissingSavedRefs(
    User user,
    Iterable<String> listingIds,
  ) async {
    for (final listingId in listingIds) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('saved_items')
            .doc(listingId)
            .delete();
      } catch (e, stack) {
        debugPrint('ERROR: $e');
        debugPrint('STACK: $stack');
      }
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchSavedListings(
    List<String> listingIds,
  ) async {
    final listingDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (var index = 0; index < listingIds.length; index += 10) {
      final end = index + 10 > listingIds.length
          ? listingIds.length
          : index + 10;
      final chunk = listingIds.sublist(index, end);
      final snapshot = await FirebaseFirestore.instance
          .collection('listings')
          .where(FieldPath.documentId, whereIn: chunk)
          .tracedGet('listings saved chunk ${chunk.join(",")}');
      listingDocs.addAll(snapshot.docs);
    }

    listingDocs.sort(
      (a, b) => listingIds.indexOf(a.id).compareTo(listingIds.indexOf(b.id)),
    );

    return listingDocs;
  }

  int getFeedCrossAxisCount(double width) {
    if (width < 600) return 2; // mobile (UNCHANGED behavior)
    if (width < 900) return 3; // tablet
    if (width < 1200) return 4; // small desktop
    return 5; // large desktop
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: true,
        centerTitle: false,
        titleSpacing: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        title: Row(
          children: [
            const SizedBox(width: 8),
            Text(
              'Saved Items',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: user == null
          ? const Center(child: Text('Please log in to see saved items.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('saved_items')
                  .orderBy('saved_at', descending: true)
                  .tracedSnapshots(
                    'users/${user.uid}/saved_items saved screen',
                  ),
              builder: (context, savedSnapshot) {
                final isWaitingStream =
                    savedSnapshot.connectionState == ConnectionState.waiting &&
                    !savedSnapshot.hasData;
                final hasInitial =
                    initialSavedItems != null && initialSavedItems!.isNotEmpty;

                if (isWaitingStream && !hasInitial) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (savedSnapshot.hasError) {
                  return Center(child: Text(savedSnapshot.error.toString()));
                }

                List<String> listingIds = [];
                if (savedSnapshot.hasData) {
                  final savedDocs = savedSnapshot.data?.docs ?? [];
                  listingIds = savedDocs.map((d) => d.id).toList();
                } else if (isWaitingStream && hasInitial) {
                  listingIds = initialSavedItems!
                      .map((item) => item['id'] as String)
                      .toList();
                }

                if (listingIds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 48,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No saved items yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Items you like will appear here',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return FutureBuilder<
                  List<QueryDocumentSnapshot<Map<String, dynamic>>>
                >(
                  future: _fetchSavedListings(listingIds),
                  builder: (context, listingsSnapshot) {
                    final isWaitingFuture =
                        listingsSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        !listingsSnapshot.hasData;

                    if (isWaitingFuture && !hasInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (listingsSnapshot.hasError) {
                      return Center(
                        child: Text(listingsSnapshot.error.toString()),
                      );
                    }

                    List<Map<String, dynamic>> displayItems = [];

                    if (listingsSnapshot.hasData) {
                      final listingDocs = listingsSnapshot.data ?? const [];
                      final foundIds = listingDocs.map((doc) => doc.id).toSet();
                      final missingIds = listingIds
                          .where((listingId) => !foundIds.contains(listingId))
                          .toList();
                      final validListings = listingDocs
                          .cast<DocumentSnapshot>();

                      if (missingIds.isNotEmpty) {
                        Future.microtask(
                          () => _cleanupMissingSavedRefs(user, missingIds),
                        );
                      }

                      final sortedListings =
                          ListingDataUtils.sortDocsByCreatedAtDesc(
                            validListings,
                          );
                      displayItems = sortedListings
                          .map(
                            (doc) => {
                              ...(doc.data() as Map<String, dynamic>? ??
                                  const {}),
                              'id': doc.id,
                            },
                          )
                          .toList();
                    } else if (isWaitingFuture && hasInitial) {
                      displayItems = initialSavedItems!;
                    }

                    if (displayItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 48,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No saved items yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Items you like will appear here',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        int crossAxisCount = 2;
                        if (width > 1200) {
                          crossAxisCount = 5;
                        } else if (width > 900) {
                          crossAxisCount = 4;
                        } else if (width > 600) {
                          crossAxisCount = 3;
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 12.0,
                                crossAxisSpacing: 12.0,
                                childAspectRatio: 0.7,
                              ),
                          itemCount: displayItems.length,
                          itemBuilder: (context, index) {
                            final data = displayItems[index];
                            final docId = data['id'] as String;

                            final title =
                                data['title'] as String? ?? 'Untitled';
                            final priceDisplay =
                                ListingPriceUtils.resolveDisplayPrice(data);
                            final displayLocation =
                                ListingLocationUtils.resolveDisplayLocation(
                                  data,
                                );

                            final listingType = ListingDataUtils.resolveType(
                              data,
                            );
                            final isUrgent =
                                data['is_urgent'] as bool? ?? false;
                            final images = ListingDataUtils.resolveImages(data);

                            String tagText = ListingPriceUtils.resolveBadgeText(
                              data,
                            );
                            if (isUrgent) {
                              tagText = 'URGENT';
                            }

                            Color tagColor =
                                ListingPriceUtils.resolveBadgeColor(data);
                            if (tagText == 'URGENT') {
                              tagColor = AppColors.error;
                            }

                            return listingType == 'service'
                                ? ServiceCard(
                                    key: ValueKey(docId),
                                    data: data,
                                    docId: docId,
                                    isFavorite: true,
                                    onFavoriteTap: () =>
                                        _toggleFavorite(docId, true),
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) =>
                                            ServiceDetailSheet(data: data),
                                      );
                                    },
                                  )
                                : ListingCard(
                                    key: ValueKey(docId),
                                    title: title,
                                    priceText: priceDisplay.text,
                                    imageUrls: images,
                                    location: displayLocation,
                                    timeAgo: TimeUtils.formatTimeAgo(
                                      ListingDataUtils.resolveCreatedAt(data),
                                    ),
                                    tagText: tagText,
                                    tagColor: tagColor,
                                    isFavorite: true,
                                    isNegotiable:
                                        data['allow_negotiation'] == true,
                                    heroTag: docId,
                                    onFavoriteTap: () =>
                                        _toggleFavorite(docId, true),
                                    onTap: () {
                                      if (listingType == 'request') {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) =>
                                              RequestDetailSheet(data: data),
                                        );
                                      } else {
                                        context.tracedPush(
                                          '/listing/${docId}',
                                          extra: {'enableHero': true},
                                        );
                                      }
                                    },
                                  );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
