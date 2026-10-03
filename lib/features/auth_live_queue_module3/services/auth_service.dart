import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../patient_appointment_scheduling_module1/screens/patient_main_screen.dart';
import '../../patient_appointment_scheduling_module1/admin/screens/hospital_admin_dashboard.dart';
import '../screens/auth/splash_screen.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// Get currently signed-in Firebase user
  User? getCurrentFirebaseUser() => _auth.currentUser;
  User? get firebaseUser => _auth.currentUser;

  /// Get current user profile
  UserModel? getCurrentUserProfile() => _currentUser;

  /// Get current user role string
  String getCurrentUserRole() => _currentUser?.role.name ?? 'patient';

  /// Check whether current user account is active
  bool isUserActive() => _currentUser?.isActive ?? true;

  // ── Session check (called from SplashScreen) ──────────────────────────────

  /// Checks if a Firebase Auth session exists. If so, reads the user's role
  /// from Firestore and populates [_currentUser].
  /// Returns the user's role string, or null if no session.
  Future<String?> checkExistingSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Read role from Firestore users/{uid}
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!, id: doc.id);
        notifyListeners();
        return _currentUser!.role.name; // 'admin', 'patient', 'doctor', etc.
      } else {
        // User exists in Auth but not Firestore — treat as new / incomplete
        await _auth.signOut();
        return null;
      }
    } catch (e) {
      debugPrint("Session check notice: $e");
      return null;
    }
  }

  // ── Firebase Auth email+password login (Staff / Admin / Patient) ──────────

  /// Standard login alias
  Future<String> login(String email, String password) =>
      loginWithEmailPassword(email, password);

  /// Signs in with email + password via Firebase Auth, then reads the user doc
  /// from Firestore to get their role and active status.
  Future<String> loginWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user!.uid;

      // Read role & profile from Firestore
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!, id: doc.id);
        if (!_currentUser!.isActive) {
          await _auth.signOut();
          _currentUser = null;
          notifyListeners();
          throw FirebaseAuthException(
            code: 'user-disabled',
            message: 'This account has been deactivated. Please contact hospital admin.',
          );
        }
        notifyListeners();
        return _currentUser!.role.name;
      } else {
        // Auth succeeded but no Firestore profile — create basic staff profile
        final newUser = UserModel(
          userId: uid,
          fullName: credential.user!.displayName ?? 'Staff Member',
          phoneNumber: '',
          email: email.trim(),
          role: UserRole.staff,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .set(newUser.toMap());
        _currentUser = newUser;
        notifyListeners();
        return 'staff';
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth error: ${e.code} - ${e.message}");
      rethrow;
    }
  }

  // ── Password Reset ────────────────────────────────────────────────────────

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      debugPrint("Password reset error: ${e.code} - ${e.message}");
      rethrow;
    }
  }

  // ── Registration: Patient or Caregiver ───────────────────────────────────

  /// Creates a real Firebase Authentication account and sets Firestore users/{uid}
  Future<UserModel> registerPatientOrCaregiver({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String? nic,
    int? age,
    bool isCaregiver = false,
    String preferredLanguage = 'en',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user!.uid;

      final newUser = UserModel(
        userId: uid,
        fullName: fullName.trim(),
        phoneNumber: phoneNumber.trim(),
        email: email.trim(),
        nic: nic?.trim(),
        age: age,
        role: isCaregiver ? UserRole.caregiver : UserRole.patient,
        isCaregiver: isCaregiver,
        preferredLanguage: preferredLanguage,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(newUser.toMap());

      _currentUser = newUser;
      notifyListeners();
      return newUser;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase registration error: ${e.code} - ${e.message}");
      rethrow;
    }
  }

  /// Backward-compatible registerUser (fallback without password)
  Future<bool> registerUser({
    required String fullName,
    required String phoneNumber,
    String? nic,
    int? age,
    bool isCaregiver = false,
  }) async {
    try {
      final uid = _auth.currentUser?.uid ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
      final newUser = UserModel(
        userId: uid,
        fullName: fullName.trim(),
        phoneNumber: phoneNumber.trim(),
        nic: nic?.trim(),
        age: age,
        role: isCaregiver ? UserRole.caregiver : UserRole.patient,
        isCaregiver: isCaregiver,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(newUser.userId)
          .set(newUser.toMap());

      _currentUser = newUser;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Registration error: $e");
      return false;
    }
  }

  // ── Patient Login with Phone Number (demo / SMS OTP fallback) ─────────────

  Future<bool> loginPatient(String phoneNumber) async {
    try {
      final query = await _firestore
          .collection(AppConstants.usersCollection)
          .where('phoneNumber', isEqualTo: phoneNumber.trim())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        _currentUser = UserModel.fromMap(doc.data(), id: doc.id);
      } else {
        _currentUser = UserModel(
          userId: 'patient_${DateTime.now().millisecondsSinceEpoch}',
          fullName: 'Kamal Gunaratne',
          phoneNumber: phoneNumber.trim(),
          role: UserRole.patient,
          createdAt: DateTime.now(),
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Login notice: $e (using fallback session)");
      _currentUser = UserModel(
        userId: 'patient_${DateTime.now().millisecondsSinceEpoch}',
        fullName: 'Kamal Gunaratne',
        phoneNumber: phoneNumber.trim(),
        role: UserRole.patient,
        createdAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    }
  }

  /// Staff Login (legacy staffId-based)
  Future<bool> loginStaff(String staffId, String password) async {
    try {
      final query = await _firestore
          .collection('staff_profiles')
          .where('staffId', isEqualTo: staffId.trim())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        _currentUser = UserModel(
          userId: doc.id,
          fullName: data['name'] ?? 'Hospital Staff',
          phoneNumber: data['phoneNumber'] ?? '0112345678',
          role: (data['role'] == 'doctor') ? UserRole.doctor : UserRole.nurse,
          createdAt: DateTime.now(),
        );
      } else {
        _currentUser = UserModel(
          userId: staffId,
          fullName: 'Dr. H. M. Perera',
          phoneNumber: '0112345678',
          role: UserRole.doctor,
          createdAt: DateTime.now(),
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Staff login notice: $e (using demo staff)");
      _currentUser = UserModel(
        userId: staffId,
        fullName: 'Dr. H. M. Perera',
        phoneNumber: '0112345678',
        role: UserRole.doctor,
        createdAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    }
  }

  // ── Role-based Navigation Routing ─────────────────────────────────────────

  /// Central routing mechanism per spec Section 3
  void routeUserByRole(BuildContext context) {
    if (!context.mounted) return;
    final r = role;

    if (r == UserRole.admin) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HospitalAdminDashboard()),
        (route) => false,
      );
    } else if (isStaff) {
      // Route staff (or re-enter splash until Module 4 Staff console is added)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } else {
      // Patient or caregiver -> Module 1 Patient Dashboard
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PatientMainScreen(initialIndex: 0)),
        (route) => false,
      );
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    _currentUser = null;
    notifyListeners();
  }

  // ── Demo user (for testing without auth) ──────────────────────────────────

  void initDemoUser() {
    _currentUser = UserModel(
      userId: 'patient_001',
      fullName: 'Kamal Gunaratne',
      phoneNumber: '0771234567',
      email: 'kamal@gmail.com',
      nic: '197214502341',
      age: 52,
      role: UserRole.patient,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    notifyListeners();
  }

  // ── Role helpers ──────────────────────────────────────────────────────────

  UserRole get role => _currentUser?.role ?? UserRole.patient;

  bool get isAdmin => role == UserRole.admin;

  bool get isStaff =>
      role == UserRole.doctor ||
      role == UserRole.nurse ||
      role == UserRole.staff ||
      role == UserRole.receptionist;

  bool get isPatientOrCaregiver =>
      role == UserRole.patient || role == UserRole.caregiver;
}
