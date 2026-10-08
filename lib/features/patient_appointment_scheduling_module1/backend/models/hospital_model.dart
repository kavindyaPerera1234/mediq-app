import 'package:flutter/material.dart';

// 1. OPD Clinic Model
class OpdClinic {
  final String id;
  final String name;
  final String hours;
  final IconData icon;
  final bool isOpen;
  final String roomNumber;

  OpdClinic({
    required this.id,
    required this.name,
    required this.hours,
    required this.icon,
    this.isOpen = true,
    this.roomNumber = 'OPD Room 01',
  });
}

// 2. Government Hospital Model
class GovernmentHospital {
  final String id;
  final String name;
  final String location;
  final String district;
  final String phone;
  final bool isOpdAvailable;
  final List<OpdClinic> clinics;

  GovernmentHospital({
    required this.id,
    required this.name,
    required this.location,
    this.district = 'Colombo',
    this.phone = '',
    this.isOpdAvailable = true,
    required this.clinics,
  });

  static List<OpdClinic> getDefaultClinics(String hospitalPrefix) {
    final clean = hospitalPrefix.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return [
      OpdClinic(
        id: 'gen_med_$clean',
        name: 'General Medicine OPD',
        hours: '8:00 AM - 12:00 PM',
        icon: Icons.medical_services_outlined,
        roomNumber: 'OPD Room 01',
      ),
      OpdClinic(
        id: 'ortho_$clean',
        name: 'Orthopedics (Bone)',
        hours: '8:00 AM - 12:00 PM',
        icon: Icons.accessibility_new_outlined,
        roomNumber: 'OPD Room 02',
      ),
      OpdClinic(
        id: 'pedia_$clean',
        name: 'Pediatrics (Children)',
        hours: '8:00 AM - 1:00 PM',
        icon: Icons.child_care_outlined,
        roomNumber: 'OPD Room 03',
      ),
      OpdClinic(
        id: 'ent_$clean',
        name: 'ENT (Ear, Nose, Throat)',
        hours: '8:30 AM - 12:00 PM',
        icon: Icons.hearing_outlined,
        roomNumber: 'OPD Room 04',
      ),
    ];
  }

  factory GovernmentHospital.fromMap(Map<String, dynamic> data, String docId, {List<OpdClinic>? customClinics}) {
    final name = (data['name'] ?? 'Government Hospital').toString();
    final district = (data['district'] ?? 'Colombo').toString();
    final address = (data['address'] ?? '').toString();
    final location = (data['location'] != null && data['location'].toString().isNotEmpty)
        ? data['location'].toString()
        : (address.isNotEmpty ? '$district • $address' : district);
    final phone = (data['phone'] ?? '').toString();
    final isActive = data['isActive'] == true || data['isOpdAvailable'] == true;

    return GovernmentHospital(
      id: docId.isNotEmpty ? docId : (data['hospitalId'] ?? data['id'] ?? 'hosp').toString(),
      name: name,
      location: location,
      district: district,
      phone: phone,
      isOpdAvailable: isActive,
      clinics: customClinics != null && customClinics.isNotEmpty
          ? customClinics
          : getDefaultClinics(docId),
    );
  }

  // Sample data matching our exact Figma screens!
  static List<GovernmentHospital> getSampleHospitals() {
    return [
      GovernmentHospital(
        id: 'nhsl',
        name: 'National Hospital of Sri Lanka',
        location: 'Colombo 10',
        clinics: [
          OpdClinic(
            id: 'gen_med',
            name: 'General Medicine',
            hours: '8:00 AM - 12:00 PM',
            icon: Icons.medical_services_outlined, // Stethoscope
            roomNumber: 'OPD Room 01',
          ),
          OpdClinic(
            id: 'ortho',
            name: 'Orthopedics (Bone)',
            hours: '8:00 AM - 12:00 PM',
            icon: Icons.accessibility_new_outlined, // Bone / Mobility
            roomNumber: 'OPD Room 03',
          ),
          OpdClinic(
            id: 'ent',
            name: 'ENT (Ear, Nose, Throat)',
            hours: '8:30 AM - 12:00 PM',
            icon: Icons.hearing_outlined, // Ear
            roomNumber: 'OPD Room 07',
          ),
          OpdClinic(
            id: 'derma',
            name: 'Dermatology (Skin)',
            hours: '8:30 AM - 11:30 AM',
            icon: Icons.healing_outlined, // Skin
            roomNumber: 'OPD Room 09',
          ),
          OpdClinic(
            id: 'pedia',
            name: 'Pediatrics (Children)',
            hours: '8:00 AM - 1:00 PM',
            icon: Icons.child_care_outlined, // Baby
            roomNumber: 'OPD Room 05',
          ),
        ],
      ),
      GovernmentHospital(
        id: 'csth',
        name: 'Colombo South Teaching Hospital',
        location: 'Kalubowila',
        clinics: [
          OpdClinic(
            id: 'gen_med_csth',
            name: 'General Medicine OPD',
            hours: '8:00 AM - 12:00 PM',
            icon: Icons.medical_services_outlined,
            roomNumber: 'OPD Room 02',
          ),
        ],
      ),
      GovernmentHospital(
        id: 'lrh',
        name: 'Lady Ridgeway Hospital',
        location: 'Colombo 08',
        clinics: [
          OpdClinic(
            id: 'pedia_lrh',
            name: 'Pediatrics OPD',
            hours: '8:00 AM - 1:00 PM',
            icon: Icons.child_care_outlined,
            roomNumber: 'OPD Room 04',
          ),
        ],
      ),
      GovernmentHospital(
        id: 'cnth',
        name: 'Colombo North Teaching Hospital',
        location: 'Ragama',
        clinics: [
          OpdClinic(
            id: 'gen_med_cnth',
            name: 'General Medicine OPD',
            hours: '8:00 AM - 12:00 PM',
            icon: Icons.medical_services_outlined,
            roomNumber: 'OPD Room 01',
          ),
        ],
      ),
    ];
  }
}