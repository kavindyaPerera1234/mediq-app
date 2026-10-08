import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/caregiver_model.dart';

class CaregiverService {
  final FirebaseFirestore _firestore;

  CaregiverService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _caregiversRef => _firestore.collection('caregiver_patients');

  /// Save or register a new family member/dependent
  Future<String> addCaregiverPatient(CaregiverPatientModel patient) async {
    try {
      final docRef = patient.id.isNotEmpty
          ? _caregiversRef.doc(patient.id)
          : _caregiversRef.doc();

      final toSave = CaregiverPatientModel(
        id: docRef.id,
        caregiverUserId: patient.caregiverUserId,
        patientName: patient.patientName,
        patientNic: patient.patientNic,
        relationship: patient.relationship,
        priority: patient.priority,
        lastBookedAt: DateTime.now(),
      );

      await docRef.set(toSave.toMap()).timeout(const Duration(seconds: 4));
      return docRef.id;
    } catch (e) {
      debugPrint('CaregiverService: addCaregiverPatient error: $e');
      return '';
    }
  }

  /// Real-time stream of all dependents registered by this caregiver/patient
  Stream<List<CaregiverPatientModel>> streamCaregiverPatients(String caregiverUserId) {
    try {
      final userIds = {caregiverUserId, 'user_sandeepani_001', 'user_200164801234', '200164801234'}.toList();
      return _caregiversRef
          .where('caregiverUserId', whereIn: userIds)
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs.map((doc) => CaregiverPatientModel.fromFirestore(doc)).toList();
        // Deduplicate by patientNic in case of multiple legacy entries
        final seen = <String>{};
        return list.where((item) => seen.add(item.patientNic)).toList();
      });
    } catch (e) {
      debugPrint('CaregiverService: stream error $e');
      return Stream.value([]);
    }
  }

  /// Delete a dependent from registered list
  Future<bool> deleteCaregiverPatient(String id) async {
    try {
      await _caregiversRef.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('CaregiverService: delete error $e');
      return false;
    }
  }
}
