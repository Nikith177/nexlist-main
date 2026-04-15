import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'listing_data_utils.dart';
import 'firestore_trace_utils.dart';
import 'listing_location_utils.dart';
import 'listing_price_utils.dart';
import 'phone_gate_utils.dart';
import 'seller_identity_utils.dart';

class ContactUtils {
  static Future<void> contactSellerOnWhatsApp({
    required BuildContext context,
    required Map<String, dynamic> data,
  }) async {
    final isReady = await PhoneGateUtils.ensureUserReadyForAction(context);
    if (!context.mounted) {
      return;
    }
    if (!isReady) {
      return;
    }

    final rawOverridePhone = data['contactPhone'];
    final overridePhone = rawOverridePhone == null
        ? null
        : PhoneGateUtils.normalizePhone(rawOverridePhone);
    if (overridePhone != null) {
      await openWhatsApp(
        phone: overridePhone,
        message: getWhatsappMessage(data),
        context: context,
      );
      return;
    }

    final sellerId = SellerIdentityUtils.resolveSellerId(data);
    if (sellerId == null) {
      _showSnackBar(context, 'Contact information is not available');
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .tracedGet('users/$sellerId contact lookup');

      if (!context.mounted) {
        return;
      }

      final phone = PhoneGateUtils.normalizePhone(userDoc.data()?['phone']);

      if (phone == null) {
        _showSnackBar(context, 'No valid contact number is available yet');
        return;
      }

      await openWhatsApp(
        phone: phone,
        message: getWhatsappMessage(data),
        context: context,
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      _showSnackBar(context, 'Could not load seller contact');
    }
  }

  static String getWhatsappMessage(Map<String, dynamic> data) {
    final title = (data['title']?.toString() ?? 'item').trim();
    final price = (data['price'] == null || data['price'] == 0)
        ? 'Free'
        : '₹${data['price']}'.trim();
    final location = (data['location_tag']?.toString() ?? 'campus').trim();
    final type = (data['type'] ?? '').toString().toLowerCase();

    if (type == 'sell') {
      return "Hi, I'm interested in \"$title\".\n\n$price\n$location\n\nIs this still available?";
    }

    if (type == 'rent') {
      return "Hi, I want to rent \"$title\".\n\n$price\n$location\n\nIs this available?";
    }

    if (type == 'service') {
      return "Hi, I'm interested in your \"$title\" service.\n\n$price\n$location\n\nCan you share more details?";
    }

    if (type == 'request') {
      return "Hi, I saw your request for \"$title\".\n\n$location\n\nI can help with this. Is it still needed?";
    }

    return "Hi, I'm interested in \"$title\".\n\n$price\n$location\n\nIs this still available?";
  }

  static String getShareMessage(Map<String, dynamic> data, String? link) {
    final listingType = ListingDataUtils.resolveType(data);
    final title = (data['title'] as String? ?? 'Untitled').trim();
    final priceText = ListingPriceUtils.resolveDisplayPrice(data).text.trim();
    final locationText = ListingLocationUtils.resolveDisplayLocation(
      data,
    ).trim();
    final cleanTitle = title.isEmpty ? 'Untitled' : title;
    final safeLink = link ?? '';

    if (listingType == 'request') {
      final lines = <String>[
        '📢 Need this on campus',
        '',
        cleanTitle,
        if (locationText.isNotEmpty) '📍 $locationText',
        '',
        'Can anyone help?',
        if (safeLink.isNotEmpty) '',
        if (safeLink.isNotEmpty) safeLink,
      ];
      return lines.join('\n');
    }

    if (listingType == 'service') {
      final lines = <String>[
        '🛠️ Service available',
        '',
        cleanTitle,
        if (priceText.isNotEmpty) priceText,
        if (locationText.isNotEmpty) '📍 $locationText',
        '',
        'Check details 👇',
        if (safeLink.isNotEmpty) safeLink,
      ];
      return lines.join('\n');
    }

    if (listingType == 'rent') {
      final lines = <String>[
        '📦 Available for rent',
        '',
        cleanTitle,
        if (priceText.isNotEmpty) '💰 $priceText',
        if (locationText.isNotEmpty) '📍 $locationText',
        '',
        'Check availability 👇',
        if (safeLink.isNotEmpty) safeLink,
      ];
      return lines.join('\n');
    }

    if (priceText == 'FREE') {
      final lines = <String>[
        '🎁 FREE on Nexlist!',
        '',
        cleanTitle,
        if (locationText.isNotEmpty) '📍 $locationText',
        '',
        'First come, first serve 👀',
        if (safeLink.isNotEmpty) '',
        if (safeLink.isNotEmpty) safeLink,
      ];
      return lines.join('\n');
    }

    final lines = <String>[
      '🛒 For sale on Nexlist',
      '',
      cleanTitle,
      if (priceText.isNotEmpty) '💰 $priceText',
      if (locationText.isNotEmpty) '📍 $locationText',
      '',
      'Interested? Check it here 👇',
      if (safeLink.isNotEmpty) safeLink,
    ];

    return lines.join('\n');
  }

  static Future<void> openWhatsApp({
    required String? phone,
    required String message,
    BuildContext? context,
  }) async {
    if (phone == null || phone.trim().isEmpty) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number not available')),
        );
      }
      return;
    }

    if (message.trim().isEmpty) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Message not available')));
      }
      return;
    }

    final normalizedPhone = PhoneGateUtils.normalizePhoneForWhatsApp(phone);
    if (normalizedPhone == null) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number not available')),
        );
      }
      return;
    }
    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse(
      'https://wa.me/$normalizedPhone?text=$encodedMessage',
    );

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static String? _clean(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}
