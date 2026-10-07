import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalAdminService {
  final FirebaseFirestore _firestore;

  HospitalAdminService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Save or update a government hospital
  Future<bool> saveHospital({
    required String id,
    required String name,
    required String district,
    required String address,
    required String phone,
    required bool isActive,
  }) async {
    try {
      await _firestore.collection('hospitals').doc(id).set({
        'hospitalId': id,
        'name': name,
        'district': district,
        'address': address,
        'phone': phone,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('HospitalAdminService: saveHospital error $e');
      return false;
    }
  }

  /// Save or update an OPD Department / Clinic
  Future<bool> saveDepartment({
    required String id,
    required String name,
    required String hospitalName,
    required String roomNumber,
    required String operatingHours,
    required int capacityLimit,
    required bool isActive,
  }) async {
    try {
      await _firestore.collection('departments').doc(id).set({
        'departmentId': id,
        'name': name,
        'hospitalName': hospitalName,
        'roomNumber': roomNumber,
        'operatingHours': operatingHours,
        'capacityLimit': capacityLimit,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('HospitalAdminService: saveDepartment error $e');
      return false;
    }
  }

  /// Update Slot Capping & Emergency Status
  Future<bool> updateSlotConfig({
    required String slotId,
    required String slotRange,
    required String date,
    required String clinic,
    required int capacity,
    required int bookedCount,
    required bool isClosed,
    String reason = '',
  }) async {
    try {
      final docId = '${slotId}_$date';
      await _firestore.collection('appointment_slots').doc(docId).set({
        'slotId': slotId,
        'slotRange': slotRange,
        'date': date,
        'clinic': clinic,
        'capacity': capacity,
        'bookedCount': bookedCount,
        'isClosed': isClosed,
        'closureReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('HospitalAdminService: updateSlotConfig error $e');
      return false;
    }
  }
}
