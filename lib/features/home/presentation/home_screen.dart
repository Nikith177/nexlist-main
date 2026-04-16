import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/campus_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/app_input_decoration.dart';
import '../../../core/theme/typography.dart';
import '../../../core/services/favorite_service.dart';
import '../../../shared/layouts/app_content_wrapper.dart';
import '../../../shared/utils/listing_category_utils.dart';
import '../../../shared/utils/listing_data_utils.dart';
import '../../../shared/utils/listing_location_utils.dart';
import '../../../shared/utils/listing_price_utils.dart';
import '../../../shared/utils/firestore_trace_utils.dart';
import '../../../shared/utils/navigation_trace_utils.dart';
import '../../../shared/utils/phone_gate_utils.dart';
import '../../../shared/utils/seller_identity_utils.dart';
import '../../../shared/utils/time_utils.dart';
import 'package:nexlist_mobile/shared/widgets/content_state_widgets.dart';
import '../../../shared/widgets/custom_bottom_nav_bar.dart';
import '../../../shared/widgets/listing_card.dart';
import '../../requests/widgets/request_detail_sheet.dart';
import '../../services/widgets/service_detail_sheet.dart';
import 'widgets/home_widgets.dart';
import '../../../shared/models/filter_state.dart';
import '../../../shared/widgets/glass_filter_panel.dart';
import '../../../core/constants/campus_hostels.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _CampusActivityEntry {
  final DocumentSnapshot doc;
  final Map<String, dynamic> data;
  final String type;
  final int createdAtMillis;

  const _CampusActivityEntry({
    required this.doc,
    required this.data,
    required this.type,
    required this.createdAtMillis,
  });
}

class _CampusActivityItemData {
  final String id;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final String priceText;
  final String timeText;
  final String locationText;
  final String tagText;
  final Color tagColor;

  const _CampusActivityItemData({
    required this.id,
    required this.data,
    required this.imageUrl,
    required this.priceText,
    required this.timeText,
    required this.locationText,
    required this.tagText,
    required this.tagColor,
  });
}

class _StudentsNeedItemData {
  final String id;
  final Map<String, dynamic> data;

  const _StudentsNeedItemData({required this.id, required this.data});
}

