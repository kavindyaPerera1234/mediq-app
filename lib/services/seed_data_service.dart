import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';

class SeedDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> seedDemoData() async {
    try {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      const hospitalId = 'nhsl';
      const departmentId = 'gen_med';
      final dynamicSessionId = '${hospitalId}_${departmentId}_$dateStr';

      // Check if reference data is already present to prevent any overwrites
      final hospCheck = await _db.collection(AppConstants.hospitalsCollection).doc(hospitalId).get();
      if (hospCheck.exists) {
        debugPrint('Firestore: Reference hospital and departments already present.');
        return true;
      }

      // 1. Hospitals & Departments
      await _db.collection(AppConstants.hospitalsCollection).doc(hospitalId).set({
        'hospitalId': hospitalId,
        'name': 'National Hospital of Sri Lanka',
        'location': 'Colombo',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection(AppConstants.departmentsCollection).doc(departmentId).set({
        'departmentId': departmentId,
        'hospitalId': hospitalId,
        'name': 'General Medicine OPD',
        'code': 'GEN-MED',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Staff Users & Profiles (Needed for doctor/nurse logins)
      final staffUsers = [
        {
          'uid': 'doc-silva-uid',
          'email': 'doctor@mediq.lk',
          'fullName': 'Dr. Silva',
          'phone': '0771234567',
          'nic': '198512345678',
          'role': 'doctor',
          'staffId': 'DOC-001',
          'employeeNumber': 'EMP-101',
        },
        {
          'uid': 'nurse-fernando-uid',
          'email': 'nurse@mediq.lk',
          'fullName': 'Nurse Fernando',
          'phone': '0772345678',
          'nic': '199023456789',
          'role': 'nurse',
          'staffId': 'NUR-001',
          'employeeNumber': 'EMP-102',
        },
        {
          'uid': 'rec-silva-uid',
          'email': 'receptionist@mediq.lk',
          'fullName': 'Receptionist Silva',
          'phone': '0773456789',
          'nic': '199234567890',
          'role': 'receptionist',
          'staffId': 'REC-001',
          'employeeNumber': 'EMP-103',
        },
      ];

      for (var staff in staffUsers) {
        await _db.collection(AppConstants.usersCollection).doc(staff['uid'] as String).set({
          'uid': staff['uid'],
          'email': staff['email'],
          'fullName': staff['fullName'],
          'phone': staff['phone'],
          'nic': staff['nic'],
          'role': staff['role'],
          'preferredLanguage': 'en',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _db.collection(AppConstants.staffProfilesCollection).doc(staff['uid'] as String).set({
          'userId': staff['uid'],
          'staffId': staff['staffId'],
          'role': staff['role'],
          'hospitalId': hospitalId,
          'departmentId': departmentId,
          'employeeNumber': staff['employeeNumber'],
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Initial Clean Queue Session starting from A-000 (first patient will get A-001)
      final sessionMap = {
        'queueSessionId': dynamicSessionId,
        'hospitalId': hospitalId,
        'departmentId': departmentId,
        'date': dateStr,
        'status': 'active',
        'currentToken': '—',
        'currentTokenNumber': '—',
        'currentTokenServing': '—',
        'nowServing': '—',
        'lastIssuedToken': 'A-000',
        'lastIssuedTokenNumber': 'A-000',
        'estimatedMinutesPerPatient': 10,
        'delayMinutes': 0,
        'delayReason': '',
        'totalTokens': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _db.collection(AppConstants.queueSessionsCollection).doc(dynamicSessionId).set(sessionMap);
      await _db.collection(AppConstants.queueSessionsCollection).doc('QS-001').set({...sessionMap, 'queueSessionId': 'QS-001'});

      // 6. Initial Sample Queue Event (so queue_events collection appears in Firestore)
      await _db.collection(AppConstants.queueEventsCollection).doc('EVT-pat-018').set({
        'eventId': 'EVT-pat-018',
        'queueSessionId': dynamicSessionId,
        'queueEntryId': 'QE-pat-018',
        'appointmentId': 'APT-pat-018',
        'performedBy': 'doc-silva-uid',
        'actionType': 'completed',
        'eventType': 'completed',
        'previousStatus': 'called',
        'newStatus': 'completed',
        'reason': 'Routine OPD Consultation Completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 7. Initial Sample Consultation (so consultations collection appears in Firestore)
      await _db.collection(AppConstants.consultationsCollection).doc('CNS-pat-018').set({
        'consultationId': 'CNS-pat-018',
        'appointmentId': 'APT-pat-018',
        'queueEntryId': 'QE-pat-018',
        'patientId': 'pat-018',
        'staffId': 'doc-silva-uid',
        'doctorId': 'doc-silva-uid',
        'hospitalId': hospitalId,
        'departmentId': departmentId,
        'notes': 'Routine OPD Examination completed. Patient prescribed standard regimen.',
        'status': 'completed',
        'startedAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 8. Initial Sample Delay Update (so delay_updates collection appears in Firestore)
      await _db.collection(AppConstants.delayUpdatesCollection).doc('DLY-001').set({
        'delayUpdateId': 'DLY-001',
        'queueSessionId': dynamicSessionId,
        'hospitalId': hospitalId,
        'departmentId': departmentId,
        'reason': 'OPD Morning Setup',
        'delayReason': 'OPD Morning Setup',
        'delayMinutes': 0,
        'additionalMinutes': 0,
        'createdBy': 'doc-silva-uid',
        'performedBy': 'doc-silva-uid',
        'isActive': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Cloud Firestore: All 8 MediQ Module 4 collections successfully created and populated.');
      return true;
    } catch (e) {
      debugPrint('Cloud Firestore Seeding Error: $e');
      return false;
    }
  }
}
