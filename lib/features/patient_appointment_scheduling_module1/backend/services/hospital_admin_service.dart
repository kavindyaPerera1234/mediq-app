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
          'operatingHours': '8:00 AM - 02:00 PM',
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
    String? hospitalId,
  }) async {
    try {
      String resolvedHospId = hospitalId ?? '';
      if (resolvedHospId.isEmpty) {
        final q = await _firestore.collection('hospitals').where('name', isEqualTo: hospitalName).limit(1).get();
        if (q.docs.isNotEmpty) {
          resolvedHospId = q.docs.first.id;
        }
      }

      await _firestore.collection('departments').doc(id).set({
        'id': id,
        'departmentId': id,
        'name': name,
        'hospitalName': hospitalName,
        'hospitalId': resolvedHospId,
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

  /// Populate standard OPD clinics for a specific hospital (e.g., General Medicine, Pediatrics, Eye Clinic, etc.)
  Future<int> populateStandardClinics({
    required String hospitalName,
    String? hospitalId,
  }) async {
    try {
      final standardClinics = [
        {'name': 'General Medicine OPD', 'room': 'OPD Room 01', 'hours': '8:00 AM - 02:00 PM', 'cap': 25},
        {'name': 'Pediatric Clinic', 'room': 'OPD Room 02', 'hours': '8:00 AM - 02:00 PM', 'cap': 20},
        {'name': 'Cardiology Clinic', 'room': 'OPD Room 03', 'hours': '8:00 AM - 01:00 PM', 'cap': 15},
        {'name': 'Ophthalmology (Eye Clinic)', 'room': 'OPD Room 04', 'hours': '8:00 AM - 02:00 PM', 'cap': 20},
        {'name': 'ENT & Audiology Clinic', 'room': 'OPD Room 05', 'hours': '8:00 AM - 01:00 PM', 'cap': 18},
        {'name': 'Dental & Maxillofacial OPD', 'room': 'Dental Unit 01', 'hours': '8:00 AM - 02:00 PM', 'cap': 15},
        {'name': 'Orthopedic Clinic', 'room': 'OPD Room 07', 'hours': '8:00 AM - 02:00 PM', 'cap': 20},
      ];

      final cleanHosp = hospitalName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
      int added = 0;

      for (var c in standardClinics) {
        final cleanClinic = c['name']!.toString().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
        final docId = 'dept_${cleanHosp}_$cleanClinic';

        await _firestore.collection('departments').doc(docId).set({
          'departmentId': docId,
          'id': docId,
          'name': c['name'],
          'hospitalName': hospitalName,
          'hospitalId': hospitalId ?? cleanHosp,
          'roomNumber': c['room'],
          'operatingHours': c['hours'],
          'capacityLimit': c['cap'],
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        added++;
      }
      return added;
    } catch (e) {
      debugPrint('HospitalAdminService: populateStandardClinics error $e');
      return 0;
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

  /// Delete a department / clinic by ID
  Future<bool> deleteDepartment(String id) async {
    try {
      await _firestore.collection('departments').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('HospitalAdminService: deleteDepartment error $e');
      return false;
    }
  }

  /// Delete duplicate or test departments
  Future<int> cleanupDuplicateDepartments({String? hospitalName}) async {
    try {
      Query query = _firestore.collection('departments');
      if (hospitalName != null && hospitalName.isNotEmpty) {
        query = query.where('hospitalName', isEqualTo: hospitalName);
      }
      final snapshot = await query.get();
      final seenKeys = <String>{};
      int deletedCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final hosp = (data['hospitalName'] ?? '').toString().trim().toLowerCase();
        final name = (data['name'] ?? '').toString().trim().toLowerCase();
        final key = '$hosp-$name';

        final isTest = name.contains('test') || doc.id.toLowerCase().contains('test');

        if (isTest || seenKeys.contains(key)) {
          await doc.reference.delete();
          deletedCount++;
        } else {
          seenKeys.add(key);
        }
      }
      return deletedCount;
    } catch (e) {
      debugPrint('HospitalAdminService: cleanupDuplicateDepartments error $e');
      return 0;
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
