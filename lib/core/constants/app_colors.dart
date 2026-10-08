import 'package:flutter/material.dart';
import 'app_accessibility.dart';

class AppColors {
  // Brand Medical Theme
  static const Color primary = Color(0xFF0056B3);
  static const Color primaryBlue = Color(0xFF0056B3);
  static const Color primaryDark = Color(0xFF003875);
  static const Color primaryLight = Color(0xFFE8F1FB);
  static const Color accent = Color(0xFF0D6EFD);
  static const Color accentBlue = Color(0xFF0D6EFD);

  // Background & Surfaces
  static const Color background = Color(0xFFF8F9FA);
  static const Color backgroundGrey = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceWhite = Colors.white;
  static const Color surfaceMuted = Color(0xFFFBFBFB);
  static const Color cardBackground = Colors.white;
  static const Color cardBg = Colors.white;
  static const Color chipBackground = Color(0xFFF1F5F9);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFE9ECEF);
  static const Color borderFocused = Color(0xFF0056B3);
  static const Color borderActive = Color(0xFF0056B3);
  static const Color divider = Color(0xFFE2E8F0);

  // Typography
  static const Color textDark = Color(0xFF1E293B);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color iconGrey = Color(0xFF64748B);

  // Semantic Status Colors
  static const Color statusGreen = Color(0xFF16A34A);
  static const Color statusGreenLight = Color(0xFFDCFCE7);
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);

  static const Color statusRed = Color(0xFFDC2626);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);

  static const Color statusOrange = Color(0xFFEA580C);
  static const Color statusOrangeLight = Color(0xFFFFEDD5);
  static const Color warning = Color(0xFFEA580C);
  static const Color warningLight = Color(0xFFFEF3C7);

  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color neutral = Color(0xFF64748B);
  static const Color neutralLight = Color(0xFFF1F5F9);

  // Slot Capping Helpers
  static const Color slotAvailable = Color(0xFFDCFCE7);
  static const Color slotFull = Color(0xFFFEE2E2);

  // Senior Mode High Contrast Colors
  static const Color seniorHighContrastBg = Color(0xFF0B132B);
  static const Color seniorHighContrastSurface = Color(0xFF1C2541);
  static const Color seniorHighContrastBorder = Color(0xFF3A506B);
  static const Color seniorHighContrastText = Color(0xFFFFFFFF);
  static const Color seniorHighContrastAccent = Color(0xFF38BDF8);

  // Dynamic Accessibility Helpers
  static bool get isDark => AppAccessibility.isHighContrastMode.value;
  static Color get pageBg => isDark ? seniorHighContrastBg : background;
  static Color get cardSurface => isDark ? seniorHighContrastSurface : surface;
  static Color get innerCardBg => isDark ? const Color(0xFF141E33) : background;
  static Color get cardBorder => isDark ? seniorHighContrastBorder : border;
  static Color get headingText => isDark ? seniorHighContrastText : textDark;
  static Color get bodyText => isDark ? const Color(0xFFCBD5E1) : textSecondary;
  static Color get accentColor => isDark ? seniorHighContrastAccent : primary;
  static Color get chipBg => isDark ? const Color(0xFF243356) : chipBackground;
  static Color get appBarBg => isDark ? seniorHighContrastSurface : primary;
  static Color get navBg => isDark ? seniorHighContrastSurface : Colors.white;
}