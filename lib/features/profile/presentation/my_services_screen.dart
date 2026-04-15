import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/colors.dart';
import '../../../shared/utils/navigation_trace_utils.dart';
import '../../../shared/utils/listing_data_utils.dart';
import '../../../shared/utils/listing_delete_utils.dart';
import '../../../shared/utils/seller_identity_utils.dart';
import '../../../shared/utils/firestore_trace_utils.dart';
import '../../../shared/widgets/service_card.dart';
import '../../services/widgets/service_detail_sheet.dart';

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  final Map<String, String> _optimisticStatuses = {};
  final Set<String> _updatingIds = {};
  final Set<String> _deletingIds = {};

  Future<void> _updateListingStatus(
    BuildContext context,
    String listingId,
    String newStatus,
  ) async {
    if (_updatingIds.contains(listingId)) return;
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _optimisticStatuses[listingId] = newStatus;
      _updatingIds.add(listingId);
    });

    try {
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId)
          .update({'status': newStatus});
    } catch (e) {
      if (mounted) {
        setState(() => _optimisticStatuses.remove(listingId));
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingIds.remove(listingId));
    }
  }

  Future<void> _deleteListing(BuildContext context, String listingId) async {
    if (_deletingIds.contains(listingId)) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this service?'),
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
              'My Services',
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
                      child: Text('Please log in to see your services.'),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: SellerIdentityUtils.queryListingsForSeller(
                        user.uid,
                      ).tracedSnapshots('listings my services ${user.uid}'),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text(snapshot.error.toString()));
                        }

                        final rawDocs =
                            snapshot.data?.docs
                                .cast<DocumentSnapshot>()
                                .toList() ??
                            [];
                        final services =
                            ListingDataUtils.sortDocsByCreatedAtDesc(
                              rawDocs.where((doc) {
                                final data =
                                    doc.data() as Map<String, dynamic>? ??
                                    const {};
                                return ListingDataUtils.isServiceType(data);
                              }),
                            );

                        if (services.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.build_outlined,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No services posted yet',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Post a service to see it here',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      context.tracedPush('/post?type=service'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Post a Service'),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            final doc = services[index];
                            final data = {
                              ...(doc.data() as Map<String, dynamic>? ??
                                  const {}),
                              'id': doc.id,
                            };

                            final firestoreStatus =
                                data['status'] as String? ?? 'available';
                            final status =
                                _optimisticStatuses[doc.id] ?? firestoreStatus;
                            final isUpdating = _updatingIds.contains(doc.id);
                            final isDeleting = _deletingIds.contains(doc.id);
                            final isBusy = isUpdating || isDeleting;

                            final topMenu = IgnorePointer(
                              ignoring: isBusy,
                              child: PopupMenuButton<String>(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.zero,
                                onSelected: (value) async {
                                  if (value == 'view') {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) =>
                                          ServiceDetailSheet(data: data),
                                    );
                                  } else if (value == 'unavailable' ||
                                      value == 'available') {
                                    _updateListingStatus(
                                      context,
                                      doc.id,
                                      value,
                                    );
                                  } else if (value == 'delete') {
                                    _deleteListing(context, doc.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: ListTile(
                                      leading: Icon(Icons.visibility, size: 20),
                                      title: Text('View Details'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  if (status == 'available')
                                    const PopupMenuItem(
                                      value: 'unavailable',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.pause_circle_outline,
                                          size: 20,
                                        ),
                                        title: Text('Mark as Unavailable'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  if (status != 'available')
                                    const PopupMenuItem(
                                      value: 'available',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.check_circle_outline,
                                          size: 20,
                                        ),
                                        title: Text('Mark as Available'),
                                        contentPadding: EdgeInsets.zero,
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
                                ],
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: isBusy
                                      ? const Center(
                                          child: SizedBox(
                                            height: 12,
                                            width: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
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

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Opacity(
                                opacity: isBusy ? 0.6 : 1.0,
                                child: ServiceCard(
                                  key: ValueKey(doc.id),
                                  data: data,
                                  docId: doc.id,
                                  isFavorite: false,
                                  onFavoriteTap: () {},
                                  onTap: isBusy
                                      ? () {}
                                      : () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (_) =>
                                                ServiceDetailSheet(data: data),
                                          );
                                        },
                                  topMenu: topMenu,
                                ),
                              ),
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
