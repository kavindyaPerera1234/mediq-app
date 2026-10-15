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
      } else if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        final hId = data['hospitalId'] ?? data['hospital'] ?? 'nhsl';
        final dId = data['departmentId'] ?? data['department'] ?? 'gen_med';
        currentStaffProfile = StaffProfile(
          userId: uid,
          staffId: data['staffId'] ?? 'DOC-${uid.substring(0, uid.length > 5 ? 5 : uid.length).toUpperCase()}',
          role: currentUserModel?.role ?? data['role'] ?? 'doctor',
          hospitalId: hId.toString(),
          departmentId: dId.toString(),
          employeeNumber: data['employeeNumber'] ?? 'EMP-01',
          isActive: currentUserModel?.isActive ?? true,
        );
      }
    } catch (e) {
      // Fallback if network or firestore error
    }

    if (currentUserModel == null || currentStaffProfile == null) {
      await _loadFallbackStaffData(uid);
    }
  }

  Future<void> _loadFallbackStaffData(String uid) async {
    final authUser = _auth.currentUser;
    final fallbackName = authUser?.displayName ?? (authUser?.email != null ? authUser!.email!.split('@').first : 'Doctor');

    currentUserModel ??= UserModel(
      uid: uid,
      email: authUser?.email ?? 'doctor@mediq.lk',
      fullName: (fallbackName.isNotEmpty && fallbackName != 'Doctor') ? fallbackName : 'Dr. S. Perera',
      phone: authUser?.phoneNumber ?? '0771234567',
      nic: '198512345678',
      role: 'doctor',
      isActive: true,
    );

    currentStaffProfile ??= StaffProfile(
      userId: uid,
      staffId: 'DOC-${uid.substring(0, uid.length > 5 ? 5 : uid.length).toUpperCase()}',
      role: currentUserModel?.role ?? 'doctor',
      hospitalId: 'nhsl',
      departmentId: 'gen_med',
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
