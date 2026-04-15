import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_input_decoration.dart';
import '../../../core/theme/typography.dart';
import '../../../config/listing_categories.dart';
import 'package:nexlist_mobile/shared/widgets/content_state_widgets.dart';
import '../../../shared/layouts/app_content_wrapper.dart';
import '../../../shared/utils/firestore_trace_utils.dart';
import '../../../shared/utils/listing_category_utils.dart';
import '../../../shared/utils/listing_data_utils.dart';
import '../../../shared/utils/navigation_trace_utils.dart';
import '../../../core/utils/search_utils.dart';
import '../../../shared/widgets/custom_bottom_nav_bar.dart';
import '../../../shared/widgets/service_card.dart';
import '../widgets/service_detail_sheet.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String selectedCategory = 'All Services';
  String searchQuery = '';
  String? _campusId;
  Stream<QuerySnapshot>? _servicesStream;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserCampus();
  }

  Future<void> _loadUserCampus() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedCampusId = prefs.getString('campus_id');

    if (cachedCampusId != null) {
      if (mounted) {
        setState(() {
          _campusId = cachedCampusId;
          _servicesStream = _buildServicesStream();
        });
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .tracedGet('users/${user.uid} services campus lookup');
      if (userDoc.exists && mounted) {
        final fetchedCampusId = userDoc.data()?['campus_id'] as String?;
        if (fetchedCampusId != null) {
          await prefs.setString('campus_id', fetchedCampusId);
          setState(() {
            _campusId = fetchedCampusId;
            _servicesStream = _buildServicesStream();
          });
        }
      }
    }
  }

  Stream<QuerySnapshot> _buildServicesStream() {
    return FirebaseFirestore.instance
        .collection('listings')
        .where('campus_id', isEqualTo: _campusId)
        .where('status', isEqualTo: 'available')
        .limit(50)
        .tracedSnapshots('listings services feed campus=$_campusId');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        if (_campusId == null) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(color: colors.primary),
            ),
          );
        }

        final isDesktop = width >= 900;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: isDesktop
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: colors.onSurface,
                    onPressed: () => context.tracedGo('/home'),
                  )
                : null,
            title: Text(
              'Services',
              style: AppTypography.h2.copyWith(color: colors.onSurface),
            ),
            centerTitle: true,
          ),
          body: AppContentWrapper(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
                  child: Column(
                    children: [
                      // Search Bar
                      SizedBox(
                        height: 44,
                        child: TextField(
                          controller: _searchController,
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(color: colors.onSurface),
                          decoration: buildInputDecoration(
                            'Search services',
                            fillColor: colors.surface,
                            focusColor: colors.primary,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 8,
                              ),
                              child: Icon(
                                Icons.search,
                                size: 20,
                                color: colors.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      size: 20,
                                      color: colors.onSurface.withValues(
                                        alpha: 0.55,
                                      ),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: colors.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value.trim().toLowerCase();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (searchQuery.isEmpty) ...[
                        // Category Pills
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FilterPill(
                                text: 'All Services',
                                isSelected: selectedCategory == 'All Services',
                                onTap: () => setState(
                                  () => selectedCategory = 'All Services',
                                ),
                              ),
                              ...ListingCategories.getServiceCategories().map(
                                (c) => _FilterPill(
                                  text: c,
                                  isSelected: selectedCategory == c,
                                  onTap: () =>
                                      setState(() => selectedCategory = c),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),

                // Grid of Listings
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    color: colors.primary,
                    child: _servicesStream == null
                        ? Center(
                            child: CircularProgressIndicator(
                              color: colors.primary,
                            ),
                          )
                        : StreamBuilder<QuerySnapshot>(
                            stream: _servicesStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: const [
                                    SizedBox(height: 140),
                                    SizedBox(
                                      height: 240,
                                      child: ErrorStateView(),
                                    ),
                                  ],
                                );
                              }

                              final hasData =
                                  snapshot.hasData && snapshot.data != null;
                              final isWaiting =
                                  snapshot.connectionState ==
                                  ConnectionState.waiting;

                              List<dynamic> services = [];
                              if (hasData) {
                                final rawDocs = snapshot.data!.docs
                                    .cast<DocumentSnapshot>()
                                    .toList();
                                final servicesDocs = rawDocs.where((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>? ??
                                      const {};
                                  return ListingDataUtils.resolveType(data) ==
                                      'service';
                                }).toList();
                                final categoryFilteredDocs =
                                    selectedCategory == 'All Services'
                                    ? servicesDocs
                                    : servicesDocs.where((doc) {
                                        final data =
                                            doc.data()
                                                as Map<String, dynamic>? ??
                                            const {};
                                        return ListingCategoryUtils.matchesCategory(
                                          data,
                                          selectedCategory,
                                        );
                                      }).toList();
                                final filteredDocs = filterListings(
                                  categoryFilteredDocs,
                                  searchQuery,
                                );
                                services =
                                    ListingDataUtils.sortDocsByCreatedAtDesc(
                                      filteredDocs,
                                    );
                              }

                              // ✅ CASE 1 — REAL DATA EXISTS → ALWAYS SHOW
                              if (hasData && services.isNotEmpty) {
                                return ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    80,
                                  ),
                                  itemCount: services.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12.0,
                                          top: 8.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Available Services',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: colors.onSurface,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (services.length < 3)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      colors.primaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'NEW ON CAMPUS',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: colors
                                                        .onPrimaryContainer,
                                                  ),
                                                ),
                                              )
                                            else
                                              Text(
                                                '${services.length} ${services.length == 1 ? 'service' : 'services'}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: colors.onSurface
                                                      .withValues(alpha: 0.68),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }

                                    final doc = services[index - 1];
                                    final data = {
                                      ...(doc.data() as Map<String, dynamic>),
                                      'id': doc.id,
                                    };

                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: index == services.length
                                            ? 0.0
                                            : 12.0,
                                      ),
                                      child: ServiceCard(
                                        data: data,
                                        docId: doc.id,
                                        isFavorite: false,
                                        onFavoriteTap: () {},
                                        onTap: () {
                                          const FABVisibilityNotification(
                                            true,
                                          ).dispatch(context);
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            useRootNavigator: false,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) =>
                                                ServiceDetailSheet(data: data),
                                          ).whenComplete(() {
                                            if (context.mounted) {
                                              const FABVisibilityNotification(
                                                false,
                                              ).dispatch(context);
                                            }
                                          });
                                        },
                                      ),
                                    );
                                  },
                                );
                              }

                              // ✅ CASE 2 — STILL LOADING (including first empty emission)
                              if (isWaiting) {
                                return const VerticalCardSkeletonList();
                              }

                              // ✅ CASE 3 — REAL EMPTY STATE (NOT loading)
                              if (hasData && services.isEmpty) {
                                return ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const SizedBox(height: 120),
                                    SizedBox(
                                      height: 280,
                                      child: EmptyStateView(
                                        icon: Icons
                                            .miscellaneous_services_outlined,
                                        title: searchQuery.isEmpty
                                            ? 'No services yet'
                                            : 'No services found',
                                        subtitle: searchQuery.isEmpty
                                            ? 'Offer your skills!'
                                            : 'Try a different search or pull to refresh.',
                                        action: searchQuery.isEmpty
                                            ? ElevatedButton.icon(
                                                onPressed: () =>
                                                    context.tracedPush(
                                                      '/post?type=service',
                                                    ),
                                                icon: const Icon(Icons.add),
                                                label: const Text(
                                                  'Post a Service',
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      colors.primary,
                                                  foregroundColor:
                                                      colors.onPrimary,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 24,
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return const SizedBox.shrink();
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback? onTap;

  const _FilterPill({required this.text, this.isSelected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? colors.onPrimary : colors.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
