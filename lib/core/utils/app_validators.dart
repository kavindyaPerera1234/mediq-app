import 'package:flutter/services.dart';
import 'nic_helper.dart';

/// Centralized validation suite for MediQ.
/// Enforces Sri Lankan healthcare standards at both the UI (Form) and Service layers.
class AppValidators {
  // ── Input Formatters ────────────────────────────────────────────────────────

  /// Enforces maximum 10 digits for Sri Lankan phone numbers (e.g., 0771234567)
  static final List<TextInputFormatter> phoneFormatters = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ];

  /// Enforces maximum 12 characters for Sri Lankan NIC (12 digits new, or 9 digits + V/X old)
  static final List<TextInputFormatter> nicFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]')),
    LengthLimitingTextInputFormatter(12),
  ];

  /// Enforces maximum 2 numeric digits for patient age (1 - 99)
  static final List<TextInputFormatter> ageFormatters = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(2),
  ];

  /// Allows letters, spaces, hyphens, and dots in patient / doctor names
  static final List<TextInputFormatter> nameFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\.\-']")),
    LengthLimitingTextInputFormatter(60),
  ];

  /// Dual-purpose formatter for Patient Login / Forgot Password (Phone or Email):
  /// - When user types numbers (phone), strictly limits to 10 digits (or 11/12 with +94).
  /// - When user types email, limits to 50 characters.
  static final List<TextInputFormatter> phoneOrEmailFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@\.\+\-_]')),
    TextInputFormatter.withFunction((oldValue, newValue) {
      final text = newValue.text;
      if (text.isEmpty) return newValue;

      // If user typed letters or '@', it's an email - limit to 50 chars
      if (text.contains('@') || RegExp(r'[a-zA-Z]').hasMatch(text)) {
        if (text.length > 50) return oldValue;
        return newValue;
      }

      // If numeric/phone (digits or +)
      final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
      final maxDigits = text.startsWith('+94') ? 11 : 10;
      if (digits.length > maxDigits) {
        return oldValue;
      }
      return newValue;
    }),
  ];

  // ── Field Validators (UI & Service Layer) ───────────────────────────────────

  /// Validates Sri Lankan National Identity Card (NIC):
  /// - Old format: exactly 9 digits + 'V' or 'X' (10 chars, e.g. 951234567V)
  /// - New format: exactly 12 digits (12 chars, e.g. 200212345678)
  static String? validateNic(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'National ID (NIC) is required';
      return null;
    }

    final nic = value.trim().toUpperCase();

    // Check character length limit (Old NIC = 10 chars, New NIC = 12 chars)
    if (nic.length != 10 && nic.length != 12) {
      return 'NIC must be either 10 characters (Old) or 12 digits (New)';
    }

    // Old format: 9 digits + V or X
    final oldPattern = RegExp(r'^[0-9]{9}[VX]$');
    // New format: 12 digits
    final newPattern = RegExp(r'^[0-9]{12}$');

    if (!oldPattern.hasMatch(nic) && !newPattern.hasMatch(nic)) {
      return 'Invalid Sri Lankan NIC format (e.g. 199912345678 or 951234567V)';
    }

    // Verify calendar date and birth year logic
    final decoded = SriLankanNicHelper.decode(nic);
    if (!decoded.isValid) {
      return 'Invalid NIC number: date of birth or checksum failed';
    }

    return null;
  }

  /// Validates Sri Lankan mobile phone number:
  /// - Must be exactly 10 digits starting with '07' (or local landline '0[1-9]')
  /// - Or international E.164 format: '+947XXXXXXXX' (12 chars)
  static String? validatePhone(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'Phone number is required';
      return null;
    }

    final clean = value.replaceAll(RegExp(r'[\s\-]'), '');

    // Standard 10-digit Sri Lankan phone number (e.g., 0712345678)
    if (clean.startsWith('0')) {
      if (clean.length != 10) {
        return 'Phone number must be exactly 10 digits (e.g. 0771234567)';
      }
      if (!RegExp(r'^07[0-9]{8}$').hasMatch(clean) && !RegExp(r'^0[1-9][0-9]{8}$').hasMatch(clean)) {
        return 'Please enter a valid 10-digit Sri Lankan mobile or landline number';
      }
      return null;
    }

    // International +94 format (e.g., +94771234567)
    if (clean.startsWith('+94') || clean.startsWith('94')) {
      final normalized = clean.startsWith('+') ? clean : '+$clean';
      if (!RegExp(r'^\+947[0-9]{8}$').hasMatch(normalized) && !RegExp(r'^\+94[1-9][0-9]{8}$').hasMatch(normalized)) {
        return 'Invalid international format. Expected +94 followed by 9 digits';
      }
      return null;
    }

    if (clean.length != 10) {
      return 'Phone number must be exactly 10 digits (e.g. 0771234567)';
    }

    return 'Phone number must start with 0 (e.g. 0771234567)';
  }

  /// Validates patient age:
  /// - Hard 2-digit limit: between 1 and 99 years old
  static String? validateAge(dynamic value, {bool required = true}) {
    if (value == null || value.toString().trim().isEmpty) {
      if (required) return 'Age is required';
      return null;
    }

    final str = value.toString().trim();
    final parsed = int.tryParse(str);

    if (parsed == null) {
      return 'Please enter a valid numeric age';
    }

    if (str.length > 2) {
      return 'Age cannot exceed 2 digits (maximum 99 years)';
    }

    if (parsed < 1 || parsed > 99) {
      return 'Age must be between 1 and 99 years';
    }

    return null;
  }

  /// Validates full name:
  /// - Minimum 2 characters
  /// - Letters, dots, hyphens, and spaces only
  static String? validateFullName(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'Full name is required';
      return null;
    }

    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (trimmed.length > 60) {
      return 'Name is too long (maximum 60 characters)';
    }

    if (!RegExp(r"^[a-zA-Z\s\.\-']+$").hasMatch(trimmed)) {
      return 'Name can only contain alphabetic letters and spaces';
    }

    return null;
  }

  /// Validates email address if provided
  static String? validateEmail(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'Email address is required';
      return null;
    }

    final trimmed = value.trim();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address (e.g. patient@mediq.lk)';
    }

    return null;
  }

  /// Validates password / security PIN
  static String? validatePassword(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'Password is required';
      return null;
    }

    if (value.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  /// Validates a dual-purpose input that can be either a 10-digit phone number or an email
  static String? validatePhoneOrEmail(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'Please enter your phone number or email';
      return null;
    }

    final trimmed = value.trim();

    // If it contains '@' or alphabetic letters, validate as email
    if (trimmed.contains('@') || RegExp(r'[a-zA-Z]').hasMatch(trimmed)) {
      return validateEmail(trimmed, required: required);
    }

    // Otherwise enforce 10-digit Sri Lankan phone validation
    return validatePhone(trimmed, required: required);
  }

  /// Backend assertion helper: throws [ArgumentError] if validation fails
  static void assertValid({
    String? fullName,
    String? phone,
    String? nic,
    int? age,
    String? email,
  }) {
    if (fullName != null) {
      final err = validateFullName(fullName);
      if (err != null) throw ArgumentError(err);
    }
    if (phone != null) {
      final err = validatePhone(phone);
      if (err != null) throw ArgumentError(err);
    }
    if (nic != null && nic.trim().isNotEmpty) {
      final err = validateNic(nic);
      if (err != null) throw ArgumentError(err);
    }
    if (age != null) {
      final err = validateAge(age);
      if (err != null) throw ArgumentError(err);
    }
    if (email != null && email.trim().isNotEmpty) {
      final err = validateEmail(email);
      if (err != null) throw ArgumentError(err);
    }
  }
}
