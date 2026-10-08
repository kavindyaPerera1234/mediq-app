import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediq_app/core/utils/nic_helper.dart';

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
    this.bloodGroup = 'Not Set',
    this.dateOfBirth = '',
    this.gender = 'Not Specified',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
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
    final nicStr = (data['nic'] != null && data['nic'].toString().isNotEmpty)
        ? data['nic'].toString()
        : (doc.id.isNotEmpty ? doc.id : 'N/A');

    final nicInfo = SriLankanNicHelper.decode(nicStr);

    String dob = (data['dateOfBirth'] ?? '').toString().trim();
    // If dateOfBirth is empty, missing, or was set to the legacy placeholder '1995-01-01'
    if (dob.isEmpty || dob == '1995-01-01') {
      if (nicInfo.isValid && nicInfo.dateOfBirth.isNotEmpty) {
        dob = nicInfo.dateOfBirth;
      } else if (dob == '1995-01-01') {
        dob = ''; // Clear legacy placeholder
      }
    }

    String gender = (data['gender'] ?? '').toString().trim();
    if (gender.isEmpty || gender == 'Not Specified') {
      if (nicInfo.isValid && nicInfo.gender.isNotEmpty) {
        gender = nicInfo.gender;
      } else {
        gender = 'Not Specified';
      }
    }

    String blood = (data['bloodGroup'] ?? '').toString().trim();
    if (blood.isEmpty) {
      blood = 'Not Set';
    }

    return PatientProfileModel(
      patientId: doc.id,
      fullName: (data['fullName'] != null && data['fullName'].toString().isNotEmpty)
          ? data['fullName'].toString()
          : 'Patient',
      nic: nicStr,
      phone: (data['phone'] ?? data['phoneNumber'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      bloodGroup: blood,
      dateOfBirth: dob,
      gender: gender,
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
      bloodGroup: 'Not Set',
      dateOfBirth: '',
      gender: 'Not Specified',
      emergencyContactName: '',
      emergencyContactPhone: '',
      isSeniorModeEnabled: false,
      photoUrl: '',
    );
  }
}
