import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/colors.dart';
import '../../../shared/utils/firestore_trace_utils.dart';
import '../../../shared/utils/listing_data_utils.dart';
import '../../../shared/utils/listing_delete_utils.dart';
import '../../../shared/utils/navigation_trace_utils.dart';
import '../../../shared/utils/seller_identity_utils.dart';
import '../../requests/widgets/request_card.dart';
import '../../requests/widgets/request_detail_sheet.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final Set<String> _deletingIds = {};

  Future<void> _deleteListing(BuildContext context, String listingId) async {
    if (_deletingIds.contains(listingId)) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: const Text('Are you sure you want to delete this request?'),
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
              'My Requests',
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
                      child: Text('Please log in to see your requests.'),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: SellerIdentityUtils.queryListingsForSeller(
                        user.uid,
                      ).tracedSnapshots('listings my requests ${user.uid}'),
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
                        final requestDocs =
                            ListingDataUtils.sortDocsByCreatedAtDesc(
                              rawDocs.where((doc) {
                                final data =
                                    doc.data() as Map<String, dynamic>? ??
                                    const {};
                                return ListingDataUtils.isRequestType(data);
                              }),
                            );

                        if (requestDocs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.help_outline,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No requests posted yet',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Post a request to see it here',
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
                                      context.tracedPush('/post?type=request'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Post a Request'),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: requestDocs.length,
                          itemBuilder: (context, index) {
                            final doc = requestDocs[index];
                            final data = {
                              ...(doc.data() as Map<String, dynamic>? ??
                                  const {}),
                              'id': doc.id,
                            };
                            final isDeleting = _deletingIds.contains(doc.id);

                            final topMenu = IgnorePointer(
                              ignoring: isDeleting,
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
                                          RequestDetailSheet(data: data),
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
                                  child: isDeleting
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
                                opacity: isDeleting ? 0.6 : 1.0,
                                child: RequestCard(
                                  data: data,
                                  onTap: isDeleting
                                      ? () {}
                                      : () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (_) =>
                                                RequestDetailSheet(data: data),
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
