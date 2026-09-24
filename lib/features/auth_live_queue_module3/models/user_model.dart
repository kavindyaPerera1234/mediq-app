enum UserRole {
  patient,
  caregiver,
  doctor,
  nurse,
  staff,
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
  final DateTime createdAt;

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
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'nic': nic,
      'age': age,
      'role': role.name,
      'isCaregiver': isCaregiver,
      'linkedPatientId': linkedPatientId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return UserModel(
      userId: id ?? map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'],
      nic: map['nic'],
      age: map['age'] != null ? (map['age'] as num).toInt() : null,
      role: UserRole.values.firstWhere(
        (r) => r.name.toLowerCase() == (map['role'] ?? 'patient').toString().toLowerCase(),
        orElse: () => UserRole.patient,
      ),
      isCaregiver: map['isCaregiver'] ?? false,
      linkedPatientId: map['linkedPatientId'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
