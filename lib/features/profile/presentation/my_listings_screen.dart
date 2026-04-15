import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/favorite_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/utils/firestore_trace_utils.dart';
import '../../../shared/widgets/listing_card.dart';
import '../../../shared/utils/listing_data_utils.dart';
import '../../../shared/utils/listing_delete_utils.dart';
import '../../../shared/utils/listing_location_utils.dart';
import '../../../shared/utils/navigation_trace_utils.dart';
import '../../../shared/utils/listing_price_utils.dart';
import '../../../shared/utils/seller_identity_utils.dart';
import '../../../shared/utils/time_utils.dart';

class MyListingsScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialListings;
  const MyListingsScreen({super.key, this.initialListings});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  // Optimistic UI state
  final Map<String, String> _optimisticStatuses = {};
  final Set<String> _updatingIds = {};
  final Set<String> _deletingIds = {};

  Future<void> _updateListingStatus(
    BuildContext context,
    String listingId,
    String newStatus,
    String currentStatus,
  ) async {
    // Prevent double tap
    if (_updatingIds.contains(listingId)) return;

    final messenger = ScaffoldMessenger.of(context);

    // 1. Set Optimistic State
    setState(() {
      _optimisticStatuses[listingId] = newStatus;
      _updatingIds.add(listingId);
    });

    try {
      // 2. Perform Firestore Update
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId)
          .update({'status': newStatus});
    } catch (e) {
      // 4. Revert On Error
      if (mounted) {
        setState(() {
          _optimisticStatuses.remove(listingId);
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // 5. Cleanup
      if (mounted) {
        setState(() {
          _updatingIds.remove(listingId);
        });
      }
    }
  }

  Future<void> _deleteListing(BuildContext context, String listingId) async {
    if (_deletingIds.contains(listingId)) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _deletingIds.add(listingId));
      try {
        await ListingDeleteUtils.deleteListing(listingId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _deletingIds.remove(listingId));
        }
      }
    }
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
              'My Listings',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: user == null
                  ? const Center(
                      child: Text('Please log in to see your listings.'),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: SellerIdentityUtils.queryListingsForSeller(
                        user.uid,
                      ).tracedSnapshots('listings my listings ${user.uid}'),
                      builder: (context, snapshot) {
                        final isWaiting =
                            snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData;
                        final hasInitialFallback =
                            widget.initialListings != null &&
                            widget.initialListings!.isNotEmpty;

                        if (isWaiting && !hasInitialFallback) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text(snapshot.error.toString()));
                        }

                        List<Map<String, dynamic>> displayItems = [];

                        if (snapshot.hasData) {
                          final rawDocs =
                              snapshot.data?.docs
                                  .cast<DocumentSnapshot>()
                                  .toList() ??
                              [];
                          final sorted = ListingDataUtils.sortDocsByCreatedAtDesc(
                            rawDocs.where((doc) {
                              final data =
                                  doc.data() as Map<String, dynamic>? ??
                                  const {};
                              return ListingDataUtils.isMarketplaceListingType(
                                data,
                              );
                            }),
                          );
                          displayItems = sorted
                              .map(
                                (doc) => {
                                  ...(doc.data() as Map<String, dynamic>? ??
                                      const {}),
                                  'id': doc.id,
                                },
                              )
                              .toList();
                        } else if (isWaiting && hasInitialFallback) {
                          displayItems = widget.initialListings!;
                        }

                        if (displayItems.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'No sell or rent listings yet',
                                    style: AppTypography.bodyLarge,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        context.tracedPush('/post?type=sell'),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Post a Listing'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('saved_items')
                              .tracedSnapshots(
                                'users/${user.uid}/saved_items my listings',
                              ),
                          builder: (context, savedSnapshot) {
                            final savedIds =
                                savedSnapshot.data?.docs
                                    .map((savedDoc) => savedDoc.id)
                                    .toSet() ??
                                <String>{};

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
                                        ListingPriceUtils.resolveDisplayPrice(
                                          data,
                                        );
                                    final displayLocation =
                                        ListingLocationUtils.resolveDisplayLocation(
                                          data,
                                        );

                                    final listingType =
                                        ListingDataUtils.resolveType(data);
                                    final isUrgent =
                                        data['is_urgent'] as bool? ?? false;
                                    final firestoreStatus =
                                        data['status'] as String? ??
                                        'available';

                                    final status =
                                        _optimisticStatuses[docId] ??
                                        firestoreStatus;
                                    final isUpdating = _updatingIds.contains(
                                      docId,
                                    );
                                    final isDeleting = _deletingIds.contains(
                                      docId,
                                    );
                                    final isBusy = isUpdating || isDeleting;
                                    final isFavorite = savedIds.contains(docId);

                                    final images =
                                        ListingDataUtils.resolveImages(data);

                                    String tagText =
                                        ListingPriceUtils.resolveBadgeText(
                                          data,
                                        );
                                    Color tagColor =
                                        ListingPriceUtils.resolveBadgeColor(
                                          data,
                                        );

                                    if (status == 'sold') {
                                      tagText = 'SOLD';
                                      tagColor = AppColors.error;
                                    } else if (status == 'rented') {
                                      tagText = 'RENTED';
                                      tagColor = AppColors.primary;
                                    } else if (isUrgent) {
                                      tagText = 'URGENT';
                                      tagColor = AppColors.error;
                                    } else if (tagText == 'RENT') {
                                      tagColor = AppColors.primary;
                                    }

                                    final topMenu = IgnorePointer(
                                      ignoring: isBusy,
                                      child: PopupMenuButton<String>(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                        onSelected: (value) async {
                                          if (value == 'view') {
                                            final result = await context
                                                .tracedPush(
                                                  '/listing/${docId}',
                                                  extra: {'enableHero': true},
                                                );
                                            if (result == 'updated') {
                                              if (mounted) {
                                                setState(() {});
                                              }
                                            }
                                          } else if (value == 'sold' ||
                                              value == 'available' ||
                                              value == 'rented') {
                                            _updateListingStatus(
                                              context,
                                              docId,
                                              value,
                                              status,
                                            );
                                          } else if (value == 'delete') {
                                            _deleteListing(context, docId);
                                          }
                                        },
                                        itemBuilder: (context) {
                                          final isSell = listingType == 'sell';
                                          final isRent = listingType == 'rent';
                                          final isActive =
                                              status == 'available';
                                          final isCompleted =
                                              status == 'sold' ||
                                              status == 'rented';

                                          return [
                                            const PopupMenuItem(
                                              value: 'view',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.visibility,
                                                  size: 20,
                                                ),
                                                title: Text('View Details'),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                            if (isActive && isSell)
                                              const PopupMenuItem(
                                                value: 'sold',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.sell,
                                                    size: 20,
                                                  ),
                                                  title: Text('Mark as Sold'),
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                ),
                                              ),
                                            if (isActive && isRent)
                                              const PopupMenuItem(
                                                value: 'rented',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.key,
                                                    size: 20,
                                                  ),
                                                  title: Text('Mark as Rented'),
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                ),
                                              ),
                                            if (isCompleted)
                                              const PopupMenuItem(
                                                value: 'available',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.check_circle_outline,
                                                    size: 20,
                                                  ),
                                                  title: Text(
                                                    'Mark as Available',
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                ),
                                              ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.delete,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                                  size: 20,
                                                ),
                                                title: Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.error,
                                                  ),
                                                ),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ];
                                        },
                                        child: SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: isBusy
                                              ? const Center(
                                                  child: SizedBox(
                                                    height: 12,
                                                    width: 12,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color:
                                                              AppColors.primary,
                                                        ),
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.more_vert,
                                                  size: 20,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                        ),
                                      ),
                                    );

                                    final cardWidget = ListingCard(
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
                                      isFavorite: isFavorite,
                                      isNegotiable:
                                          data['allow_negotiation'] == true,
                                      heroTag: docId,
                                      onFavoriteTap: () async {
                                        await FavoriteService.toggle(
                                          user.uid,
                                          docId,
                                        );
                                      },
                                      onTap: isBusy
                                          ? null
                                          : () async {
                                              final result = await context.push(
                                                '/listing/$docId',
                                                extra: {'enableHero': true},
                                              );
                                              if (result == 'updated') {
                                                if (mounted) {
                                                  setState(() {});
                                                }
                                              }
                                            },
                                      topMenu: topMenu,
                                    );

                                    return RepaintBoundary(
                                      child: isBusy
                                          ? IgnorePointer(
                                              ignoring: true,
                                              child: Opacity(
                                                opacity: 0.6,
                                                child: cardWidget,
                                              ),
                                            )
                                          : cardWidget,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
