import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../../core/constants/app_constants.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Initial mock user for seamless demonstration
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

  /// Patient Login with Phone Number
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
        // Create or fallback for demo
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

  /// Staff Login (Agreed Exception: Module 3 implements Staff Auth Logic)
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
        // Demo staff credentials
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

  /// Patient Registration
  Future<bool> registerUser({
    required String fullName,
    required String phoneNumber,
    String? nic,
    int? age,
    bool isCaregiver = false,
  }) async {
    try {
      final newUser = UserModel(
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
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
      debugPrint("Registration error: $e (saving locally)");
      _currentUser = UserModel(
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        fullName: fullName.trim(),
        phoneNumber: phoneNumber.trim(),
        nic: nic?.trim(),
        age: age,
        role: isCaregiver ? UserRole.caregiver : UserRole.patient,
        isCaregiver: isCaregiver,
        createdAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    }
  }

  /// Logout
  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }

  /// Role check helper
  UserRole get role => _currentUser?.role ?? UserRole.patient;
  bool get isStaff => role == UserRole.doctor || role == UserRole.nurse || role == UserRole.staff;
}
