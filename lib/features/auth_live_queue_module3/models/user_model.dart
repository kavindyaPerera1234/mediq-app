import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  patient,
  caregiver,
  doctor,
  nurse,
  staff,
  admin,
  receptionist,
}

class UserModel {
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String? nic;
  final int? age;
  final UserRole role;
  final bool isCaregiver;
  final String? linkedPatientId;
  final String preferredLanguage; // 'en', 'si', 'ta'
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.nic,
    this.age,
    required this.role,
    this.isCaregiver = false,
    this.linkedPatientId,
    this.preferredLanguage = 'en',
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Aliases matching shared specification
  String get uid => userId;
  String get phone => phoneNumber;

  Map<String, dynamic> toMap() {
    return {
      'uid': userId,
      'userId': userId,
      'fullName': fullName,
      'phone': phoneNumber,
      'phoneNumber': phoneNumber,
      'email': email,
      'nic': nic,
      'age': age,
      'role': role.name,
      'isCaregiver': isCaregiver,
      'linkedPatientId': linkedPatientId,
      'preferredLanguage': preferredLanguage,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return UserModel(
      userId: id ?? map['uid'] ?? map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phone'] ?? map['phoneNumber'] ?? '',
      email: map['email'],
      nic: map['nic'],
      age: map['age'] != null ? (map['age'] as num).toInt() : null,
      role: UserRole.values.firstWhere(
        (r) => r.name.toLowerCase() == (map['role'] ?? 'patient').toString().toLowerCase(),
        orElse: () => UserRole.patient,
      ),
      isCaregiver: map['isCaregiver'] ?? false,
      linkedPatientId: map['linkedPatientId'],
      preferredLanguage: map['preferredLanguage'] ?? 'en',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null ? parseDate(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }
}
