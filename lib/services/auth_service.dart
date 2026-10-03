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

  User? get currentFirebaseUser => _auth.currentUser;

  Future<void> loadCurrentStaffProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      await loadStaffDataByUid(user.uid);
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
  }

  Future<AuthResult> signInStaff({
    required String usernameOrIdOrEmail,
    required String password,
  }) async {
    try {
      String input = usernameOrIdOrEmail.trim();

      // 1. Check for quick demo staff ID fallbacks if typed DOC-001 / NUR-001 / REC-001
      String targetRole = 'doctor';
      if (input.toUpperCase() == 'NUR-001' || input.toLowerCase().contains('nurse')) {
        targetRole = 'nurse';
      } else if (input.toUpperCase() == 'REC-001' || input.toLowerCase().contains('rec')) {
        targetRole = 'receptionist';
      }

      String email = input;

      // Map staff ID to email if not email format
      if (!email.contains('@')) {
        final queryByStaff = await _db
            .collection(AppConstants.staffProfilesCollection)
            .where('staffId', isEqualTo: input.toUpperCase())
            .get();

        if (queryByStaff.docs.isNotEmpty) {
          final uid = queryByStaff.docs.first.id;
          final userDoc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
          if (userDoc.exists && userDoc.data()?['email'] != null) {
            email = userDoc.data()!['email'];
          }
        } else {
          // Lookup by phone
          final queryByPhone = await _db
              .collection(AppConstants.usersCollection)
              .where('phone', isEqualTo: input)
              .get();
          if (queryByPhone.docs.isNotEmpty) {
            email = queryByPhone.docs.first.data()['email'] ?? email;
          } else {
            // Default demo email mapping if DB is not yet populated
            email = '$targetRole@mediq.lk';
          }
        }
      }

      // Try Firebase Auth Sign In
      UserCredential? credential;
      try {
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (authErr) {
        // Fallback for local demo credentials if firebase auth user not registered
        final queryUser = await _db
            .collection(AppConstants.usersCollection)
            .where('email', isEqualTo: email)
            .get();

        if (queryUser.docs.isNotEmpty) {
          final uid = queryUser.docs.first.id;
          await loadStaffDataByUid(uid);
          if (currentUserModel != null && currentUserModel!.isActive) {
            return AuthResult.success(currentUserModel!, currentStaffProfile!);
          }
        }
        
        // Instant Demo Login Fallback for university testing
        return await signInDemoRole(targetRole);
      }

      if (credential.user != null) {
        final uid = credential.user!.uid;
        await loadStaffDataByUid(uid);
      }

      if (currentUserModel == null) {
        return await signInDemoRole(targetRole);
      }

      return AuthResult.success(currentUserModel!, currentStaffProfile!);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  // Demo Login Quick Preset Loader
  Future<AuthResult> signInDemoRole(String role) async {
    try {
      final staffQuery = await _db
          .collection(AppConstants.staffProfilesCollection)
          .where('role', isEqualTo: role)
          .limit(1)
          .get();

      if (staffQuery.docs.isNotEmpty) {
        final uid = staffQuery.docs.first.id;
        await loadStaffDataByUid(uid);
        if (currentUserModel != null) {
          return AuthResult.success(currentUserModel!, currentStaffProfile!);
        }
      }

      // Default mock fallback if Firestore database not yet seeded
      final mockUid = role == 'doctor' ? 'doc-silva-uid' : (role == 'nurse' ? 'nurse-fernando-uid' : 'rec-silva-uid');
      currentUserModel = UserModel(
        uid: mockUid,
        email: '$role@mediq.lk',
        fullName: role == 'doctor' ? 'Dr. Silva' : (role == 'nurse' ? 'Nurse Fernando' : 'Receptionist Silva'),
        phone: '0771234567',
        nic: '198512345678',
        role: role,
        isActive: true,
      );
      currentStaffProfile = StaffProfile(
        userId: mockUid,
        staffId: role == 'doctor' ? 'DOC-001' : (role == 'nurse' ? 'NUR-001' : 'REC-001'),
        role: role,
        hospitalId: 'HOSP-001',
        departmentId: 'DEPT-001',
        employeeNumber: 'EMP-100',
        isActive: true,
      );

      return AuthResult.success(currentUserModel!, currentStaffProfile!);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    currentUserModel = null;
    currentStaffProfile = null;
  }
}

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final UserModel? user;
  final StaffProfile? staffProfile;

  AuthResult.success(this.user, this.staffProfile)
      : isSuccess = true,
        errorMessage = null;

  AuthResult.failure(this.errorMessage)
      : isSuccess = false,
        user = null,
        staffProfile = null;
}
