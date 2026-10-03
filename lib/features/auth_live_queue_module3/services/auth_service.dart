import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../patient_appointment_scheduling_module1/screens/patient_main_screen.dart';
import '../screens/auth/splash_screen.dart';
import 'package:mediq_app/screens/staff_dashboard_screen.dart';
import 'package:mediq_app/services/auth_service.dart' as m4_auth;
import 'package:mediq_app/features/admin_dashboard/screens/admin_dashboard_screen.dart';

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
  Future<String> loginWithEmailPassword(String phoneOrEmail, String password) async {
    try {
      String emailToUse = phoneOrEmail.trim();

      // If the user entered a phone number instead of email:
      if (!emailToUse.contains('@')) {
        final formattedPhone = formatToE164(emailToUse);
        final rawPhone = emailToUse;

        // Query Firestore users collection with both formatted and raw representations
        var userQuery = await _firestore
            .collection(AppConstants.usersCollection)
            .where('phoneNumber', isEqualTo: formattedPhone)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          userQuery = await _firestore
              .collection(AppConstants.usersCollection)
              .where('phoneNumber', isEqualTo: rawPhone)
              .limit(1)
              .get();
        }
        if (userQuery.docs.isEmpty) {
          userQuery = await _firestore
              .collection(AppConstants.usersCollection)
              .where('phone', isEqualTo: rawPhone)
              .limit(1)
              .get();
        }
        if (userQuery.docs.isEmpty) {
          userQuery = await _firestore
              .collection(AppConstants.usersCollection)
              .where('phone', isEqualTo: formattedPhone)
              .limit(1)
              .get();
        }

        if (userQuery.docs.isNotEmpty) {
          final data = userQuery.docs.first.data();
          final storedEmail = (data['email'] ?? '').toString();
          if (storedEmail.isNotEmpty && storedEmail.contains('@')) {
            emailToUse = storedEmail;
          } else {
            emailToUse = '${formattedPhone.replaceAll('+', '')}@mediq.lk';
          }
        } else {
          emailToUse = '${formattedPhone.replaceAll('+', '')}@mediq.lk';
        }
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
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
          email: emailToUse,
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

  // ── Patient Login with Phone Number (lookup registered user) ─────────────

  Future<bool> loginPatient(String phoneNumber) async {
    final formatted = formatToE164(phoneNumber);
    final raw = phoneNumber.trim();
    try {
      var query = await _firestore
          .collection(AppConstants.usersCollection)
          .where('phoneNumber', isEqualTo: formatted)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        query = await _firestore
            .collection(AppConstants.usersCollection)
            .where('phoneNumber', isEqualTo: raw)
            .limit(1)
            .get();
      }
      if (query.docs.isEmpty) {
        query = await _firestore
            .collection(AppConstants.usersCollection)
            .where('phone', isEqualTo: raw)
            .limit(1)
            .get();
      }
      if (query.docs.isEmpty) {
        query = await _firestore
            .collection(AppConstants.usersCollection)
            .where('phone', isEqualTo: formatted)
            .limit(1)
            .get();
      }

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        _currentUser = UserModel.fromMap(doc.data(), id: doc.id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Login patient lookup notice: $e");
      return false;
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
        MaterialPageRoute(builder: (_) => AdminDashboardScreen()),
        (route) => false,
      );
    } else if (isStaff) {
      final m4Auth = m4_auth.AuthService();
      m4Auth.loadCurrentStaffProfile();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => StaffDashboardScreen(authService: m4Auth)),
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

  // ── Firebase Phone Authentication (SMS Verification) ───────────────────────

  /// Format local or international phone numbers to E.164 (e.g. +94771234567)
  static String formatToE164(String raw) {
    String clean = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (clean.startsWith('+')) return clean;
    if (clean.startsWith('00')) return '+${clean.substring(2)}';
    if (clean.startsWith('0')) {
      return '+94${clean.substring(1)}';
    }
    if (clean.startsWith('94')) {
      return '+$clean';
    }
    // Default prefix Sri Lanka (+94)
    return '+94$clean';
  }

  /// Sends a real 6-digit SMS verification code to the phone number via Firebase Auth
  Future<void> sendPhoneVerification({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException error) onVerificationFailed,
    required void Function(PhoneAuthCredential credential) onVerificationCompleted,
    int? resendToken,
  }) async {
    final formattedNumber = formatToE164(phoneNumber);
    debugPrint('AuthService: Sending SMS OTP to $formattedNumber');

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedNumber,
      forceResendingToken: resendToken,
      verificationCompleted: (PhoneAuthCredential credential) {
        debugPrint('AuthService: Phone verification automatically completed.');
        onVerificationCompleted(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('AuthService: Phone verification failed: ${e.code} - ${e.message}');
        onVerificationFailed(e);
      },
      codeSent: (String verificationId, int? newResendToken) {
        debugPrint('AuthService: SMS verification code sent! verificationId=$verificationId');
        onCodeSent(verificationId, newResendToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('AuthService: Auto retrieval timeout for $verificationId');
      },
      timeout: const Duration(seconds: 60),
    );
  }

  /// Verifies the 6-digit SMS OTP against Firebase Auth
  Future<bool> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      final user = _auth.currentUser;
      if (user != null) {
        try {
          await user.linkWithCredential(credential);
        } on FirebaseAuthException catch (linkErr) {
          if (linkErr.code == 'credential-already-in-use' || linkErr.code == 'provider-already-linked') {
            // Already linked
          } else {
            await _auth.signInWithCredential(credential);
          }
        }
      } else {
        await _auth.signInWithCredential(credential);
      }
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: verifyPhoneOtp error: ${e.code} - ${e.message}');
      rethrow;
    }
  }
}

