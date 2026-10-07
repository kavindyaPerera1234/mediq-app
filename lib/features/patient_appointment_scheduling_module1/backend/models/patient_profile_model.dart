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
  final String photoUrl;

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
    this.photoUrl = '',
  });

  PatientProfileModel copyWith({
    String? patientId,
    String? fullName,
    String? nic,
    String? phone,
    String? email,
    String? bloodGroup,
    String? dateOfBirth,
    String? gender,
    String? emergencyContactName,
    String? emergencyContactPhone,
    bool? isSeniorModeEnabled,
    String? photoUrl,
  }) {
    return PatientProfileModel(
      patientId: patientId ?? this.patientId,
      fullName: fullName ?? this.fullName,
      nic: nic ?? this.nic,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      isSeniorModeEnabled: isSeniorModeEnabled ?? this.isSeniorModeEnabled,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

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
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory PatientProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PatientProfileModel(
      patientId: doc.id,
      fullName: (data['fullName'] != null && data['fullName'].toString().isNotEmpty)
          ? data['fullName'].toString()
          : 'Patient',
      nic: (data['nic'] != null && data['nic'].toString().isNotEmpty)
          ? data['nic'].toString()
          : (doc.id.isNotEmpty ? doc.id : 'N/A'),
      phone: (data['phone'] ?? data['phoneNumber'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      bloodGroup: data['bloodGroup'] ?? 'O+',
      dateOfBirth: data['dateOfBirth'] ?? '1995-01-01',
      gender: data['gender'] ?? 'Not Specified',
      emergencyContactName: data['emergencyContactName'] ?? '',
      emergencyContactPhone: data['emergencyContactPhone'] ?? '',
      isSeniorModeEnabled: data['isSeniorModeEnabled'] ?? false,
      photoUrl: data['photoUrl'] ?? '',
    );
  }

  static PatientProfileModel defaultProfile() {
    return const PatientProfileModel(
      patientId: 'patient_default',
      fullName: 'Patient',
      nic: 'N/A',
      phone: '',
      email: '',
      bloodGroup: 'O+',
      dateOfBirth: '1995-01-01',
      gender: 'Not Specified',
      emergencyContactName: '',
      emergencyContactPhone: '',
      isSeniorModeEnabled: false,
      photoUrl: '',
    );
  }
}
