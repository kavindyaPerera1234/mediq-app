import 'package:flutter/material.dart';
import '../constants/app_accessibility.dart';

/// Global language controller for MediQ App supporting English, Simple Sinhala, and Tamil.
class AppLanguage {
  static final ValueNotifier<String> currentLanguage = ValueNotifier<String>('en');

  /// Tracks whether the user explicitly changed language during this app session
  static bool hasUserExplicitlySelected = false;

  static bool _initialized = false;
  static void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    AppAccessibility.onLanguageChanged = (lang) {
      if (currentLanguage.value != lang) {
        currentLanguage.value = lang;
      }
      hasUserExplicitlySelected = true;
    };
  }

  static bool get isEnglish {
    ensureInitialized();
    return currentLanguage.value == 'en';
  }

  static bool get isSinhala {
    ensureInitialized();
    return currentLanguage.value == 'si';
  }

  static bool get isTamil {
    ensureInitialized();
    return currentLanguage.value == 'ta';
  }

  static String get code {
    ensureInitialized();
    return currentLanguage.value;
  }

  static void setLanguage(String langCode, {bool isExplicit = false}) {
    ensureInitialized();
    if (langCode == 'en' || langCode == 'si' || langCode == 'ta') {
      if (isExplicit) {
        hasUserExplicitlySelected = true;
      }
      if (currentLanguage.value != langCode) {
        currentLanguage.value = langCode;
      }
      if (AppAccessibility.currentLanguage.value != langCode) {
        AppAccessibility.currentLanguage.value = langCode;
      }
    }
  }

  static void setEnglish({bool isExplicit = false}) => setLanguage('en', isExplicit: isExplicit);
  static void setSinhala({bool isExplicit = false}) => setLanguage('si', isExplicit: isExplicit);
  static void setTamil({bool isExplicit = false}) => setLanguage('ta', isExplicit: isExplicit);
}
