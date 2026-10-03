import 'package:flutter/material.dart';

/// Global controller for Senior Accessibility settings across the entire MediQ App
class AppAccessibility {
  /// Controls dynamic text scaling across all app screens (1.32x for seniors, 1.0x for standard)
  static final ValueNotifier<bool> isLargeTextMode = ValueNotifier<bool>(false);

  /// Controls high contrast color themes across the entire app
  static final ValueNotifier<bool> isHighContrastMode = ValueNotifier<bool>(false);

  /// Controls simplified 3-tab large navigation for seniors
  static final ValueNotifier<bool> isSimplifiedNav = ValueNotifier<bool>(false);

  /// Controls spoken voice announcements across the app
  static final ValueNotifier<bool> isVoiceGuidance = ValueNotifier<bool>(false);

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

  /// Updates simplified navigation globally
  static void setSimplifiedNav(bool enabled) {
    if (isSimplifiedNav.value != enabled) {
      isSimplifiedNav.value = enabled;
    }
  }

  /// Updates voice guidance globally
  static void setVoiceGuidance(bool enabled) {
    if (isVoiceGuidance.value != enabled) {
      isVoiceGuidance.value = enabled;
    }
  }
}
