import 'package:flutter/material.dart';

/// Global language controller for MediQ App supporting English, Simple Sinhala, and Tamil.
class AppLanguage {
  static final ValueNotifier<String> currentLanguage = ValueNotifier<String>('en');

  static bool get isEnglish => currentLanguage.value == 'en';
  static bool get isSinhala => currentLanguage.value == 'si';
  static bool get isTamil => currentLanguage.value == 'ta';

  static String get code => currentLanguage.value;

  static void setLanguage(String langCode) {
    if (langCode == 'en' || langCode == 'si' || langCode == 'ta') {
      if (currentLanguage.value != langCode) {
        currentLanguage.value = langCode;
      }
    }
  }

  static void setEnglish() => setLanguage('en');
  static void setSinhala() => setLanguage('si');
  static void setTamil() => setLanguage('ta');
}
