import 'dart:math';

class EmiUtils {
  EmiUtils._();

  /// Calculates EMI using the standard formula:
  /// EMI = (P * r * (1+r)^n) / ((1+r)^n - 1)
  ///
  /// [principal] — loan amount (price - down payment)
  /// [annualRate] — annual interest rate in percent (e.g. 8.5)
  /// [tenureYears] — loan tenure in years
  static double calculateEmi({
    required double principal,
    required double annualRate,
    required int tenureYears,
  }) {
    if (principal <= 0 || annualRate <= 0 || tenureYears <= 0) return 0;

    final r = annualRate / 12 / 100; // monthly rate
    final n = tenureYears * 12; // total months

    final emi = (principal * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
    return emi;
  }

  /// Formats EMI value in Indian convention (e.g. ₹45,230)
  static String formatEmi(double emi) {
    final rounded = emi.round();
    // Indian number format: last 3 digits, then groups of 2
    final str = rounded.toString();
    if (str.length <= 3) return '₹$str';

    final last3 = str.substring(str.length - 3);
    var remaining = str.substring(0, str.length - 3);
    final buf = StringBuffer();
    while (remaining.length > 2) {
      buf.write('${remaining.substring(0, remaining.length - 2)},');
      remaining = remaining.substring(remaining.length - 2);
    }
    // remaining is 1 or 2 chars now
    return '₹${buf.toString().isEmpty ? '' : buf.toString()}$remaining,$last3';
  }
}
