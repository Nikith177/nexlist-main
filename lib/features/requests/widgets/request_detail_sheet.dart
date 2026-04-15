import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/colors.dart';
import '../../../shared/utils/contact_utils.dart';
import '../../../shared/utils/listing_data_utils.dart';
import '../../../shared/utils/listing_location_utils.dart';
import '../../../shared/utils/listing_price_utils.dart';
import '../../../shared/utils/phone_gate_utils.dart';
import '../../../shared/utils/title_format_utils.dart';

class RequestDetailSheet extends StatelessWidget {
  final Map<String, dynamic> data;

  const RequestDetailSheet({super.key, required this.data});

  void _handleShare(BuildContext context, Map<String, dynamic> data) {
    final listingId = data['id']?.toString().trim();
    final link = listingId == null || listingId.isEmpty
        ? null
        : 'https://www.nexlist.in/preview/listing/$listingId';

    final message = ContactUtils.getShareMessage(data, link);
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    // SAFE DATA PARSING
    final rawTitle = data['title'] as String? ?? 'Untitled';
    final title = formatTitle(rawTitle);
    final description = data['description'] as String? ?? '';
    final priceDisplay = ListingPriceUtils.resolveDisplayPrice(data);
    final userName =
        PhoneGateUtils.normalizeName(data['contactName']) ??
        PhoneGateUtils.normalizeName(data['user_name']) ??
        PhoneGateUtils.normalizeName(data['name']) ??
        'User';

    final location = ListingLocationUtils.resolveDisplayLocation(data);
    final hasLocation = location.isNotEmpty;

    // SAFE TIME PARSING
    String timeAgo = '';
    final createdAt = ListingDataUtils.resolveCreatedAt(data);
    if (createdAt != null) {
      final DateTime dt = createdAt;
      final Duration diff = DateTime.now().difference(dt);

      if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours}h ago';
      } else {
        timeAgo = '${diff.inDays}d ago';
      }
    }
    final isUrgent = data['is_urgent'] as bool? ?? false;

    // 4. BUILD CLEAN SHEET UI
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.45,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // HANDLE
              const SizedBox(height: 8),

              // HANDLE BAR
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 10),

              // CONTENT
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TOP ROW (BADGE + TIME)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isUrgent
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isUrgent ? 'URGENT' : 'REQUEST',
                              style: TextStyle(
                                fontSize: 11,
                                color: isUrgent
                                    ? Colors.red
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (timeAgo.isNotEmpty)
                            Text(
                              timeAgo,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // TITLE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: () => _handleShare(context, data),
                            tooltip: 'Share',
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // DESCRIPTION
                      if (description.isNotEmpty)
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),

                      const SizedBox(height: 16),

                      const Divider(),

                      const SizedBox(height: 12),

                      // LOCATION + PRICE
                      if (hasLocation || priceDisplay.hasPrice) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (hasLocation)
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        location,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              const Spacer(),
                            if (priceDisplay.hasPrice)
                              Text(
                                priceDisplay.text,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // USER BLOCK (MINIMAL TRUST)
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            child: Icon(Icons.person, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Posted by $userName',
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 80), // Space for sticky button
                    ],
                  ),
                ),
              ),

              // STICKY CONTACT BUTTON
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ContactUtils.contactSellerOnWhatsApp(
                          context: context,
                          data: data,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Contact on WhatsApp',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
