class FormatUtils {
  FormatUtils._();

  /// Formats price in Indian convention:
  /// 12000 → ₹12K   |   350000 → ₹3.5L   |   8500000 → ₹85L   |   10000000 → ₹1Cr
  static String formatPrice(double price) {
    if (price >= 10000000) {
      final cr = price / 10000000;
      return '₹${cr % 1 == 0 ? cr.toInt() : cr.toStringAsFixed(1)}Cr';
    } else if (price >= 100000) {
      final lakh = price / 100000;
      return '₹${lakh % 1 == 0 ? lakh.toInt() : lakh.toStringAsFixed(1)}L';
    } else if (price >= 1000) {
      final k = price / 1000;
      return '₹${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(0)}K';
    }
    return '₹${price.toInt()}';
  }

  /// Returns the rental suffix: /mo or nothing for sale
  static String priceSuffix(String listingType) =>
      listingType == 'Rent' ? '/mo' : '';

  /// BHK label: null → 'PG/Studio'
  static String bhkLabel(int? bhk) =>
      bhk != null ? '$bhk BHK' : 'Studio/PG';

  /// Days ago label
  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 1) return 'Just now';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}
