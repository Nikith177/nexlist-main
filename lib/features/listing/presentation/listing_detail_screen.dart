import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexlist_mobile/core/state/app_state.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/favorite_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/utils/contact_utils.dart';
import '../../../shared/utils/firestore_trace_utils.dart';
import '../../../shared/utils/listing_category_utils.dart';
import '../../../shared/utils/listing_condition_utils.dart';
import '../../../shared/utils/listing_data_utils.dart';
import '../../../shared/utils/listing_delete_utils.dart';
import '../../../shared/utils/listing_location_utils.dart';
import '../../../shared/utils/listing_price_utils.dart';
import '../../../shared/utils/navigation_trace_utils.dart';
import '../../../shared/utils/phone_gate_utils.dart';
import '../../../shared/utils/seller_identity_utils.dart';
import '../../../shared/utils/time_utils.dart';
import '../../../shared/utils/title_format_utils.dart';
import '../../../shared/widgets/semantic_pill.dart';

class ListingDetailScreen extends StatefulWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  bool _isUpdatingStatus = false;
  bool _isDeleting = false;

  Future<bool> _handleBackNavigation(BuildContext context) async {
    if (!listingLaunchedFromDeepLink) {
      return true;
    }

    listingLaunchedFromDeepLink = false;
    if (context.mounted) {
      context.tracedGo('/home');
    }
    return false;
  }

  Future<void> _handleBackTap(BuildContext context) async {
    final shouldPop = await _handleBackNavigation(context);
    if (shouldPop && context.mounted) {
      context.pop();
    }
  }

  String _resolveSellerId(Map<String, dynamic> data) {
    return SellerIdentityUtils.resolveSellerId(data) ?? '';
  }

  bool _canShareListing(String type) {
    return type == 'sell' ||
        type == 'rent' ||
        type == 'request' ||
        type == 'service';
  }

  Future<void> _shareListing(Map<String, dynamic> data) async {
    final listingType = ListingDataUtils.resolveType(data);
    final title = (data['title'] as String? ?? 'Untitled').trim();
    final priceText = ListingPriceUtils.resolveDisplayPrice(data).text.trim();
    final locationText = ListingLocationUtils.resolveDisplayLocation(
      data,
    ).trim();
    final cleanTitle = title.isEmpty ? 'Untitled' : title;
    final rawListingId = (data['id'] as String?)?.trim();
    final listingId = rawListingId != null && rawListingId.isNotEmpty
        ? rawListingId
        : widget.listingId.trim();
    final link = listingId.isEmpty
        ? null
        : 'https://www.nexlist.in/preview/listing/$listingId';

    final message = ContactUtils.getShareMessage(data, link);
    await Share.share(message);
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save listings')),
      );
      return;
    }

    try {
      await FavoriteService.toggle(user.uid, widget.listingId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update saved items: $e')),
      );
    }
  }

  Future<void> _deleteListing(BuildContext context) async {
    if (_isDeleting) return;

    setState(() => _isDeleting = true);
    try {
      await ListingDeleteUtils.deleteListing(widget.listingId);
      if (!context.mounted) return;
      GoRouter.of(context).pop(widget.listingId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    if (_isUpdatingStatus || _isDeleting) return;

    setState(() => _isUpdatingStatus = true);
    try {
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.listingId)
          .update({'status': status});
      if (!context.mounted) return;
      Navigator.pop(context, 'updated');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update listing: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _favoriteStream(
    String userId,
  ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('saved_items')
        .doc(widget.listingId)
        .tracedSnapshots(
          'users/$userId/saved_items/${widget.listingId} listing detail',
        );
  }

  Widget _buildFavoriteBadge({
    required BuildContext context,
    required String userId,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonDecoration = BoxDecoration(
      shape: BoxShape.circle,
      color: isDark
          ? colors.surface.withValues(alpha: 0.94)
          : colors.surface.withValues(alpha: 0.98),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : colors.outline.withValues(alpha: 0.14),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.12),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
    final unsavedFavoriteColor = isDark ? Colors.white : colors.onSurface;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _favoriteStream(userId),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data?.exists ?? false;

        return Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            onTap: () => _toggleFavorite(context),
            customBorder: const CircleBorder(),
            child: Ink(
              width: 36,
              height: 36,
              decoration: buttonDecoration,
              child: Center(
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppColors.error : unsavedFavoriteColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return WillPopScope(
      onWillPop: () => _handleBackNavigation(context),
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('listings')
            .doc(widget.listingId)
            .tracedGet('listings/${widget.listingId} listing detail'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                iconTheme: IconThemeData(color: colors.onSurface),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.onSurface),
                  onPressed: () => _handleBackTap(context),
                ),
                title: Text(
                  'Listing Details',
                  style: AppTypography.h3.copyWith(color: colors.onSurface),
                ),
                centerTitle: true,
              ),
              body: Center(
                child: CircularProgressIndicator(color: colors.primary),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: Center(
                child: Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: colors.onSurface),
                ),
              ),
            );
          }

          final listingDoc = snapshot.data;

          if (listingDoc == null || !listingDoc.exists) {
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: Center(
                child: Text(
                  'Listing not found',
                  style: AppTypography.h3.copyWith(color: colors.onSurface),
                ),
              ),
            );
          }

          final data = listingDoc.data() ?? const <String, dynamic>{};
          final resolvedType = ListingDataUtils.resolveType(data);
          final listingType = resolvedType.isEmpty ? 'sell' : resolvedType;
          final listingTypeLabel = listingType.toUpperCase();
          final isRequestOrService =
              listingType == 'request' || listingType == 'service';
          final hasOwnerStatusAction =
              listingType == 'sell' || listingType == 'rent';
          final listingBadgeLabel = ListingPriceUtils.resolveBadgeText(data);
          final listingBadgeColor = ListingPriceUtils.resolveBadgeColor(data);
          final createdAt = ListingDataUtils.resolveCreatedAt(data);
          final imageUrl = (() {
            final resolvedImages = ListingDataUtils.resolveImages(data);
            return resolvedImages.isEmpty ? null : resolvedImages.first;
          })();
          final hasImages = imageUrl != null && imageUrl != 'placeholder';
          final rawTitle = (data['title'] as String?)?.trim() ?? '';
          final title = formatTitle(rawTitle.isEmpty ? 'Untitled' : rawTitle);
          final description =
              data['description'] as String? ?? 'No description available.';
          final category = ListingCategoryUtils.resolveCategory(data);
          final hasCategory = category.isNotEmpty;
          final condition = ListingConditionUtils.getDisplayCondition(
            data['condition'],
          );
          final hasCondition =
              (listingType == 'sell' || listingType == 'rent') &&
              condition.isNotEmpty;
          final status = data['status'] as String? ?? 'available';
          final sellerId = _resolveSellerId(data);
          final isOwner = user != null && user.uid == sellerId;
          final isNegotiable = data['allow_negotiation'] == true;
          final displayLocation =
              ListingLocationUtils.resolveShortCleanLocation(data);
          final hasDisplayLocation = displayLocation.isNotEmpty;
          final priceDisplay = ListingPriceUtils.resolveDisplayPrice(data);
          final timeAgo = TimeUtils.formatTimeAgo(createdAt);
          final hasTimeAgo = timeAgo.trim().isNotEmpty;

          Widget _buildMainImage(bool isDesktop) {
            if (!hasImages) return const SizedBox.shrink();
            final extra = GoRouterState.of(context).extra as Map?;
            final enableHero = extra?['enableHero'] ?? true;
            final imageContent = ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: colors.surfaceContainerHighest),
                  CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    fadeInDuration: const Duration(milliseconds: 200),
                    fadeOutDuration: const Duration(milliseconds: 100),
                    placeholder: (context, url) =>
                        Container(color: colors.surfaceContainerHighest),
                    errorWidget: (context, url, error) => Container(
                      color: colors.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 64,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
            return SizedBox(
              height: isDesktop
                  ? 400
                  : MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  enableHero
                      ? Hero(tag: widget.listingId, child: imageContent)
                      : imageContent,
                  Positioned(
                    top: 16,
                    left: 16,
                    child: AppPill(
                      label: listingBadgeLabel,
                      baseColor: listingBadgeColor,
                      variant: AppPillVariant.solid,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (user != null)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _buildFavoriteBadge(
                        context: context,
                        userId: user.uid,
                      ),
                    ),
                ],
              ),
            );
          }

          Widget _buildHeaderSection() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    if (priceDisplay.hasPrice) ...[
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            priceDisplay.text,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                          if (isNegotiable) ...[
                            const SizedBox(height: 4),
                            AppPill(
                              label: 'Negotiable',
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              textStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
                if (hasDisplayLocation || hasTimeAgo) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (hasDisplayLocation) ...[
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            displayLocation,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (hasDisplayLocation && hasTimeAgo) ...[
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (hasTimeAgo) ...[
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            );
          }

          Widget _buildMetaSection() {
            if (!hasCondition && !hasCategory) return const SizedBox.shrink();
            return Row(
              children: [
                if (hasCondition) ...[
                  Expanded(child: _buildAttributeBox('CONDITION', condition)),
                  const SizedBox(width: 8),
                ],
                if (hasCategory) ...[
                  Expanded(child: _buildAttributeBox('CATEGORY', category)),
                  const SizedBox(width: 8),
                ],
                Expanded(child: _buildAttributeBox('TYPE', listingTypeLabel)),
              ],
            );
          }

          Widget _buildDescriptionSection() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (!isRequestOrService) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Seller Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                 const SizedBox(height: 12),
                 if (sellerId.isEmpty)
                   const Text('Seller info unavailable')
                 else
                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(sellerId)
                        .tracedGet('users/$sellerId listing detail seller'),
                    builder: (context, sellerSnapshot) {
                      if (sellerSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (sellerSnapshot.hasError) {
                        return const Text('Seller info unavailable');
                      }

                      final sellerData =
                          sellerSnapshot.data?.data() ??
                          const <String, dynamic>{};
                      String sellerName =
                          PhoneGateUtils.normalizeName(data['contactName']) ??
                          PhoneGateUtils.normalizeName(sellerData['name']) ??
                          PhoneGateUtils.normalizeName(data['user_name']) ??
                          PhoneGateUtils.normalizeName(data['name']) ??
                          'User';

                      if (user != null && sellerId == user.uid) {
                        sellerName = '$sellerName (You)';
                      }

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: colors.primary.withValues(
                                alpha: 0.1,
                              ),
                              child: Icon(Icons.person, color: colors.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Posted by',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sellerName,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: colors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Nexlist Campus Safety Tips',
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildSafetyBullet(
                          'Meet in a public campus area during daylight.',
                        ),
                        _buildSafetyBullet(
                          'Always inspect the item before paying.',
                        ),
                        _buildSafetyBullet(
                          'Use campus UPI or cash for secure payments.',
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          }

          Widget _buildActionCTA() {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.outline.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (!isOwner) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await ContactUtils.contactSellerOnWhatsApp(
                              context: context,
                              data: {...data, 'id': widget.listingId},
                            );
                          },
                          icon: Icon(
                            Icons.chat_bubble_outline,
                            color: colors.onPrimary,
                          ),
                          label: Text(
                            'Contact on WhatsApp',
                            style: TextStyle(
                              color: colors.onPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (isOwner) ...[
                      if (listingType == 'sell') ...[
                        if (status == 'available')
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdatingStatus || _isDeleting
                                  ? null
                                  : () => _updateStatus(context, 'sold'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Mark as Sold',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        if (status == 'sold')
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdatingStatus || _isDeleting
                                  ? null
                                  : () => _updateStatus(context, 'available'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Mark as Available',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                      if (listingType == 'rent') ...[
                        if (status == 'available')
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdatingStatus || _isDeleting
                                  ? null
                                  : () => _updateStatus(context, 'rented'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Mark as Rented',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        if (status == 'rented')
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdatingStatus || _isDeleting
                                  ? null
                                  : () => _updateStatus(context, 'available'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Mark as Available',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                      if (listingType == 'request') ...[
                        if (status == 'available')
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdatingStatus || _isDeleting
                                  ? null
                                  : () => _updateStatus(context, 'resolved'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Mark as Resolved',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        if (status == 'resolved')
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdatingStatus || _isDeleting
                                  ? null
                                  : () => _updateStatus(context, 'available'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Mark as Unresolved',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.error),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _isUpdatingStatus || _isDeleting
                              ? null
                              : () => _deleteListing(context),
                          icon: _isDeleting
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.error,
                                  ),
                                )
                              : Icon(Icons.delete_outline, color: colors.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          Widget _buildMobileLayout() {
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                iconTheme: IconThemeData(color: colors.onSurface),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.onSurface),
                  onPressed: () => _handleBackTap(context),
                ),
                title: Text(
                  'Listing Details',
                  style: AppTypography.h3.copyWith(color: colors.onSurface),
                ),
                centerTitle: true,
                actions: [
                  if (_canShareListing(listingType))
                    IconButton(
                      icon: Icon(Icons.share, color: colors.onSurface),
                      onPressed: () => _shareListing(data),
                    ),
                ],
              ),
              body: listingType == 'service'
                  ? _buildServiceLayout(
                      context: context,
                      data: data,
                      sellerId: sellerId,
                      imageUrl: imageUrl,
                      category: category,
                      title: title,
                      description: description,
                      displayLocation: displayLocation,
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMainImage(false),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeaderSection(),
                                const SizedBox(height: 24),
                                _buildMetaSection(),
                                const SizedBox(height: 24),
                                _buildDescriptionSection(),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              bottomNavigationBar: listingType == 'service'
                  ? _buildServiceBottomBar(
                      context: context,
                      isOwner: isOwner,
                      status: status,
                      data: data,
                    )
                  : _buildActionCTA(),
            );
          }

          Widget _buildDesktopLayout(BuildContext context) {
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                iconTheme: IconThemeData(color: colors.onSurface),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.onSurface),
                  onPressed: () => _handleBackTap(context),
                ),
                title: Text(
                  'Listing Details',
                  style: AppTypography.h3.copyWith(color: colors.onSurface),
                ),
                centerTitle: true,
                actions: [
                  if (_canShareListing(listingType))
                    IconButton(
                      icon: Icon(Icons.share, color: colors.onSurface),
                      onPressed: () => _shareListing(data),
                    ),
                ],
              ),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: listingType == 'service'
                      ? _buildServiceLayout(
                          context: context,
                          data: data,
                          sellerId: sellerId,
                          imageUrl: imageUrl,
                          category: category,
                          title: title,
                          description: description,
                          displayLocation: displayLocation,
                        )
                      : SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [_buildMainImage(true)],
                                  ),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildHeaderSection(),
                                      const SizedBox(height: 24),
                                      _buildMetaSection(),
                                      const SizedBox(height: 24),
                                      _buildDescriptionSection(),
                                      const SizedBox(height: 32),
                                      _buildActionCTA(),
                                      const SizedBox(height: 64),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            );
          }

          final isDesktop = MediaQuery.of(context).size.width > 900;
          if (isDesktop) {
            return _buildDesktopLayout(context);
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildServiceLayout({
    required BuildContext context,
    required Map<String, dynamic> data,
    required String sellerId,
    required String? imageUrl,
    required String category,
    required String title,
    required String description,
    required String displayLocation,
  }) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl != 'placeholder')
            SizedBox(
              height: 280,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: colors.surfaceContainerHighest),
                errorWidget: (context, url, err) => Container(
                  color: colors.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h1.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: 8),
                if (displayLocation.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        displayLocation,
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                Text(
                  'Description',
                  style: AppTypography.h3.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceBottomBar({
    required BuildContext context,
    required bool isOwner,
    required String status,
    required Map<String, dynamic> data,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!isOwner)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ContactUtils.contactSellerOnWhatsApp(
                      context: context,
                      data: {...data, 'id': widget.listingId},
                    );
                  },
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: colors.onPrimary,
                  ),
                  label: Text(
                    'Contact on WhatsApp',
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (isOwner) ...[
              if (status == 'available')
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isUpdatingStatus || _isDeleting
                        ? null
                        : () => _updateStatus(context, 'unavailable'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Mark as Unavailable',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              if (status == 'unavailable')
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isUpdatingStatus || _isDeleting
                        ? null
                        : () => _updateStatus(context, 'available'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Mark as Available',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colors.error),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _isUpdatingStatus || _isDeleting
                      ? null
                      : () => _deleteListing(context),
                  icon: _isDeleting
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.error,
                          ),
                        )
                      : Icon(Icons.delete_outline, color: colors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttributeBox(String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyBullet(String text) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 13,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
