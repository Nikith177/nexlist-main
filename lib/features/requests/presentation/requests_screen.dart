import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_input_decoration.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/search_utils.dart';
import '../../../shared/layouts/app_content_wrapper.dart';
import '../../../shared/utils/firestore_trace_utils.dart';
import '../../../shared/utils/listing_data_utils.dart';
import '../../../shared/utils/navigation_trace_utils.dart';
import '../../../shared/widgets/custom_bottom_nav_bar.dart';
import 'package:nexlist_mobile/shared/widgets/content_state_widgets.dart';
import '../widgets/request_detail_sheet.dart';
import '../widgets/request_card.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  String? _campusId;
  String searchQuery = '';
  Stream<QuerySnapshot>? _requestsStream;

  @override
  void initState() {
    super.initState();
    _loadCampusId();
  }

  Future<void> _loadCampusId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('campus_id');
    if (cached != null) {
      if (mounted) {
        setState(() {
          _campusId = cached;
          _requestsStream = FirebaseFirestore.instance
              .collection('listings')
              .where('campus_id', isEqualTo: _campusId)
              .where('status', isEqualTo: 'available')
              .limit(50)
              .tracedSnapshots(
                'listings requests feed outer campus=$_campusId',
              );
        });
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .tracedGet('users/${user.uid} requests campus lookup outer');
      if (doc.exists && mounted) {
        final fetched = doc.data()?['campus_id'] as String?;
        if (fetched != null) {
          await prefs.setString('campus_id', fetched);
          setState(() {
            _campusId = fetched;
            _requestsStream = FirebaseFirestore.instance
                .collection('listings')
                .where('campus_id', isEqualTo: _campusId)
                .where('status', isEqualTo: 'available')
                .limit(50)
                .tracedSnapshots(
                  'listings requests feed outer campus=$_campusId',
                );
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_campusId == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: MediaQuery.of(context).size.width >= 900
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                color: colors.onSurface,
                onPressed: () => context.tracedGo('/home'),
              )
            : null,
        title: Text(
          'Campus Requests',
          style: AppTypography.h2.copyWith(color: colors.onSurface),
        ),
        centerTitle: true,
      ),
      body: const AppContentWrapper(child: RequestsScreenContent()),
    );
  }
}

class RequestsScreenContent extends StatefulWidget {
  const RequestsScreenContent({super.key});

  @override
  State<RequestsScreenContent> createState() => _RequestsScreenContentState();
}

class _RequestsScreenContentState extends State<RequestsScreenContent> {
  String? _campusId;
  String searchQuery = '';
  Stream<QuerySnapshot>? _requestsStream;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCampusId();
  }

  Future<void> _loadCampusId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('campus_id');
    if (cached != null && cached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _campusId = cached;
          _requestsStream = FirebaseFirestore.instance
              .collection('listings')
              .where('campus_id', isEqualTo: _campusId)
              .where('status', isEqualTo: 'available')
              .limit(50)
              .tracedSnapshots(
                'listings requests feed inner campus=$_campusId',
              );
        });
      }
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .tracedGet('users/${user.uid} requests campus lookup inner');
      final fetched = doc.data()?['campus_id'] as String?;
      if (fetched != null && fetched.isNotEmpty) {
        await prefs.setString('campus_id', fetched);
        if (mounted) {
          setState(() {
            _campusId = fetched;
            _requestsStream = FirebaseFirestore.instance
                .collection('listings')
                .where('campus_id', isEqualTo: _campusId)
                .where('status', isEqualTo: 'available')
                .limit(50)
                .tracedSnapshots(
                  'listings requests feed inner campus=$_campusId',
                );
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_campusId == null) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(color: colors.onSurface),
              decoration: buildInputDecoration(
                'Search requests',
                fillColor: colors.surface,
                focusColor: colors.primary,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
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
                          color: colors.onSurface.withValues(alpha: 0.55),
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
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: _requestsStream == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: _requestsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const VerticalCardSkeletonList();
                      }
                      if (snapshot.hasError) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 140),
                            SizedBox(height: 240, child: ErrorStateView()),
                          ],
                        );
                      }

                      final rawDocs =
                          snapshot.data?.docs
                              .cast<DocumentSnapshot>()
                              .toList() ??
                          [];
                      final requestsDocs = rawDocs.where((doc) {
                        final data =
                            doc.data() as Map<String, dynamic>? ?? const {};
                        return ListingDataUtils.resolveType(data) == 'request';
                      }).toList();

                      final filteredDocs =
                          ListingDataUtils.sortDocsByUrgentThenCreatedAtDesc(
                            filterListings(requestsDocs, searchQuery),
                          );

                      if (filteredDocs.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            SizedBox(
                              height: 260,
                              child: EmptyStateView(
                                icon: Icons.help_outline,
                                title: searchQuery.isEmpty
                                    ? 'No requests yet'
                                    : 'No requests found',
                                subtitle: searchQuery.isEmpty
                                    ? 'Ask for something you need!'
                                    : 'Try a different search or pull to refresh.',
                                action: searchQuery.isEmpty
                                    ? ElevatedButton.icon(
                                        onPressed: () => context.tracedPush(
                                          '/post?type=request',
                                        ),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Post a Request'),
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        itemCount: filteredDocs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final data = {
                            ...filteredDocs[index].data()
                                as Map<String, dynamic>,
                            'id': filteredDocs[index].id,
                          };
                          return RequestCard(
                            data: data,
                            onTap: () {
                              const FABVisibilityNotification(
                                true,
                              ).dispatch(context);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useRootNavigator: false,
                                backgroundColor: Colors.transparent,
                                builder: (_) => RequestDetailSheet(data: data),
                              ).whenComplete(() {
                                if (context.mounted) {
                                  const FABVisibilityNotification(
                                    false,
                                  ).dispatch(context);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
