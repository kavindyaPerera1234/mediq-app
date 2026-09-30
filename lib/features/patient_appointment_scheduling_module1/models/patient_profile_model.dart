import 'package:cloud_firestore/cloud_firestore.dart';

class PatientProfileModel {
  final String patientId; // NIC or User ID
  final String fullName;
  final String nic;
  final String phone;
  final String email;
  final String bloodGroup;
  final String dateOfBirth;
  final String gender;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final bool isSeniorModeEnabled;

  const PatientProfileModel({
    required this.patientId,
    required this.fullName,
    required this.nic,
    required this.phone,
    this.email = '',
    this.bloodGroup = 'O+',
    this.dateOfBirth = '2001-08-15',
    this.gender = 'Female',
    this.emergencyContactName = 'Sunil Perera',
    this.emergencyContactPhone = '+94 77 987 6543',
    this.isSeniorModeEnabled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'fullName': fullName,
      'nic': nic,
      'phone': phone,
      'email': email,
      'bloodGroup': bloodGroup,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'isSeniorModeEnabled': isSeniorModeEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory PatientProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PatientProfileModel(
      patientId: doc.id,
      fullName: data['fullName'] ?? 'Sandeepani Perera',
      nic: data['nic'] ?? '200164801234',
      phone: data['phone'] ?? '+94 77 123 4567',
      email: data['email'] ?? 'sandeepani@gmail.com',
      bloodGroup: data['bloodGroup'] ?? 'O+',
      dateOfBirth: data['dateOfBirth'] ?? '2001-08-15',
      gender: data['gender'] ?? 'Female',
      emergencyContactName: data['emergencyContactName'] ?? 'Sunil Perera',
      emergencyContactPhone: data['emergencyContactPhone'] ?? '+94 77 987 6543',
      isSeniorModeEnabled: data['isSeniorModeEnabled'] ?? false,
    );
  }

  static PatientProfileModel defaultProfile() {
    return const PatientProfileModel(
      patientId: '200164801234',
      fullName: 'Sandeepani Perera',
      nic: '200164801234',
      phone: '+94 77 123 4567',
      email: 'sandeepani@gmail.com',
      bloodGroup: 'O+',
      dateOfBirth: '2001-08-15',
      gender: 'Female',
      emergencyContactName: 'Sunil Perera',
      emergencyContactPhone: '+94 77 987 6543',
      isSeniorModeEnabled: false,
    );
  }
}
