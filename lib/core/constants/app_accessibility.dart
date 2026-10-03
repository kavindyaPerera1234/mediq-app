import 'package:flutter/material.dart';

/// Global controller for Senior Accessibility settings across the entire MediQ App
class AppAccessibility {
  /// Controls dynamic text scaling across all app screens (1.18x for seniors, 1.0x for standard)
  static final ValueNotifier<bool> isLargeTextMode = ValueNotifier<bool>(true);

  /// Controls high contrast color themes across the app
  static final ValueNotifier<bool> isHighContrastMode = ValueNotifier<bool>(false);

  /// Updates large text mode globally
  static void setLargeTextMode(bool enabled) {
    if (isLargeTextMode.value != enabled) {
      isLargeTextMode.value = enabled;
    }
  }

  /// Updates high contrast mode globally
  static void setHighContrastMode(bool enabled) {
    if (isHighContrastMode.value != enabled) {
      isHighContrastMode.value = enabled;
    }
  }
}
