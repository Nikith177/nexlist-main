import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import 'listing_data_utils.dart';

class ResolvedPriceDisplay {
  final String text;

  const ResolvedPriceDisplay(this.text);

  bool get hasPrice => text.isNotEmpty;
}

class ListingPriceUtils {
  static const String freePriceText = 'FREE';

  static bool isFreeItem(Map<String, dynamic> data) {
    final price = _parsePrice(data['price']);
    final priceLabel1 = data['priceLabel']?.toString().trim().toUpperCase();
    final priceLabel2 = data['price_label']?.toString().trim().toUpperCase();

    return price == 0 || priceLabel1 == 'FREE' || priceLabel2 == 'FREE';
  }

  static ResolvedPriceDisplay resolveDisplayPrice(Map<String, dynamic> data) {
    if (isFreeItem(data)) {
      return const ResolvedPriceDisplay(freePriceText);
    }

    final listingType = ListingDataUtils.resolveType(data);
    final price = _parsePrice(data['price']);

    if (price == null || price <= 0) {
      return const ResolvedPriceDisplay('');
    }

    final formattedPrice = '₹${_formatAmount(price)}';

    switch (listingType) {
      case 'rent':
        final unit = _clean(data['rental_price_unit']) ?? 'day';
        return ResolvedPriceDisplay('$formattedPrice / $unit');
      case 'service':
        return ResolvedPriceDisplay('From $formattedPrice');
      case 'request':
        return ResolvedPriceDisplay('Budget $formattedPrice');
      case 'sell':
      default:
        return ResolvedPriceDisplay(formattedPrice);
    }
  }

  static String resolveBadgeText(Map<String, dynamic> data) {
    if (isFreeItem(data)) {
      return 'FREE';
    }

    final listingType = ListingDataUtils.resolveType(data);

    switch (listingType) {
      case 'rent':
        return 'RENT';
      case 'sell':
        return 'SELL';
      default:
        return listingType.toUpperCase();
    }
  }

  static Color resolveBadgeColor(Map<String, dynamic> data) {
    final badgeText = resolveBadgeText(data);

    if (badgeText == 'FREE') {
      return AppColors.textHint;
    }

    if (badgeText == 'RENT') {
      return AppColors.rentPill;
    }

    if (badgeText == 'REQUEST') {
      return AppColors.requestPill;
    }

    if (badgeText == 'SERVICE') {
      return AppColors.servicePill;
    }

    return AppColors.sellPill;
  }

  static num? _parsePrice(dynamic rawPrice) {
    if (rawPrice is num) {
      if (rawPrice.isNaN || rawPrice.isInfinite) {
        return null;
      }
      return rawPrice;
    }

    if (rawPrice is String) {
      return num.tryParse(rawPrice.trim());
    }

    return null;
  }

  static String _formatAmount(num amount) {
    if (amount % 1 == 0) {
      return amount.toInt().toString();
    }

    var text = amount.toStringAsFixed(2);
    text = text.replaceFirst(RegExp(r'\.?0+$'), '');
    return text;
  }

  static String? _clean(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}
