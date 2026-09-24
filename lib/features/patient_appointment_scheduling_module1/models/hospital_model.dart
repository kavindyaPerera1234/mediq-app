import 'package:flutter/material.dart';

// 1. OPD Clinic Model
class OpdClinic {
  final String id;
  final String name;
  final String hours;
  final IconData icon;
  final bool isOpen;

  OpdClinic({
    required this.id,
    required this.name,
    required this.hours,
    required this.icon,
    this.isOpen = true,
  });
}

// 2. Government Hospital Model
class GovernmentHospital {
  final String id;
  final String name;
  final String location;
  final bool isOpdAvailable;
  final List<OpdClinic> clinics;

  GovernmentHospital({
    required this.id,
    required this.name,
    required this.location,
    this.isOpdAvailable = true,
    required this.clinics,
  });

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
          ),
          OpdClinic(
            id: 'ortho',
            name: 'Orthopedics (Bone)',
            hours: '8:00 AM - 12:00 PM',
            icon: Icons.accessibility_new_outlined, // Bone / Mobility
          ),
          OpdClinic(
            id: 'ent',
            name: 'ENT (Ear, Nose, Throat)',
            hours: '8:30 AM - 12:00 PM',
            icon: Icons.hearing_outlined, // Ear
          ),
          OpdClinic(
            id: 'derma',
            name: 'Dermatology (Skin)',
            hours: '8:30 AM - 11:30 AM',
            icon: Icons.healing_outlined, // Skin
          ),
          OpdClinic(
            id: 'pedia',
            name: 'Pediatrics (Children)',
            hours: '8:00 AM - 1:00 PM',
            icon: Icons.child_care_outlined, // Baby
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
          ),
        ],
      ),
    ];
  }
}