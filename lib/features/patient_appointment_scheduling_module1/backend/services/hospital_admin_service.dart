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

  /// Delete a government hospital from Firestore and optionally its associated departments
  Future<bool> deleteHospital(String id, {String? hospitalName}) async {
    try {
      await _firestore.collection('hospitals').doc(id).delete();

      // Also clean up matching custom departments if hospitalName provided
      if (hospitalName != null && hospitalName.isNotEmpty) {
        final deptQuery = await _firestore
            .collection('departments')
            .where('hospitalName', isEqualTo: hospitalName)
            .get();
        for (var doc in deptQuery.docs) {
          await doc.reference.delete();
        }
      }
      return true;
    } catch (e) {
      debugPrint('HospitalAdminService: deleteHospital error $e');
      return false;
    }
  }

  /// Delete all test hospitals created during testing (e.g. named 'test')
  Future<int> cleanupTestHospitals() async {
    try {
      final query = await _firestore.collection('hospitals').get();
      int count = 0;
      for (var doc in query.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().toLowerCase().trim();
        final id = doc.id.toLowerCase();
        if (name == 'test' || name.startsWith('test ') || name.contains('test') || id.startsWith('hosp_17')) {
          await doc.reference.delete();
          count++;
        }
      }
      return count;
    } catch (e) {
      debugPrint('HospitalAdminService: cleanupTestHospitals error $e');
      return 0;
    }
  }
}
