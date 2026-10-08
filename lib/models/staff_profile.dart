import 'package:cloud_firestore/cloud_firestore.dart';

class StaffProfile {
  final String userId;
  final String staffId;
  final String role; // doctor, nurse, receptionist, admin
  final String hospitalId;
  final String departmentId;
  final String employeeNumber;
  final bool isActive;
  final DateTime? createdAt;

  StaffProfile({
    required this.userId,
    required this.staffId,
    required this.role,
    required this.hospitalId,
    required this.departmentId,
    required this.employeeNumber,
    this.isActive = true,
    this.createdAt,
  });

  factory StaffProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StaffProfile(
      userId: data['userId'] ?? doc.id,
      staffId: data['staffId'] ?? '',
      role: data['role'] ?? 'doctor',
      hospitalId: data['hospitalId'] ?? '',
      departmentId: data['departmentId'] ?? '',
      employeeNumber: data['employeeNumber'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'staffId': staffId,
      'role': role,
      'hospitalId': hospitalId,
      'departmentId': departmentId,
      'employeeNumber': employeeNumber,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
