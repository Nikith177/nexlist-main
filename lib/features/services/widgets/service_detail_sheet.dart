import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/utils/contact_utils.dart';
import '../../../shared/utils/listing_data_utils.dart';
import '../../../shared/utils/listing_location_utils.dart';
import '../../../shared/utils/listing_price_utils.dart';
import '../../../shared/utils/phone_gate_utils.dart';
import '../../../shared/utils/time_utils.dart';
import '../../../shared/utils/title_format_utils.dart';

class ServiceDetailSheet extends StatelessWidget {
  final Map<String, dynamic> data;

  const ServiceDetailSheet({super.key, required this.data});

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
    final rawTitle = data['title'] as String? ?? 'Untitled Service';
    final title = formatTitle(rawTitle);
    final description = data['description'] as String? ?? '';
    final priceDisplay = ListingPriceUtils.resolveDisplayPrice(data);
    final userName =
        PhoneGateUtils.normalizeName(data['contactName']) ??
        PhoneGateUtils.normalizeName(data['user_name']) ??
        PhoneGateUtils.normalizeName(data['name']) ??
        'User';

    final displayLocation = ListingLocationUtils.resolveDisplayLocation(data);

    final timeAgo = TimeUtils.formatTimeAgo(
      ListingDataUtils.resolveCreatedAt(data),
    );

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
              const SizedBox(height: 8),

              // HANDLE
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

                      // PRICE
                      if (priceDisplay.hasPrice) ...[
                        Text(
                          priceDisplay.text,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (data['pricing_type'] == 'starting_from') ...[
                          const SizedBox(height: 4),
                          Text(
                            "Price may vary based on requirements",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 12),

                      const Divider(),

                      const SizedBox(height: 12),

                      // DESCRIPTION
                      if (description.isNotEmpty)
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // LOCATION
                      if (displayLocation.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                displayLocation,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

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
                      const SizedBox(height: 12),
                      // TIME
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Posted $timeAgo',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 80), // Space for button
                    ],
                  ),
                ),
              ),

              // CTA BUTTON
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    height: 48,
                    width: double.infinity,
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
