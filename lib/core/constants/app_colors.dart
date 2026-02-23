import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary   = Color(0xFF121212); // near-black (HTML primary)
  static const Color accent    = Color(0xFFFF7A45); // orange accent
  static const Color primaryDark = Color(0xFF1E40AF);

  // Backgrounds
  static const Color background  = Color(0xFFF7F7F7);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color surfaceAlt  = Color(0xFFF1F3F4);
  static const Color surfaceDark = Color(0xFF232323);

  // Text
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF6B7280); // gray-500
  static const Color textHint      = Color(0xFF9CA3AF); // gray-400

  // Borders
  static const Color border  = Color(0xFFE5E7EB); // gray-200
  static const Color divider = Color(0xFFF3F4F6); // gray-100

  // Status
  static const Color success  = Color(0xFF10B981);
  static const Color error    = Color(0xFFEF4444);
  static const Color warning  = Color(0xFFF59E0B);
  static const Color verified = Color(0xFF10B981);

  // Listing type badges
  static const Color rent = Color(0xFF6366F1);
  static const Color buy  = Color(0xFF1C4ED8);
}
