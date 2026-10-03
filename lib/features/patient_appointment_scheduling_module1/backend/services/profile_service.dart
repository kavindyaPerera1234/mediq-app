import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_profile_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore;

  ProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _profilesRef => _firestore.collection('patient_profiles');

  /// Fetch profile from Firestore with local fallback
  Future<PatientProfileModel> getPatientProfile(String patientNic) async {
    try {
      final doc = await _profilesRef.doc(patientNic).get().timeout(const Duration(seconds: 3));
      if (doc.exists) {
        return PatientProfileModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('ProfileService: getPatientProfile fallback: $e');
    }
    return PatientProfileModel.defaultProfile();
  }

  /// Update or save patient profile
  Future<bool> savePatientProfile(PatientProfileModel profile) async {
    try {
      await _profilesRef
          .doc(profile.nic)
          .set(profile.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 4));
      return true;
    } catch (e) {
      debugPrint('ProfileService: savePatientProfile error: $e');
      return false;
    }
  }

  /// Get accessibility settings from profile
  Future<Map<String, bool>> getAccessibilitySettings(String patientNic) async {
    try {
      final doc = await _profilesRef.doc(patientNic).get().timeout(const Duration(seconds: 3));
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return {
          'largeTextMode': data['largeTextMode'] ?? true,
          'highContrastMode': data['highContrastMode'] ?? false,
          'simplifiedNav': data['simplifiedNav'] ?? false,
          'voiceGuidance': data['voiceGuidance'] ?? false,
        };
      }
    } catch (e) {
      debugPrint('ProfileService: getAccessibilitySettings fallback $e');
    }
    return {
      'largeTextMode': true,
      'highContrastMode': false,
      'simplifiedNav': false,
      'voiceGuidance': false,
    };
  }

  /// Save full accessibility settings to Firestore
  Future<void> saveAccessibilitySettings({
    required String patientNic,
    required bool largeTextMode,
    required bool highContrastMode,
    required bool simplifiedNav,
    required bool voiceGuidance,
  }) async {
    try {
      await _profilesRef.doc(patientNic).set({
        'isSeniorModeEnabled': largeTextMode || highContrastMode || simplifiedNav || voiceGuidance,
        'largeTextMode': largeTextMode,
        'highContrastMode': highContrastMode,
        'simplifiedNav': simplifiedNav,
        'voiceGuidance': voiceGuidance,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('ProfileService: saveAccessibilitySettings error: $e');
    }
  }

  /// Toggle Senior Accessibility Mode preference in database
  Future<void> toggleSeniorMode(String patientNic, bool enabled) async {
    try {
      await _profilesRef.doc(patientNic).set({
        'isSeniorModeEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
