import 'package:cloud_firestore/cloud_firestore.dart';
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

      // 2. Staff Users & Profiles
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

      // 3. Patient Users & Appointments
      final patients = [
        {'id': 'pat-018', 'name': 'Nimal Perera', 'phone': '0711111111', 'token': 'A-018', 'status': 'completed', 'priority': 'normal', 'pos': 1},
        {'id': 'pat-019', 'name': 'Nimali Wijesekera', 'phone': '0712222222', 'token': 'A-019', 'status': 'called', 'priority': 'normal', 'pos': 2},
        {'id': 'pat-020', 'name': 'Suresh Kumar', 'phone': '0713333333', 'token': 'A-020', 'status': 'on_hold', 'priority': 'normal', 'pos': 3},
        {'id': 'pat-021', 'name': 'Chamari D.', 'phone': '0714444444', 'token': 'A-021', 'status': 'waiting', 'priority': 'normal', 'pos': 4},
        {'id': 'pat-022', 'name': 'Ranjith M.', 'phone': '0715555555', 'token': 'A-022', 'status': 'waiting', 'priority': 'normal', 'pos': 5},
        {'id': 'pat-025', 'name': 'Amal R.', 'phone': '0716666666', 'token': 'A-025', 'status': 'waiting', 'priority': 'emergency', 'pos': 6},
      ];

      for (var p in patients) {
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

        // Create appointment doc (shared with Module 1)
        await _db.collection(AppConstants.appointmentsCollection).doc('APT-${p['id']}').set({
          'appointmentId': 'APT-${p['id']}',
          'patientId': p['id'],
          'caregiverId': '',
          'caregiverPatientId': '',
          'hospitalId': hospitalId,
          'departmentId': departmentId,
          'slotId': 'SLOT-001',
          'appointmentDate': dateStr,
          'startTime': '08:30 AM',
          'endTime': '12:30 PM',
          'status': p['status'] == 'completed' ? 'completed' : (p['status'] == 'called' ? 'called' : 'booked'),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 4. Queue Session (Write both dynamic ID and QS-001 doc for compatibility)
      final sessionMap = {
        'queueSessionId': dynamicSessionId,
        'hospitalId': hospitalId,
        'departmentId': departmentId,
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
      };

      await _db.collection(AppConstants.queueSessionsCollection).doc(dynamicSessionId).set(sessionMap);
      await _db.collection(AppConstants.queueSessionsCollection).doc('QS-001').set({...sessionMap, 'queueSessionId': 'QS-001'});

      // 5. Queue Entries
      for (var p in patients) {
        final entryMap = {
          'queueSessionId': dynamicSessionId,
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
        };

        await _db.collection(AppConstants.queueEntriesCollection).doc('QE-${p['id']}').set(entryMap);
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
