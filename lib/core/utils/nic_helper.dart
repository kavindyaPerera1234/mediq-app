class SriLankanNicInfo {
  final bool isValid;
  final String dateOfBirth; // 'YYYY-MM-DD'
  final String gender;      // 'Male' or 'Female'
  final int? age;

  const SriLankanNicInfo({
    required this.isValid,
    this.dateOfBirth = '',
    this.gender = '',
    this.age,
  });

  @override
  String toString() =>
      'SriLankanNicInfo(isValid: $isValid, dob: $dateOfBirth, gender: $gender, age: $age)';
}

/// Helper to decode Sri Lankan National Identity Card (NIC) numbers.
/// Supports both:
///  - Old format: 9 digits + optional 'V' or 'X' (e.g., 951234567V)
///  - New format: 12 digits (e.g., 200285403099)
class SriLankanNicHelper {
  static SriLankanNicInfo decode(String? rawNic) {
    if (rawNic == null) return const SriLankanNicInfo(isValid: false);
    final nic = rawNic.trim().toUpperCase();
    if (nic.isEmpty || nic == 'N/A') return const SriLankanNicInfo(isValid: false);

    int year = 0;
    int dayOfYear = 0;

    final oldMatch = RegExp(r'^(\d{2})(\d{3})\d{4}[VX]?$').firstMatch(nic);
    final newMatch = RegExp(r'^(\d{4})(\d{3})\d{5}$').firstMatch(nic);

    if (newMatch != null) {
      year = int.tryParse(newMatch.group(1)!) ?? 0;
      dayOfYear = int.tryParse(newMatch.group(2)!) ?? 0;
    } else if (oldMatch != null) {
      final yearPart = int.tryParse(oldMatch.group(1)!) ?? 0;
      year = 1900 + yearPart;
      dayOfYear = int.tryParse(oldMatch.group(2)!) ?? 0;
    } else {
      return const SriLankanNicInfo(isValid: false);
    }

    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear) {
      return const SriLankanNicInfo(isValid: false);
    }

    String gender = 'Male';
    if (dayOfYear > 500) {
      gender = 'Female';
      dayOfYear -= 500;
    }

    // In Sri Lankan NIC system, days are from 1 to 366 (calculated with 29 days in Feb)
    if (dayOfYear < 1 || dayOfYear > 366) {
      return const SriLankanNicInfo(isValid: false);
    }

    final daysInMonths = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    int month = 1;
    int day = dayOfYear;

    for (int i = 0; i < daysInMonths.length; i++) {
      if (day <= daysInMonths[i]) {
        month = i + 1;
        break;
      }
      day -= daysInMonths[i];
    }

    // Handle non-leap year Feb 29 adjustment (clamp to Feb 28)
    final isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    if (!isLeapYear && month == 2 && day > 28) {
      day = 28;
    }

    final mStr = month.toString().padLeft(2, '0');
    final dStr = day.toString().padLeft(2, '0');
    final dob = '$year-$mStr-$dStr';

    final now = DateTime.now();
    int age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }

    return SriLankanNicInfo(
      isValid: true,
      dateOfBirth: dob,
      gender: gender,
      age: age >= 0 ? age : null,
    );
  }
}
