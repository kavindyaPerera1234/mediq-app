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
      final docRef = _firestore.collection('hospitals').doc(id);
      await docRef.set({
        'id': id,
        'hospitalId': id,
        'name': name,
        'district': district,
        'address': address,
        'location': address.isNotEmpty ? '$district • $address' : district,
        'phone': phone,
        'isActive': isActive,
        'isOpdAvailable': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also ensure at least one default department exists in 'departments' collection for this hospital
      final deptQuery = await _firestore
          .collection('departments')
          .where('hospitalName', isEqualTo: name)
          .limit(1)
          .get();

      if (deptQuery.docs.isEmpty) {
        final cleanId = id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
        await _firestore.collection('departments').doc('dept_gen_$cleanId').set({
          'departmentId': 'dept_gen_$cleanId',
          'name': 'General Medicine OPD',
          'hospitalId': id,
          'hospitalName': name,
          'roomNumber': 'OPD Room 01',
          'operatingHours': '8:00 AM - 12:00 PM',
          'capacityLimit': 25,
          'isActive': isActive,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

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
      final clinicKey = clinic.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
      final clinicDocId = '${clinicKey}_${slotId}_$date';
      final legacyDocId = '${slotId}_$date';

      final data = {
        'slotId': slotId,
        'slotRange': slotRange,
        'date': date,
        'clinic': clinic,
        'capacity': capacity,
        'bookedCount': bookedCount,
        'isClosed': isClosed,
        'closureReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('appointment_slots').doc(clinicDocId).set(data, SetOptions(merge: true));
      await _firestore.collection('appointment_slots').doc(legacyDocId).set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('HospitalAdminService: updateSlotConfig error $e');
      return false;
    }
  }
}
