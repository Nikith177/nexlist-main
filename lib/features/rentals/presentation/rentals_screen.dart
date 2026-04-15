import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/favorite_service.dart';
import '../../../core/theme/app_input_decoration.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../config/listing_categories.dart';
import '../../../shared/widgets/listing_card.dart';
import '../../../shared/widgets/service_card.dart';
import '../../../shared/utils/firestore_trace_utils.dart';
import '../../../shared/utils/listing_category_utils.dart';
import '../../../shared/utils/listing_data_utils.dart';
import '../../../shared/utils/listing_location_utils.dart';
import '../../../shared/utils/navigation_trace_utils.dart';
import '../../../shared/utils/listing_price_utils.dart';
import '../../../shared/utils/time_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../requests/widgets/request_detail_sheet.dart';
import '../../services/widgets/service_detail_sheet.dart';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';
  String? _campusId;
  Stream<QuerySnapshot>? _rentalsStream;

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
          _rentalsStream = _buildRentalsStream();
        });
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .tracedGet('users/${user.uid} rentals campus lookup');
      if (userDoc.exists && mounted) {
        final fetchedCampusId = userDoc.data()?['campus_id'] as String?;
        if (fetchedCampusId != null) {
          await prefs.setString('campus_id', fetchedCampusId);
          setState(() {
            _campusId = fetchedCampusId;
            _rentalsStream = _buildRentalsStream();
          });
        }
      }
    }
  }

  Future<void> _toggleFavorite(String listingId, bool isCurrentlySaved) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FavoriteService.toggle(user.uid, listingId);
  }

  Stream<QuerySnapshot> _buildRentalsStream() {
    return FirebaseFirestore.instance
        .collection('listings')
        .where('campus_id', isEqualTo: _campusId)
        .where('status', isEqualTo: 'available')
        .where('type', isEqualTo: 'rent')
        .limit(50)
        .tracedSnapshots('listings rentals feed campus=$_campusId');
  }

  @override
  Widget build(BuildContext context) {
    if (_campusId == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Rentals', style: AppTypography.h2),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                children: [
                  // Search Bar
                  SizedBox(
                    height: 44,
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: buildInputDecoration(
                        'Search rental items',
                        fillColor: AppColors.surface,
                        focusColor: AppColors.primary,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: AppColors.textHint,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 20,
                        ),
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textHint,
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
                            text: 'All',
                            isSelected: selectedCategory == 'All',
                            onTap: () =>
                                setState(() => selectedCategory = 'All'),
                          ),
                          ...ListingCategories.getSellCategories().map(
                            (c) => _FilterPill(
                              text: c,
                              isSelected: selectedCategory == c,
                              onTap: () => setState(() => selectedCategory = c),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),

          // Grid of Listings
          _rentalsStream == null
              ? const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: _rentalsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      final error = snapshot.error.toString();
                      if (error.contains('FAILED_PRECONDITION') ||
                          error.contains('requires an index')) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Text(
                              'App setup incomplete. Please contact admin.',
                            ),
                          ),
                        );
                      }
                      return const SliverToBoxAdapter(
                        child: Center(child: Text('Something went wrong')),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    final categoryFilteredDocs = selectedCategory == 'All'
                        ? docs
                        : docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return ListingCategoryUtils.matchesCategory(
                              data,
                              selectedCategory,
                            );
                          }).toList();

                    final filteredDocs = searchQuery.isEmpty
                        ? categoryFilteredDocs
                        : categoryFilteredDocs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final title = (data['title'] ?? '')
                                .toString()
                                .toLowerCase();
                            final description = (data['description'] ?? '')
                                .toString()
                                .toLowerCase();
                            final category =
                                ListingCategoryUtils.resolveCategory(
                                  data,
                                ).toLowerCase();

                            return title.contains(searchQuery) ||
                                description.contains(searchQuery) ||
                                category.contains(searchQuery);
                          }).toList();

                    final sortedDocs = ListingDataUtils.sortDocsByCreatedAtDesc(
                      filteredDocs.cast<DocumentSnapshot>(),
                    );

                    if (sortedDocs.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              searchQuery.isEmpty
                                  ? 'No rental listings found.'
                                  : 'No results found',
                              style: AppTypography.bodyLarge,
                            ),
                          ),
                        ),
                      );
                    }

                    final currentUser = FirebaseAuth.instance.currentUser;
                    return StreamBuilder<QuerySnapshot>(
                      stream: currentUser != null
                          ? FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser.uid)
                                .collection('saved_items')
                                .tracedSnapshots(
                                  'users/${currentUser.uid}/saved_items rentals',
                                )
                          : const Stream.empty(),
                      builder: (context, savedSnapshot) {
                        final savedDocIds =
                            savedSnapshot.data?.docs.map((d) => d.id).toSet() ??
                            <String>{};

                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          sliver: SliverLayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.crossAxisExtent;
                              int crossAxisCount = 2;
                              if (width > 1200) {
                                crossAxisCount = 5;
                              } else if (width > 900) {
                                crossAxisCount = 4;
                              } else if (width > 600) {
                                crossAxisCount = 3;
                              }

                              return SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      mainAxisSpacing: 12.0,
                                      crossAxisSpacing: 12.0,
                                      childAspectRatio: 0.7,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final doc = sortedDocs[index];
                                  final data = {
                                    ...(doc.data() as Map<String, dynamic>),
                                    'id': doc.id,
                                  };

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

                                  final imageUrls =
                                      ListingDataUtils.resolveImages(data);

                                  String tagText =
                                      ListingPriceUtils.resolveBadgeText(data);
                                  if (isUrgent) {
                                    tagText = 'URGENT';
                                  }

                                  Color tagColor =
                                      ListingPriceUtils.resolveBadgeColor(data);
                                  if (tagText == 'URGENT') {
                                    tagColor = AppColors.error;
                                  }

                                  final isFavorite = savedDocIds.contains(
                                    doc.id,
                                  );

                                  return listingType.toLowerCase() == 'service'
                                      ? ServiceCard(
                                          key: ValueKey(doc.id),
                                          data: data,
                                          docId: doc.id,
                                          isFavorite: isFavorite,
                                          onFavoriteTap: () => _toggleFavorite(
                                            doc.id,
                                            isFavorite,
                                          ),
                                          onTap: () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              builder: (_) =>
                                                  ServiceDetailSheet(
                                                    data: data,
                                                  ),
                                            );
                                          },
                                        )
                                      : ListingCard(
                                          key: ValueKey(doc.id),
                                          title: title,
                                          priceText: priceDisplay.text,
                                          imageUrls: imageUrls,
                                          location: displayLocation,
                                          timeAgo: TimeUtils.formatTimeAgo(
                                            data['created_at'],
                                          ),
                                          tagText: tagText,
                                          tagColor: tagColor,
                                          isFavorite: isFavorite,
                                          isNegotiable:
                                              data['allow_negotiation'] == true,
                                          heroTag: doc.id,
                                          onFavoriteTap: () => _toggleFavorite(
                                            doc.id,
                                            isFavorite,
                                          ),
                                          onTap: () {
                                            if (listingType.toLowerCase() ==
                                                'request') {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                                builder: (_) =>
                                                    RequestDetailSheet(
                                                      data: data,
                                                    ),
                                              );
                                            } else {
                                              context.tracedPush(
                                                '/listing/${doc.id}',
                                                extra: {'enableHero': true},
                                              );
                                            }
                                          },
                                        );
                                }, childCount: sortedDocs.length),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),

          // Spacing for BottomNav
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryDark
                    : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
