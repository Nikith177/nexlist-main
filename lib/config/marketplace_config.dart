class MarketplaceConfig {
  static const List<String> rentalTypes = ['hour', 'day', 'week', 'month'];

  static const List<String> listingTypes = ['sell', 'rent'];

  static String getRentShareMessage(
    String titleText,
    String priceText,
    String pickupText,
    String listingLink,
  ) {
    return '''Posting this on Nexlist – marketplace for NIT Kurukshetra students.

🔁 Available for rent

📦 $titleText
💰 Rent: $priceText
📍 Pickup: $pickupText

🔗 View item:
$listingLink''';
  }

  static String getSaleShareMessage(
    String titleText,
    String priceText,
    String pickupText,
    String listingLink,
  ) {
    return '''Posting this on Nexlist – marketplace for NIT Kurukshetra students.

🛒 Available for sale

📦 $titleText
💰 Price: $priceText
📍 Pickup: $pickupText

🔗 View item:
$listingLink''';
  }
}
