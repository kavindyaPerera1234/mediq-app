import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/patient_profile_model.dart';
import '../../../auth_live_queue_module3/services/auth_service.dart';

class ProfileService {
  final FirebaseFirestore _firestore;

  ProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _profilesRef => _firestore.collection('patient_profiles');

  /// Reactive active profile notifier accessible across Module 1 screens
  static final ValueNotifier<PatientProfileModel> activeProfileNotifier =
      ValueNotifier<PatientProfileModel>(PatientProfileModel.defaultProfile());

  /// Sync active profile with the currently authenticated user
  Future<PatientProfileModel> syncWithCurrentUser() async {
    try {
      // 1. Check AuthService current user first (instant memory cache)
      final authUser = AuthService().currentUser;
      if (authUser != null && authUser.fullName.isNotEmpty) {
        final nic = (authUser.nic != null && authUser.nic!.isNotEmpty) ? authUser.nic! : '';
        final profileDocId = (nic.isNotEmpty && nic != 'N/A') ? nic : authUser.userId;
        try {
          final profileDoc = await _profilesRef.doc(profileDocId).get();
          if (profileDoc.exists) {
            final profile = PatientProfileModel.fromFirestore(profileDoc);
            activeProfileNotifier.value = profile;
            return profile;
          }
        } catch (_) {}

        final newProfile = PatientProfileModel(
          patientId: profileDocId,
          fullName: authUser.fullName,
          nic: (nic.isNotEmpty && nic != 'N/A') ? nic : (authUser.userId.length > 8 ? authUser.userId.substring(0, 8).toUpperCase() : authUser.userId),
          phone: authUser.phoneNumber,
          email: authUser.email ?? '',
          bloodGroup: 'O+',
        );
        activeProfileNotifier.value = newProfile;
        return newProfile;
      }

      // 2. Query Firebase Auth & Firestore users/{uid}
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          final fullName = (data['fullName'] ?? '').toString();
          final nic = (data['nic'] ?? '').toString();
          final phone = (data['phoneNumber'] ?? data['phone'] ?? '').toString();
          final email = (data['email'] ?? user.email ?? '').toString();

          final profileDocId = (nic.isNotEmpty && nic != 'N/A') ? nic : user.uid;
          final profileDoc = await _profilesRef.doc(profileDocId).get();
          if (profileDoc.exists) {
            final profile = PatientProfileModel.fromFirestore(profileDoc);
            activeProfileNotifier.value = profile;
            return profile;
          }

          if (fullName.isNotEmpty) {
            final newProfile = PatientProfileModel(
              patientId: profileDocId,
              fullName: fullName,
              nic: (nic.isNotEmpty && nic != 'N/A') ? nic : user.uid.substring(0, 8).toUpperCase(),
              phone: phone,
              email: email,
              bloodGroup: (data['bloodGroup'] ?? 'O+').toString(),
              photoUrl: (data['photoUrl'] ?? user.photoURL ?? '').toString(),
            );
            activeProfileNotifier.value = newProfile;
            return newProfile;
          }
        } else if (user.displayName != null && user.displayName!.isNotEmpty) {
          final newProfile = PatientProfileModel(
            patientId: user.uid,
            fullName: user.displayName!,
            nic: user.uid.substring(0, 8).toUpperCase(),
            phone: user.phoneNumber ?? '',
            email: user.email ?? '',
            bloodGroup: 'O+',
            photoUrl: user.photoURL ?? '',
          );
          activeProfileNotifier.value = newProfile;
          return newProfile;
        }
      }
    } catch (e) {
      debugPrint('ProfileService: syncWithCurrentUser error: $e');
    }
    return activeProfileNotifier.value;
  }

  /// Sign out current patient and reset active profile
  Future<void> signOut() async {
    activeProfileNotifier.value = PatientProfileModel.defaultProfile();
  }

  /// Fetch profile from Firestore with local fallback
  Future<PatientProfileModel> getPatientProfile(String patientNic) async {
    try {
      final doc = await _profilesRef.doc(patientNic).get().timeout(const Duration(seconds: 3));
      if (doc.exists) {
        final profile = PatientProfileModel.fromFirestore(doc);
        activeProfileNotifier.value = profile;
        return profile;
      }
    } catch (e) {
      debugPrint('ProfileService: getPatientProfile fallback: $e');
    }
    return activeProfileNotifier.value;
  }

  /// Update or save patient profile
  Future<bool> savePatientProfile(PatientProfileModel profile) async {
    activeProfileNotifier.value = profile;
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final docId = (profile.nic.isNotEmpty && profile.nic != 'N/A')
          ? profile.nic
          : (currentUid ?? profile.patientId);

      await _profilesRef
          .doc(docId)
          .set(profile.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 4));

      if (currentUid != null) {
        await _firestore.collection('users').doc(currentUid).set({
          'fullName': profile.fullName,
          'phone': profile.phone,
          'phoneNumber': profile.phone,
          'email': profile.email,
          'bloodGroup': profile.bloodGroup,
          if (profile.photoUrl.isNotEmpty) 'photoUrl': profile.photoUrl,
        }, SetOptions(merge: true)).catchError((_) {});
      }
      return true;
    } catch (e) {
      debugPrint('ProfileService: savePatientProfile error: $e');
      return false;
    }
  }

  /// Update profile photo URL directly
  Future<bool> updateProfilePhoto(String patientNic, String photoUrl) async {
    try {
      activeProfileNotifier.value = activeProfileNotifier.value.copyWith(photoUrl: photoUrl);
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final docId = (patientNic.isNotEmpty && patientNic != 'N/A')
          ? patientNic
          : (currentUid ?? 'default');

      await _profilesRef
          .doc(docId)
          .set({'photoUrl': photoUrl, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true))
          .timeout(const Duration(seconds: 4));

      if (currentUid != null) {
        await _firestore.collection('users').doc(currentUid).set({
          'photoUrl': photoUrl,
        }, SetOptions(merge: true)).catchError((_) {});
      }
      return true;
    } catch (e) {
      debugPrint('ProfileService: updateProfilePhoto error: $e');
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
