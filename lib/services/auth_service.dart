import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/staff_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel? currentUserModel;
  StaffProfile? currentStaffProfile;

  /// Get currently authenticated Firebase User (from Module 3 / FirebaseAuth)
  User? get currentUser => _auth.currentUser;
  User? get currentFirebaseUser => _auth.currentUser;

  /// Load staff user model and staff profile for the logged-in user
  Future<void> loadCurrentStaffProfile() async {
    final user = currentUser;
    if (user != null) {
      await loadStaffDataByUid(user.uid);
    } else {
      await _loadFallbackStaffData('doc-silva-uid');
    }
  }

  Future<void> loadStaffDataByUid(String uid) async {
    try {
      final userDoc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
      if (userDoc.exists) {
        currentUserModel = UserModel.fromFirestore(userDoc);
      }
      final staffDoc = await _db.collection(AppConstants.staffProfilesCollection).doc(uid).get();
      if (staffDoc.exists) {
        currentStaffProfile = StaffProfile.fromFirestore(staffDoc);
      }
    } catch (e) {
      // Fallback
    }

    if (currentUserModel == null || currentStaffProfile == null) {
      await _loadFallbackStaffData(uid);
    }
  }

  Future<void> _loadFallbackStaffData(String uid) async {
    currentUserModel ??= UserModel(
      uid: uid,
      email: 'doctor@mediq.lk',
      fullName: 'Dr. Silva',
      phone: '0771234567',
      nic: '198512345678',
      role: 'doctor',
      isActive: true,
    );

    currentStaffProfile ??= StaffProfile(
      userId: uid,
      staffId: 'DOC-001',
      role: 'doctor',
      hospitalId: 'HOSP-001',
      departmentId: 'DEPT-001',
      employeeNumber: 'EMP-101',
      isActive: true,
    );
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    currentUserModel = null;
    currentStaffProfile = null;
  }
}
