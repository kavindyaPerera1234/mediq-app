import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';

class SeedDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> seedDemoData() async {
    try {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // 1. Hospitals & Departments (Multi-Hospital & Multi-OPD linkage)
      final hospitals = [
        {'id': 'nhsl', 'name': 'National Hospital of Sri Lanka', 'location': 'Colombo'},
        {'id': 'hosp_kandy', 'name': 'Kandy General Hospital', 'location': 'Kandy'},
        {'id': 'hosp_karapitiya', 'name': 'Karapitiya Teaching Hospital', 'location': 'Galle'},
      ];

      for (var h in hospitals) {
        await _db.collection(AppConstants.hospitalsCollection).doc(h['id']!).set({
          'hospitalId': h['id'],
          'name': h['name'],
          'location': h['location'],
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final departments = [
        {'id': 'gen_med', 'hospId': 'nhsl', 'name': 'General Medicine OPD', 'code': 'GEN-MED'},
        {'id': 'dept_pediatrics', 'hospId': 'nhsl', 'name': 'Pediatrics OPD', 'code': 'PED-OPD'},
        {'id': 'dept_cardiology', 'hospId': 'nhsl', 'name': 'Cardiology OPD', 'code': 'CARD-OPD'},
        {'id': 'dept_pediatrics', 'hospId': 'hosp_kandy', 'name': 'Pediatrics OPD (Kandy)', 'code': 'KANDY-PED'},
        {'id': 'gen_med', 'hospId': 'hosp_kandy', 'name': 'General Medicine OPD (Kandy)', 'code': 'KANDY-GEN'},
      ];

      for (var d in departments) {
        await _db.collection(AppConstants.departmentsCollection).doc('${d['hospId']}_${d['id']}').set({
          'departmentId': d['id'],
          'hospitalId': d['hospId'],
          'name': d['name'],
          'code': d['code'],
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Staff Users & Profiles (Storing specific hospitalId and departmentId)
      final staffUsers = [
        {
          'uid': 'doc-silva-uid',
          'email': 'doctor@mediq.lk',
          'fullName': 'Dr. S. Perera',
          'phone': '0771234567',
          'nic': '198512345678',
          'role': 'doctor',
          'staffId': 'DOC-001',
          'hospitalId': 'nhsl',
          'departmentId': 'gen_med',
          'employeeNumber': 'EMP-101',
        },
        {
          'uid': 'doc-perera-uid',
          'email': 'dr.perera@mediq.lk',
          'fullName': 'Dr. Perera',
          'phone': '0779998887',
          'nic': '198299988877',
          'role': 'doctor',
          'staffId': 'DOC-002',
          'hospitalId': 'hosp_kandy',
          'departmentId': 'dept_pediatrics',
          'employeeNumber': 'EMP-104',
        },
        {
          'uid': 'nurse-fernando-uid',
          'email': 'nurse@mediq.lk',
          'fullName': 'Nurse Fernando',
          'phone': '0772345678',
          'nic': '199023456789',
          'role': 'nurse',
          'staffId': 'NUR-001',
          'hospitalId': 'nhsl',
          'departmentId': 'gen_med',
          'employeeNumber': 'EMP-102',
        },
        {
          'uid': 'rec-silva-uid',
          'email': 'receptionist@mediq.lk',
          'fullName': 'Receptionist Nimali',
          'phone': '0773456789',
          'nic': '199234567890',
          'role': 'receptionist',
          'staffId': 'REC-001',
          'hospitalId': 'nhsl',
          'departmentId': 'gen_med',
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
          'hospitalId': staff['hospitalId'],
          'departmentId': staff['departmentId'],
          'employeeNumber': staff['employeeNumber'],
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. NHSL General Medicine OPD Queue
      final nhslSessionId = 'nhsl_gen_med_$dateStr';
      final nhslPatients = [
        {'id': 'pat-018', 'name': 'Nimal Perera', 'phone': '0711111111', 'token': 'A-018', 'status': 'completed', 'priority': 'normal', 'pos': 1},
        {'id': 'pat-019', 'name': 'Nimali Wijesekera', 'phone': '0712222222', 'token': 'A-019', 'status': 'called', 'priority': 'normal', 'pos': 2},
        {'id': 'pat-020', 'name': 'Suresh Kumar', 'phone': '0713333333', 'token': 'A-020', 'status': 'on_hold', 'priority': 'normal', 'pos': 3},
        {'id': 'pat-021', 'name': 'Chamari D.', 'phone': '0714444444', 'token': 'A-021', 'status': 'waiting', 'priority': 'normal', 'pos': 4},
        {'id': 'pat-022', 'name': 'Ranjith M.', 'phone': '0715555555', 'token': 'A-022', 'status': 'waiting', 'priority': 'normal', 'pos': 5},
        {'id': 'pat-025', 'name': 'Amal R.', 'phone': '0716666666', 'token': 'A-025', 'status': 'waiting', 'priority': 'emergency', 'pos': 6},
      ];

      await _db.collection(AppConstants.queueSessionsCollection).doc(nhslSessionId).set({
        'queueSessionId': nhslSessionId,
        'hospitalId': 'nhsl',
        'departmentId': 'gen_med',
        'date': dateStr,
        'status': 'active',
        'currentToken': 'A-019',
        'currentTokenNumber': 'A-019',
        'lastIssuedToken': 'A-025',
        'lastIssuedTokenNumber': 'A-025',
        'estimatedMinutesPerPatient': 10,
        'delayMinutes': 0,
        'delayReason': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _db.collection(AppConstants.queueSessionsCollection).doc('QS-001').set({
        'queueSessionId': 'QS-001',
        'hospitalId': 'nhsl',
        'departmentId': 'gen_med',
        'date': dateStr,
        'status': 'active',
        'currentToken': 'A-019',
        'currentTokenNumber': 'A-019',
        'lastIssuedToken': 'A-025',
        'lastIssuedTokenNumber': 'A-025',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (var p in nhslPatients) {
        await _db.collection(AppConstants.usersCollection).doc(p['id'] as String).set({
          'uid': p['id'],
          'email': '${p['id']}@patient.mediq.lk',
          'fullName': p['name'],
          'phone': p['phone'],
          'nic': '2000${p['id']}',
          'role': 'patient',
          'preferredLanguage': 'en',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _db.collection(AppConstants.appointmentsCollection).doc('APT-${p['id']}').set({
          'appointmentId': 'APT-${p['id']}',
          'patientId': p['id'],
          'caregiverId': '',
          'caregiverPatientId': '',
          'hospitalId': 'nhsl',
          'departmentId': 'gen_med',
          'slotId': 'SLOT-001',
          'appointmentDate': dateStr,
          'startTime': '08:30 AM',
          'endTime': '12:30 PM',
          'status': p['status'] == 'completed' ? 'completed' : (p['status'] == 'called' ? 'called' : 'booked'),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _db.collection(AppConstants.queueEntriesCollection).doc('QE-${p['id']}').set({
          'queueSessionId': nhslSessionId,
          'appointmentId': 'APT-${p['id']}',
          'patientId': p['id'],
          'patientName': p['name'],
          'tokenCode': p['token'],
          'tokenNumber': p['token'],
          'status': p['status'],
          'queuePosition': p['pos'],
          'estimatedWaitMinutes': ((p['pos'] as int) - 1) * 10,
          'priority': p['priority'],
          'calledAt': p['status'] == 'called' || p['status'] == 'completed' ? FieldValue.serverTimestamp() : null,
          'completedAt': p['status'] == 'completed' ? FieldValue.serverTimestamp() : null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 4. Kandy Pediatrics OPD Queue (Dr. Perera's Clinic)
      final kandySessionId = 'hosp_kandy_dept_pediatrics_$dateStr';
      final kandyPatients = [
        {'id': 'pat-kandy-001', 'name': 'Sanduni Perera', 'phone': '0778881111', 'token': 'P-001', 'status': 'waiting', 'priority': 'normal', 'pos': 1},
        {'id': 'pat-kandy-002', 'name': 'Kavindu Fernando', 'phone': '0778882222', 'token': 'P-002', 'status': 'waiting', 'priority': 'emergency', 'pos': 2},
      ];

      await _db.collection(AppConstants.queueSessionsCollection).doc(kandySessionId).set({
        'queueSessionId': kandySessionId,
        'hospitalId': 'hosp_kandy',
        'departmentId': 'dept_pediatrics',
        'date': dateStr,
        'status': 'active',
        'currentToken': 'P-001',
        'currentTokenNumber': 'P-001',
        'lastIssuedToken': 'P-002',
        'lastIssuedTokenNumber': 'P-002',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (var p in kandyPatients) {
        await _db.collection(AppConstants.usersCollection).doc(p['id'] as String).set({
          'uid': p['id'],
          'email': '${p['id']}@patient.mediq.lk',
          'fullName': p['name'],
          'phone': p['phone'],
          'nic': '2001${p['id']}',
          'role': 'patient',
          'preferredLanguage': 'en',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _db.collection(AppConstants.appointmentsCollection).doc('APT-${p['id']}').set({
          'appointmentId': 'APT-${p['id']}',
          'patientId': p['id'],
          'hospitalId': 'hosp_kandy',
          'departmentId': 'dept_pediatrics',
          'appointmentDate': dateStr,
          'startTime': '09:00 AM',
          'endTime': '01:00 PM',
          'status': 'booked',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _db.collection(AppConstants.queueEntriesCollection).doc('QE-${p['id']}').set({
          'queueSessionId': kandySessionId,
          'appointmentId': 'APT-${p['id']}',
          'patientId': p['id'],
          'patientName': p['name'],
          'tokenCode': p['token'],
          'tokenNumber': p['token'],
          'status': p['status'],
          'queuePosition': p['pos'],
          'estimatedWaitMinutes': ((p['pos'] as int) - 1) * 10,
          'priority': p['priority'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Initial Events & Consultations
      await _db.collection(AppConstants.queueEventsCollection).doc('EVT-pat-018').set({
        'eventId': 'EVT-pat-018',
        'queueSessionId': nhslSessionId,
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

      await _db.collection(AppConstants.consultationsCollection).doc('CNS-pat-018').set({
        'consultationId': 'CNS-pat-018',
        'appointmentId': 'APT-pat-018',
        'queueEntryId': 'QE-pat-018',
        'patientId': 'pat-018',
        'staffId': 'doc-silva-uid',
        'doctorId': 'doc-silva-uid',
        'hospitalId': 'nhsl',
        'departmentId': 'gen_med',
        'status': 'completed',
        'notes': 'Patient prescribed routine paracetamol and rest.',
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Cloud Firestore multi-hospital demo data populated successfully!');
      return true;
    } catch (e) {
      debugPrint('Error populating demo data: $e');
      return false;
    }
  }
}
