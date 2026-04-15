import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/constants/campus_constants.dart';
import '../../../shared/utils/firestore_trace_utils.dart';
import '../../../shared/utils/listing_data_utils.dart';
import '../../../shared/utils/navigation_trace_utils.dart';
import '../../../shared/utils/seller_identity_utils.dart';
import '../../../shared/widgets/custom_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String? _name;
  String? _campus;
  String? _photoUrl;
  String? _selectedHeroId;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _photoUrl = user.photoURL;

        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .tracedGet('users/${user.uid} profile preload');
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _name = data['name'] ?? user.displayName;
          _campus = data['campus_id'];
        } else {
          _name = user.displayName;
          _campus = null;
        }

        // Data will now be fetched in real-time via StreamBuilder in the build method.
      }
    } catch (e) {
      // Keep rendering fallback profile data if the preload fails.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('campus_id');
      await FirebaseAuth.instance.signOut();
      /*if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }*/
    } catch (e) {
      // ignore
    }

    /*try {
      if (!kIsWeb) {
        await GoogleSignIn().disconnect();
      }
    } catch (e) {
      // ignore completely
    }*/

    if (context.mounted) {
      context.tracedGo('/login');
    }
  }

  void _navigateToEditProfile() async {
    final result = await context.tracedPush('/edit-profile');
    if (result == true && mounted) {
      _fetchUserData(); // Refresh data if something changed
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceMuted = onSurface.withValues(alpha: 0.72);
    final onSurfaceHint = onSurface.withValues(alpha: 0.58);
    final logoAsset = isDark
        ? 'assets/branding/nexlist_logo_dark.png'
        : 'assets/branding/nexlist_logo.png';

    if (_isLoading) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isDark ? Border.all(color: theme.dividerColor) : null,
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        backgroundImage: _photoUrl != null
                            ? NetworkImage(_photoUrl ?? '')
                            : null,
                        child: _photoUrl == null
                            ? Text(
                                (_name ?? 'U').isNotEmpty
                                    ? (_name ?? 'U')[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _name ?? 'User',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 14, color: onSurfaceMuted),
                      const SizedBox(width: 4),
                      Text(
                        getCampusName(_campus),
                        style: AppTypography.bodyMedium.copyWith(
                          color: onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        SellerIdentityUtils.queryListingsForSeller(
                          FirebaseAuth.instance.currentUser?.uid ?? '',
                        ).tracedSnapshots(
                          'listings seller stats ${FirebaseAuth.instance.currentUser?.uid ?? ""}',
                        ),
                    builder: (context, snapshot) {
                      int listingsCount = 0;
                      int requestsCount = 0;
                      int servicesCount = 0;
                      int activeCount = 0;

                      final docs = snapshot.data?.docs ?? const [];
                      if (docs.isNotEmpty) {
                        for (var doc in docs) {
                          final data =
                              doc.data() as Map<String, dynamic>? ?? const {};
                          final status = data['status'] ?? 'available';
                          final isListing =
                              ListingDataUtils.isMarketplaceListingType(data);
                          final isService = ListingDataUtils.isServiceType(
                            data,
                          );
                          final isRequest = ListingDataUtils.isRequestType(
                            data,
                          );
                          final isSupportedProfileType =
                              isListing || isService || isRequest;

                          if (isListing) {
                            listingsCount++;
                          }

                          if (isService) {
                            servicesCount++;
                          }

                          if (isRequest) {
                            requestsCount++;
                          }

                          if (isSupportedProfileType && status == 'available') {
                            activeCount++;
                          }
                        }
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn(
                            listingsCount.toString(),
                            'LISTINGS',
                          ),
                          _buildStatColumn(
                            servicesCount.toString(),
                            'SERVICES',
                          ),
                          _buildStatColumn(
                            requestsCount.toString(),
                            'REQUESTS',
                          ),
                          _buildStatColumn(activeCount.toString(), 'ACTIVE'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildMyListingsPreview(
              FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              Icons.build_outlined,
              'My Services',
              AppColors.primary,
              onTap: () => context.tracedPush('/my-services'),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              Icons.receipt_long,
              'My Requests',
              AppColors.primary,
              onTap: () => context.tracedPush('/my-requests'),
            ),
            const SizedBox(height: 12),
            _buildSavedItemsPreview(
              FirebaseAuth.instance.currentUser?.uid ?? '',
            ),

            const SizedBox(height: 32),

            // Account Settings
            Text(
              'ACCOUNT SETTINGS',
              style: TextStyle(
                color: onSurfaceHint,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isDark ? Border.all(color: theme.dividerColor) : null,
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    Icons.person_outline,
                    'Edit Profile',
                    onTap: _navigateToEditProfile,
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  _buildSettingsTile(
                    Icons.location_on_outlined,
                    'Change Campus',
                    onTap: null,
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  _buildSettingsTile(
                    Icons.notifications_outlined,
                    'Notifications',
                    onTap: () => context.tracedPush('/notifications'),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  _buildSettingsTile(
                    Icons.help_outline,
                    'Help & Support',
                    onTap: _showSupportBottomSheet,
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  _buildSettingsTile(
                    Icons.info_outline,
                    'About Nexlist',
                    onTap: () => context.tracedPush('/about'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // Log Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48), // Spacing for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String val, String label) {
    final onSurfaceMuted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.72);

    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: onSurfaceMuted,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    IconData icon,
    String label,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceHint = onSurface.withValues(alpha: 0.58);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? theme.colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: theme.dividerColor)
            : null,
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, color: onSurface),
        ),
        trailing: Icon(Icons.chevron_right, color: onSurfaceHint),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceHint = onSurface.withValues(alpha: 0.58);

    return ListTile(
      leading: Icon(icon, color: onSurface),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w500, color: onSurface),
      ),
      trailing: Icon(Icons.chevron_right, color: onSurfaceHint),
      onTap: onTap,
    );
  }

  Widget _buildMyListingsPreview(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: SellerIdentityUtils.queryListingsForSeller(
        userId,
      ).tracedSnapshots('listings my listings preview $userId'),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildActionCard(
            Icons.inventory_2,
            'My Listings',
            AppColors.primary,
            onTap: () => context.tracedPush('/my-listings'),
          );
        }

        final docs = snapshot.data!.docs;
        final sortedDocs = ListingDataUtils.sortDocsByCreatedAtDesc(
          docs
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? const {};
                return ListingDataUtils.isMarketplaceListingType(data);
              })
              .toList()
              .cast<DocumentSnapshot>(),
        );

        if (sortedDocs.isEmpty) {
          return _buildActionCard(
            Icons.inventory_2,
            'My Listings',
            AppColors.primary,
            onTap: () => context.tracedPush('/my-listings'),
          );
        }

        final latestDocs = sortedDocs.take(3).toList();
        final rawDocs = sortedDocs
            .map(
              (doc) => {
                ...(doc.data() as Map<String, dynamic>? ?? const {}),
                'id': doc.id,
              },
            )
            .toList();

        return _buildPreviewCard(
          icon: Icons.inventory_2,
          title: 'My Listings',
          items: latestDocs,
          allData: rawDocs,
          targetRoute: '/my-listings',
        );
      },
    );
  }

  Widget _buildSavedItemsPreview(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('saved_items')
          .orderBy('saved_at', descending: true)
          .limit(3)
          .tracedSnapshots('users/$userId/saved_items profile preview'),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildActionCard(
            Icons.favorite,
            'Saved Items',
            AppColors.primary,
            onTap: () => context.tracedPush('/saved'),
          );
        }

        final savedIds = snapshot.data!.docs.map((d) => d.id).toList();

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('listings')
              .where(FieldPath.documentId, whereIn: savedIds)
              .tracedGet('listings saved preview ${savedIds.join(",")}'),
          builder: (context, futureSnapshot) {
            if (!futureSnapshot.hasData || futureSnapshot.data!.docs.isEmpty) {
              return _buildActionCard(
                Icons.favorite,
                'Saved Items',
                AppColors.primary,
                onTap: () => context.tracedPush('/saved'),
              );
            }

            final itemDocs = futureSnapshot.data!.docs;
            // Maintain order of saved items
            final sortedItems = itemDocs.toList()
              ..sort(
                (a, b) =>
                    savedIds.indexOf(a.id).compareTo(savedIds.indexOf(b.id)),
              );

            final allData = sortedItems
                .map(
                  (doc) => {
                    ...(doc.data() as Map<String, dynamic>? ?? const {}),
                    'id': doc.id,
                  },
                )
                .toList();

            return _buildPreviewCard(
              icon: Icons.favorite,
              title: 'Saved Items',
              items: sortedItems,
              allData: allData,
              targetRoute: '/saved',
            );
          },
        );
      },
    );
  }

  Widget _buildPreviewCard({
    required IconData icon,
    required String title,
    required List<DocumentSnapshot> items,
    required List<Map<String, dynamic>> allData,
    required String targetRoute,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: theme.dividerColor) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.tracedPush(
                  targetRoute,
                  extra: {'initialData': allData},
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(items.length, (index) {
                final doc = items[index];
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final images = ListingDataUtils.resolveImages(data);
                final String? imageUrl =
                    images.isNotEmpty && images.first != 'placeholder'
                    ? images.first
                    : null;

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == items.length - 1 ? 0 : 12,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedHeroId = doc.id);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        context
                            .tracedPush(
                              targetRoute,
                              extra: {'initialData': allData},
                            )
                            .then((_) {
                              if (mounted) {
                                setState(() => _selectedHeroId = null);
                              }
                            });
                      });
                    },
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl != null
                            ? Hero(
                                tag: _selectedHeroId == doc.id
                                    ? doc.id
                                    : 'preview_${doc.id}',
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                  ),
                                  errorWidget: (context, url, err) => Container(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              )
                            : Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.image,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _showSupportBottomSheet() {
    const FABVisibilityNotification(true).dispatch(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final onSurface = Theme.of(context).colorScheme.onSurface;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Help & Support',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.bug_report, color: onSurface),
                  title: Text(
                    'Report a Bug',
                    style: TextStyle(color: onSurface),
                  ),
                  onTap: () {
                    context.pop();
                    context.tracedPush('/support-form?type=bug');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.lightbulb_outline, color: onSurface),
                  title: Text(
                    'Suggest a Feature',
                    style: TextStyle(color: onSurface),
                  ),
                  onTap: () {
                    context.pop();
                    context.tracedPush('/support-form?type=suggestion');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.help_outline, color: onSurface),
                  title: Text('Need Help', style: TextStyle(color: onSurface)),
                  onTap: () {
                    context.pop();
                    context.tracedPush('/support-form?type=help');
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) {
        const FABVisibilityNotification(false).dispatch(context);
      }
    });
  }
}
