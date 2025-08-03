import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Blue theme matching web)
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);

  // Secondary Colors
  static const Color secondary = Color(0xFF64748B);
  static const Color secondaryDark = Color(0xFF475569);
  static const Color secondaryLight = Color(0xFF94A3B8);

  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);

  // Background Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Border Colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF2563EB), // Blue
    Color(0xFF22C55E), // Green
    Color(0xFFF59E0B), // Orange
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange Alt
    Color(0xFF84CC16), // Lime
  ];

  // Status Indicators
  static const Color statusGood = Color(0xFF22C55E);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusCritical = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
