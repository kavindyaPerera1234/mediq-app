import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors 
  static const Color primary = Color(0xFF0056B3);
  static const Color primaryLight = Color(0xFFE0F2FE); // Soft light blue for selected items
  static const Color primaryDark = Color(0xFF003E82);

  // Background & Surface
  static const Color background = Color(0xFFF8FAFC); // Clean light gray screen background
  static const Color surface = Color(0xFFFFFFFF);    // White card fill

  // Typography Colors
  static const Color textPrimary = Color(0xFF0F172A);   // Dark Navy for Headings
  static const Color textSecondary = Color(0xFF64748B); // Muted Slate for Subtitles
  static const Color textMuted = Color(0xFF94A3B8);

  // Border & Dividers
  static const Color border = Color(0xFFE2E8F0);        // Subtle card border
  static const Color borderActive = Color(0xFF0056B3);  // Active blue border

  // Status & Badges
  static const Color success = Color(0xFF16A34A);       // Green for Confirmed / Available
  static const Color successLight = Color(0xFFDCFCE7);  // Light green badge background
  static const Color error = Color(0xFFDC2626);         // Red for Full slots & Cancel
  static const Color errorLight = Color(0xFFFEE2E2);    // Light red badge background
  static const Color warning = Color(0xFFD97706);       // Amber for alerts
  static const Color warningLight = Color(0xFFFEF3C7);  // Light amber badge background
  static const Color info = Color(0xFF2563EB);          // Blue for active/info
  static const Color infoLight = Color(0xFFDBEAFE);     // Light blue badge background
  static const Color neutral = Color(0xFF64748B);       // Slate gray for neutral
  static const Color neutralLight = Color(0xFFF1F5F9);  // Light gray badge background
}