class _GlassHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _GlassHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: theme.scaffoldBackgroundColor.withValues(
            alpha: isDark ? 0.70 : 0.85,
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _GlassHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _HomeScreenState extends State<HomeScreen> {
  static final Set<String> _claimCheckCompletedUsers = <String>{};

  String selectedFilter = 'all';
  String? selectedCategoryId;
  String searchQuery = '';
  String? _campusId;
  String? _profileLoadError;
  IdentityProfile? _claimIdentity;
  int _claimableListingCount = 0;
  bool _isClaimCardDismissed = false;
  bool _isClaimingListings = false;
  FilterState _filterState = const FilterState();

  Timer? _searchDebounce;

  StreamSubscription<QuerySnapshot>? _savedItemsSubscription;
  StreamSubscription<QuerySnapshot>? _feedSubscription;
  Set<String> _savedDocIds = <String>{};
  List<DocumentSnapshot> _allDocs = const <DocumentSnapshot>[];
  List<DocumentSnapshot> _finalDocs = const <DocumentSnapshot>[];
  List<_CampusActivityItemData> _activityItems =
      const <_CampusActivityItemData>[];
  List<_StudentsNeedItemData> _studentsNeedItems =
      const <_StudentsNeedItemData>[];
  Object? _feedError;
  bool _isFeedLoading = true;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserCampus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForClaimableListings());
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _savedItemsSubscription?.cancel();
    _feedSubscription?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Query _buildBaseQuery() {
    return FirebaseFirestore.instance
        .collection('listings')
        .where('campus_id', isEqualTo: _campusId)
        .where('status', isEqualTo: 'available')
        .limit(50);
  }

  void _initStreams() {
    if (_campusId == null) return;
    _subscribeSavedItems();
    _setupFeedStream();
  }

  void _setupFeedStream() {
    if (_campusId == null) return;

    setState(() {
      _feedError = null;
      _isFeedLoading = _allDocs.isEmpty;
    });

    _feedSubscription?.cancel();
    _feedSubscription = _buildBaseQuery()
        .tracedSnapshots('listings home feed campus=$_campusId')
        .listen(
          (snapshot) {
            if (!mounted) {
              return;
            }

            setState(() {
              _allDocs = snapshot.docs.cast<DocumentSnapshot>().toList(
                growable: false,
              );
              _feedError = null;
              _isFeedLoading = false;
              _recomputeFeedSections();
            });
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!mounted) {
              return;
            }

            setState(() {
              _feedError = error;
              _isFeedLoading = false;
              _allDocs = const <DocumentSnapshot>[];
              _finalDocs = const <DocumentSnapshot>[];
              _activityItems = const <_CampusActivityItemData>[];
              _studentsNeedItems = const <_StudentsNeedItemData>[];
            });
          },
        );
  }

  void _subscribeSavedItems() {
    _savedItemsSubscription?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _savedDocIds = <String>{};
      });
      return;
    }

    _savedItemsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_items')
        .tracedSnapshots('users/${user.uid}/saved_items home')
        .listen(
          (snapshot) {
            if (!mounted) {
              return;
            }

            setState(() {
              _savedDocIds = snapshot.docs.map((doc) => doc.id).toSet();
            });
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!mounted) {
              return;
            }

            setState(() {
              _savedDocIds = <String>{};
            });
          },
        );
  }

  int? _parsePrice(dynamic price) {
    if (price == null) return null;
    if (price is num) return price.toInt();
    if (price is String) {
      final cleaned = price.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleaned.isEmpty) return null;
      return int.tryParse(cleaned);
    }
    return null;
  }

  List<DocumentSnapshot> _applyFeedFilters(List<DocumentSnapshot> docs) {
    // PRICE RANGE GUARD
    if (_filterState.minPrice != null &&
        _filterState.maxPrice != null &&
        _filterState.minPrice! > _filterState.maxPrice!) {
      return docs;
    }

    var filtered = docs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? const {};
          final type = ListingDataUtils.resolveType(data);

          // TYPE FILTER
          bool matchesType;
          switch (selectedFilter) {
            case 'sell':
              matchesType = type == 'sell';
              break;
            case 'rent':
              matchesType = type == 'rent';
              break;
            case 'passout':
              matchesType = data['is_passout_sale'] == true;
              break;
            case 'services':
              matchesType = type == 'service';
              break;
            case 'requests':
              matchesType = type == 'request';
              break;
            case 'all':
            default:
              matchesType = type == 'sell' || type == 'rent';
          }

          // CATEGORY FILTER
          bool matchesCategory = true;
          final categoryId = selectedCategoryId;
          if (categoryId != null && categoryId != 'All') {
            matchesCategory = ListingCategoryUtils.matchesCategory(
              data,
              categoryId,
            );
          }

          // SEARCH FILTER
          bool matchesSearch = true;
          if (searchQuery.isNotEmpty) {
            final q = searchQuery.toLowerCase();
            final title = (data['title'] ?? '').toString().toLowerCase();
            final description = (data['description'] ?? '')
                .toString()
                .toLowerCase();
            final category = ListingCategoryUtils.resolveCategory(
              data,
            ).toLowerCase();
            matchesSearch =
                title.contains(q) ||
                description.contains(q) ||
                category.contains(q);
          }

          // PRICE FILTER
          bool matchesPrice = true;
          final minPrice = _filterState.minPrice;
          final maxPrice = _filterState.maxPrice;
          if (minPrice != null || maxPrice != null) {
            final price = _parsePrice(data['price']);
            if (price != null) {
              if (minPrice != null && price < minPrice) matchesPrice = false;
              if (maxPrice != null && price > maxPrice) matchesPrice = false;
            } else {
              // No price field — exclude if price filter is active
              if (minPrice != null || maxPrice != null) matchesPrice = false;
            }
          }

          // LOCATION FILTER
          bool matchesLocation = true;
          if (_filterState.locations.isNotEmpty) {
            final locationTag = data['location_tag'];
            if (locationTag == null ||
                !_filterState.locations.contains(locationTag)) {
              matchesLocation = false;
            }
          }

          return matchesType &&
              matchesCategory &&
              matchesSearch &&
              matchesPrice &&
              matchesLocation;
        })
        .toList(growable: false);

    // SORTING (On a copy to avoid mutation)
    final sortedList = List<DocumentSnapshot>.from(filtered);

    switch (_filterState.sort) {
      case 'price_low':
        sortedList.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>? ?? {};
          final bData = b.data() as Map<String, dynamic>? ?? {};
          final aPrice = _parsePrice(aData['price']) ?? 0;
          final bPrice = _parsePrice(bData['price']) ?? 0;

          final result = aPrice.compareTo(bPrice);
          if (result != 0) return result;

          // fallback: newest first
          return _parseCreatedAt(bData).compareTo(_parseCreatedAt(aData));
        });
        break;
      case 'price_high':
        sortedList.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>? ?? {};
          final bData = b.data() as Map<String, dynamic>? ?? {};
          final aPrice = _parsePrice(aData['price']) ?? 0;
          final bPrice = _parsePrice(bData['price']) ?? 0;

          final result = bPrice.compareTo(aPrice);
          if (result != 0) return result;

          // fallback: newest first
          return _parseCreatedAt(bData).compareTo(_parseCreatedAt(aData));
        });
        break;
      case 'newest':
      default:
        // Default order from stream (already newest-first from Firestore)
        break;
    }

    return sortedList;
  }

  int _parseCreatedAt(Map<String, dynamic> data) {
    final raw = data['created_at'];
    if (raw is Timestamp) return raw.millisecondsSinceEpoch;
    if (raw is num) return raw.toInt();
    return 0;
  }

  void _recomputeFeedSections() {
    final showBrowseSections = searchQuery.isEmpty && selectedFilter == 'all';

    _activityItems = showBrowseSections
        ? _buildCampusActivityItems(_allDocs)
        : const <_CampusActivityItemData>[];

    _studentsNeedItems = showBrowseSections
        ? _buildStudentsNeedItems(_allDocs)
        : const <_StudentsNeedItemData>[];

    _finalDocs = _applyFeedFilters(_allDocs);

    if (selectedFilter == 'all') {
      for (final doc in _finalDocs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final type = ListingDataUtils.resolveType(data);
        if (type != 'sell' && type != 'rent') {
          debugPrint('INVALID TYPE IN FEED: $type');
        }
      }
    }
  }

  Future<String?> _loadCampusId() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedCampusId = prefs.getString('campus_id');
    if (cachedCampusId != null && cachedCampusId.trim().isNotEmpty) {
      return cachedCampusId.trim();
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    for (var i = 0; i < 10; i++) {
      final userDoc = await docRef.tracedGet(
        'users/${user.uid} campus lookup attempt ${i + 1}',
      );
      final fetchedCampusId = (userDoc.data()?['campus_id'] as String?)?.trim();
      if (fetchedCampusId != null && fetchedCampusId.isNotEmpty) {
        await prefs.setString('campus_id', fetchedCampusId);
        return fetchedCampusId;
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }

    return null;
  }

  Future<void> _loadUserCampus() async {
    try {
      final campusId = await _loadCampusId();
      if (!mounted) {
        return;
      }

      if (campusId == null) {
        setState(() {
          _profileLoadError = 'Setting up your account… please wait';
        });
        return;
      }

      setState(() {
        _profileLoadError = null;
        _campusId = campusId;
      });
      _initStreams();
    } catch (e, stack) {
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stack');
      if (!mounted) {
        return;
      }

      setState(() {
        _profileLoadError = 'Setting up your account… please wait';
      });
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _findClaimableListings({
    required String userId,
    required String phone,
  }) async {
    // Firestore needs the default single-field index on listings.contactPhone
    // for this query to remain efficient in production.
    final snapshot = await FirebaseFirestore.instance
        .collection('listings')
        .where('contactPhone', isEqualTo: phone)
        .tracedGet('listings by contactPhone=$phone home claim lookup');

    return snapshot.docs.where((doc) {
      final sellerId = SellerIdentityUtils.resolveSellerId(doc.data());
      return sellerId != userId;
    }).toList();
  }

  String? _resolveClaimPhone(IdentityProfile identity) {
    final phone = PhoneGateUtils.normalizePhone(identity.phone);
    if (phone == null || phone.isEmpty) {
      return null;
    }

    return phone;
  }

  Future<void> _checkForClaimableListings({bool force = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    if (_claimCheckCompletedUsers.contains(user.uid) && !force) {
      return;
    }

    final identity = await PhoneGateUtils.ensureIdentity(
      context,
      interactive: false,
    );
    if (!mounted || identity == null) {
      return;
    }

    final claimPhone = _resolveClaimPhone(identity);
    if (claimPhone == null) {
      return;
    }

    try {
      final matches = await _findClaimableListings(
        userId: user.uid,
        phone: claimPhone,
      );
      final hasValidMatches = matches.isNotEmpty;
      if (hasValidMatches) {
        _claimCheckCompletedUsers.add(user.uid);
      }
      if (!mounted) {
        return;
      }

      if (matches.isEmpty) {
        setState(() {
          _claimIdentity = null;
          _claimableListingCount = 0;
        });
        return;
      }

      setState(() {
        _claimIdentity = identity;
        _claimableListingCount = matches.length;
        _isClaimCardDismissed = false;
      });
    } catch (e, stack) {
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stack');
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to check for claimable listings'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              unawaited(_checkForClaimableListings(force: true));
            },
          ),
        ),
      );
    }
  }

  Future<void> _claimListings(IdentityProfile _) async {
    if (_isClaimingListings) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final isReady = await PhoneGateUtils.ensureUserReadyForAction(
      context,
      promptClaim: false,
    );
    if (!mounted || !isReady) {
      return;
    }

    final identity = await PhoneGateUtils.ensureIdentity(
      context,
      interactive: false,
    );
    if (!mounted || identity == null) {
      return;
    }

    final claimPhone = _resolveClaimPhone(identity);
    if (claimPhone == null) {
      return;
    }

    _isClaimingListings = true;

    try {
      final matches = await _findClaimableListings(
        userId: user.uid,
        phone: claimPhone,
      );
      if (!mounted) {
        return;
      }

      if (matches.isEmpty) {
        setState(() {
          _claimIdentity = null;
          _claimableListingCount = 0;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No listings are available to claim')),
        );
        return;
      }

      await PhoneGateUtils.claimListings(
        user.uid,
        matches,
        userName: identity.name,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _claimIdentity = null;
        _claimableListingCount = 0;
        _isClaimCardDismissed = true;
      });
      _setupFeedStream();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listings claimed successfully')),
      );
    } catch (e, stack) {
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stack');
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to claim listings. Please try again.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              unawaited(_claimListings(identity));
            },
          ),
        ),
      );
    } finally {
      _isClaimingListings = false;
    }
  }

  Future<void> _toggleFavorite(String listingId, bool isCurrentlySaved) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FavoriteService.toggle(user.uid, listingId);
  }

  void _openHomeItem(
    BuildContext context,
    String listingId,
    Map<String, dynamic> data, {
    bool enableHero = true,
  }) {
    final type = ListingDataUtils.resolveType(data);

    if (type == 'request') {
      const FABVisibilityNotification(true).dispatch(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => RequestDetailSheet(data: {...data, 'id': listingId}),
      ).whenComplete(() {
        if (context.mounted) {
          const FABVisibilityNotification(false).dispatch(context);
        }
      });
      return;
    }

    if (type == 'service') {
      const FABVisibilityNotification(true).dispatch(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ServiceDetailSheet(data: {...data, 'id': listingId}),
      ).whenComplete(() {
        if (context.mounted) {
          const FABVisibilityNotification(false).dispatch(context);
        }
      });
      return;
    }

    context.tracedPush(
      '/listing/$listingId',
      extra: {'enableHero': enableHero},
    );
  }

  List<_CampusActivityItemData> _buildCampusActivityItems(
    List<DocumentSnapshot> allDocs,
  ) {
    final activityEntries = <_CampusActivityEntry>[];

    for (final doc in allDocs) {
      final data = doc.data() as Map<String, dynamic>? ?? const {};
      final type = ListingDataUtils.resolveType(data);
      if (type != 'sell' && type != 'rent') {
        continue;
      }

      final createdAtMillis =
          ListingDataUtils.resolveCreatedAt(data)?.millisecondsSinceEpoch ?? 0;

      activityEntries.add(
        _CampusActivityEntry(
          doc: doc,
          data: data,
          type: type,
          createdAtMillis: createdAtMillis,
        ),
      );
    }

    activityEntries.sort(
      (a, b) => b.createdAtMillis.compareTo(a.createdAtMillis),
    );

    return activityEntries.map((entry) {
      final images = ListingDataUtils.resolveImages(entry.data);
      final imageUrl = images.isNotEmpty ? images.first : null;

      return _CampusActivityItemData(
        id: entry.doc.id,
        data: entry.data,
        imageUrl: imageUrl,
        priceText: ListingPriceUtils.resolveDisplayPrice(entry.data).text,
        timeText: TimeUtils.formatTimeAgo(
          ListingDataUtils.resolveCreatedAt(entry.data),
        ),
        locationText: _resolveCampusActivityLocation(entry.data),
        tagText: ListingPriceUtils.resolveBadgeText(entry.data),
        tagColor: ListingPriceUtils.resolveBadgeColor(entry.data),
      );
    }).toList();
  }

  String _shortCampusActivityTitle(Map<String, dynamic> data) {
    final rawTitle = _normalizeCampusActivityText(data['title'] as String?);
    if (rawTitle.isEmpty) {
      return '';
    }

    final shortTitle = rawTitle
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .take(2)
        .join(' ');

    if (shortTitle.isEmpty) {
      return '';
    }

    return _capitalizeCampusActivityWord(shortTitle);
  }

  String _resolveCampusActivityLocation(Map<String, dynamic> data) {
    return ListingLocationUtils.resolveShortCleanLocation(data);
  }

  String _normalizeCampusActivityText(String? value) {
    return (value ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _capitalizeCampusActivityWord(String value) {
    if (value.isEmpty) {
      return '';
    }

    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String _buildCampusActivityText(_CampusActivityItemData item) {
    final title = _shortCampusActivityTitle(item.data);
    if (title.isEmpty) {
      return '';
    }

    final location = item.locationText.trim();

    if (location.isEmpty) {
      return title;
    }

    return '$title • $location';
  }

  List<_StudentsNeedItemData> _buildStudentsNeedItems(
    List<DocumentSnapshot> allDocs,
  ) {
    final requests = allDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? const {};
      final type = data['type'];
      return type is String && type.toLowerCase() == 'request';
    }).toList();

    requests.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>? ?? const {};
      final dataB = b.data() as Map<String, dynamic>? ?? const {};

      final urgentA = ListingDataUtils.isUrgent(dataA);
      final urgentB = ListingDataUtils.isUrgent(dataB);

      if (urgentA != urgentB) {
        return urgentA ? -1 : 1;
      }

      final createdAtA = dataA['createdAt'];
      final createdAtB = dataB['createdAt'];

      final timeA = createdAtA is Timestamp
          ? createdAtA.millisecondsSinceEpoch
          : 0;
      final timeB = createdAtB is Timestamp
          ? createdAtB.millisecondsSinceEpoch
          : 0;

      return timeB.compareTo(timeA);
    });

    return requests.map((doc) {
      return _StudentsNeedItemData(
        id: doc.id,
        data: doc.data() as Map<String, dynamic>? ?? const {},
      );
    }).toList();
  }

  bool get _shouldShowClaimCard =>
      _claimIdentity != null &&
      _claimableListingCount > 0 &&
      !_isClaimCardDismissed;

  Widget _buildClaimCard() {
    final identity = _claimIdentity;
    if (identity == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceMuted = onSurface.withValues(alpha: 0.72);
    final listingLabel = _claimableListingCount == 1 ? 'listing' : 'listings';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You have $_claimableListingCount $listingLabel waiting for you',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Claim them to manage, edit and receive contacts',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: _isClaimingListings
                      ? null
                      : () => unawaited(_claimListings(identity)),
                  child: const Text('Claim'),
                ),
              ),
              SizedBox(
                height: 40,
                child: TextButton(
                  onPressed: _isClaimingListings
                      ? null
                      : () {
                          setState(() {
                            _isClaimCardDismissed = true;
                          });
                        },
                  child: const Text('Later'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsNeedSection(BuildContext context) {
    final allItems = _buildStudentsNeedItems(_allDocs);
    print('StudentsNeed count: ${allItems.length}');

    if (allItems.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final onSurface = colors.onSurface;

    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;
          final visibleItems = isDesktop ? allItems : allItems.take(2).toList();

          if (visibleItems.isEmpty) return const SizedBox();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Students Need',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: onSurface,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => context.tracedGo('/requests'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            'View All →',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              isDesktop
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < visibleItems.length; i++) ...[
                            SizedBox(
                              width: 300,
                              child: HomeRequestCard(
                                data: visibleItems[i].data,
                                onTap: () => _openHomeItem(
                                  context,
                                  visibleItems[i].id,
                                  visibleItems[i].data,
                                ),
                              ),
                            ),
                            if (i != visibleItems.length - 1)
                              const SizedBox(width: 16),
                          ],
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          for (var i = 0; i < visibleItems.length; i++) ...[
                            HomeRequestCard(
                              data: visibleItems[i].data,
                              onTap: () => _openHomeItem(
                                context,
                                visibleItems[i].id,
                                visibleItems[i].data,
                              ),
                            ),
                            if (i != visibleItems.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  int getFeedCrossAxisCount(double width) {
    if (width < 600) return 2; // mobile (UNCHANGED behavior)
    if (width < 900) return 3; // tablet
    if (width < 1200) return 4; // small desktop
    return 5; // large desktop
  }

  Widget _buildTopHeader({
    required bool isDesktop,
    required ColorScheme colors,
    required Color onSurface,
    required Color onSurfaceHint,
    required String logoAsset,
  }) {
    return Padding(
      padding: isDesktop
          ? const EdgeInsets.fromLTRB(16, 8, 16, 12)
          : const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 34,
                      child: Image.asset(
                        logoAsset,
                        height: 34,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Compact Campus Pill
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          getCampusName(_campusId) == 'NIT Kurukshetra' ||
                                  getCampusName(_campusId) ==
                                      'National Institute of Technology Kurukshetra'
                              ? 'NIT KKR'
                              : getCampusName(_campusId),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),

                    // Removed redundant Spacer() that was causing premature truncation
                    IconButton(
                      onPressed: () => context.tracedPush('/notifications'),
                      icon: Icon(
                        Icons.notifications_outlined,
                        size: 26,
                        color: onSurface,
                      ),
                      tooltip: 'Notifications',
                      splashRadius: 22,
                    ),
                  ],
                ),
              if (!isDesktop) const SizedBox(height: 8),

              // Slim Search Bar
              SizedBox(
                height: 48,
                child: TextField(
                  controller: _searchController,
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(color: colors.onSurface),
                  decoration: buildInputDecoration(
                    'Search listings and rentals',
                    fillColor: colors.surface,
                    focusColor: colors.primary,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(Icons.search, size: 20, color: onSurfaceHint),
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 20,
                              color: onSurfaceHint,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchQuery = '';
                                _recomputeFeedSections();
                              });
                            },
                          )
                        : null,
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    hintStyle: TextStyle(fontSize: 14, color: onSurfaceHint),
                  ),
                  onChanged: (value) {
                    final searchDebounce = _searchDebounce;
                    if (searchDebounce != null && searchDebounce.isActive) {
                      searchDebounce.cancel();
                    }

                    _searchDebounce = Timer(
                      const Duration(milliseconds: 500),
                      () {
                        setState(() {
                          searchQuery = value.trim().toLowerCase();
                          _recomputeFeedSections();
                        });
                      },
                    );
                  },
                ),
              ),
              if (searchQuery.isEmpty) ...[
                SizedBox(height: isDesktop ? 8 : 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilterPill(
                            text: 'All',
                            isSelected: selectedFilter == 'all',
                            onTap: () {
                              setState(() {
                                selectedFilter = 'all';
                                _recomputeFeedSections();
                              });
                            },
                          ),
                          FilterPill(
                            text: 'Sale',
                            isSelected: selectedFilter == 'sell',
                            onTap: () {
                              setState(() {
                                selectedFilter = 'sell';
                                _recomputeFeedSections();
                              });
                            },
                          ),
                          FilterPill(
                            text: 'Rent',
                            isSelected: selectedFilter == 'rent',
                            onTap: () {
                              setState(() {
                                selectedFilter = 'rent';
                                _recomputeFeedSections();
                              });
                            },
                          ),
                          FilterPill(
                            text: 'Passout',
                            isSelected: selectedFilter == 'passout',
                            onTap: () {
                              setState(() {
                                selectedFilter = 'passout';
                                _recomputeFeedSections();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filter button
                    GestureDetector(
                      onTap: () async {
                        final result = await showFilterPanel(
                          context: context,
                          currentState: _filterState,
                          availableLocations: campusHostels[_campusId] ?? [],
                        );
                        if (result != null && mounted) {
                          setState(() {
                            _filterState = result;
                            _recomputeFeedSections();
                          });
                        }
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _filterState.isActive
                                  ? colors.primary.withValues(alpha: 0.12)
                                  : onSurface.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _filterState.isActive
                                    ? colors.primary.withValues(alpha: 0.35)
                                    : onSurface.withValues(alpha: 0.10),
                              ),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: _filterState.isActive
                                  ? colors.primary
                                  : onSurfaceHint,
                            ),
                          ),
                          if (_filterState.isActive)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).scaffoldBackgroundColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceMuted = onSurface.withValues(alpha: 0.72);

    if (_campusId == null) {
      return ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Center(
            child: _profileLoadError == null
                ? CircularProgressIndicator(color: colors.primary)
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _profileLoadError!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: onSurfaceMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: AppContentWrapper(
          child: Builder(
            builder: (context) {
              final width = MediaQuery.of(context).size.width;
              final isDesktop = width >= 768;
              final isMobile = !isDesktop;
              final isDark = theme.brightness == Brightness.dark;
              final onSurfaceHint = onSurface.withValues(alpha: 0.58);
              final logoAsset = isDark
                  ? 'assets/branding/nexlist_logo_dark.png'
                  : 'assets/branding/nexlist_logo.png';
              final showBrowseSections =
                  searchQuery.isEmpty && selectedFilter == 'all';
              final showStudentsNeedSection =
                  searchQuery.isEmpty && selectedFilter == 'all';

              final headerHeight = isDesktop
                  ? (searchQuery.isEmpty ? 116.0 : 76.0)
                  : (searchQuery.isEmpty ? 168.0 : 124.0);

              return RefreshIndicator(
                onRefresh: () async {
                  _setupFeedStream();
                },
                color: colors.primary,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Header / App Bar content
                    if (isMobile)
                      SliverAppBar(
                        floating: true,
                        snap: true,
                        pinned: false,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        automaticallyImplyLeading: false,
                        toolbarHeight: headerHeight,
                        flexibleSpace: FlexibleSpaceBar(
                          background: _GlassHeaderDelegate(
                            height: headerHeight,
                            child: _buildTopHeader(
                              isDesktop: false,
                              colors: colors,
                              onSurface: onSurface,
                              onSurfaceHint: onSurfaceHint,
                              logoAsset: logoAsset,
                            ),
                          ).build(context, 0, false),
                        ),
                      )
                    else
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _GlassHeaderDelegate(
                          height: headerHeight,
                          child: _buildTopHeader(
                            isDesktop: isDesktop,
                            colors: colors,
                            onSurface: onSurface,
                            onSurfaceHint: onSurfaceHint,
                            logoAsset: logoAsset,
                          ),
                        ),
                      ),

                    if (_shouldShowClaimCard)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: _buildClaimCard(),
                        ),
                      ),

                    if (showBrowseSections && _activityItems.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Campus Activity',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Builder(
                                builder: (context) {
                                  print(
                                    'CampusActivity count: ${_activityItems.length}',
                                  );
                                  final visibleItems = isDesktop
                                      ? _activityItems
                                      : _activityItems.take(5).toList();

                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        for (
                                          var index = 0;
                                          index < visibleItems.length;
                                          index++
                                        ) ...[
                                          ActivityPill(
                                            text: _buildCampusActivityText(
                                              visibleItems[index],
                                            ),
                                            dotColor:
                                                visibleItems[index].tagColor,
                                            onTap: () => _openHomeItem(
                                              context,
                                              visibleItems[index].id,
                                              visibleItems[index].data,
                                              enableHero: false,
                                            ),
                                          ),
                                          if (index != visibleItems.length - 1)
                                            const SizedBox(width: 10),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (showStudentsNeedSection)
                      _buildStudentsNeedSection(context),

                    if (searchQuery.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 0),
                          child: CategoryIconRow(
                            selectedCategory: selectedCategoryId,
                            onCategoryTap: (category) {
                              setState(() {
                                selectedCategoryId =
                                    selectedCategoryId == category
                                    ? null
                                    : category;
                                searchQuery = '';
                                _recomputeFeedSections();
                              });
                            },
                          ),
                        ),
                      ),

                    // Main Feed Title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            searchQuery.isEmpty
                                ? 'Campus Feed'
                                : 'Search results',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: onSurface,
                            ),
                          ),
                        ),
                      ),
                    ), // This closes SliverToBoxAdapter
                    // Render Grid of Listings from Stream
                    if (_isFeedLoading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: ListingGridSkeleton(),
                        ),
                      )
                    else if (_feedError != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: const ErrorStateView(),
                        ),
                      )
                    else if (_finalDocs.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: EmptyStateView(
                            icon: Icons.inventory_2_outlined,
                            title: searchQuery.isEmpty
                                ? 'No listings yet'
                                : 'No listings found',
                            subtitle: searchQuery.isEmpty
                                ? 'Be the first to post something!'
                                : 'Try a different search or pull to refresh.',
                            action: searchQuery.isEmpty
                                ? ElevatedButton.icon(
                                    onPressed: () =>
                                        context.tracedPush('/post?type=sell'),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Post a Listing'),
                                  )
                                : null,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: getFeedCrossAxisCount(width),
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.7,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final doc = _finalDocs[index];
                            final data =
                                doc.data() as Map<String, dynamic>? ?? {};
                            final isSaved = _savedDocIds.contains(doc.id);
                            final title =
                                data['title'] as String? ?? 'Untitled';

                            return ListingCard(
                              title: title,
                              priceText: ListingPriceUtils.resolveDisplayPrice(
                                data,
                              ).text,
                              imageUrls: ListingDataUtils.resolveImages(data),
                              location:
                                  ListingLocationUtils.resolveShortCleanLocation(
                                    data,
                                  ),
                              timeAgo: TimeUtils.formatTimeAgo(
                                ListingDataUtils.resolveCreatedAt(data),
                              ),
                              tagText: ListingPriceUtils.resolveBadgeText(data),
                              tagColor: ListingPriceUtils.resolveBadgeColor(
                                data,
                              ),
                              isFavorite: isSaved,
                              isNegotiable: data['allow_negotiation'] == true,
                              isPassoutSale: data['is_passout_sale'] == true,
                              heroTag: doc.id,
                              onTap: () => _openHomeItem(context, doc.id, data),
                              onFavoriteTap: () =>
                                  _toggleFavorite(doc.id, isSaved),
                            );
                          }, childCount: _finalDocs.length),
                        ),
                      ),

                    // Add padding at the bottom so FAB doesn't cover last items
                    const SliverToBoxAdapter(child: SizedBox(height: 88)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
