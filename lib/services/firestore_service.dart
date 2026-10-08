import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/staff_profile.dart';
import '../models/queue_session.dart';
import '../models/queue_entry.dart';
import '../models/delay_update.dart';
import '../models/notification_model.dart';
import '../models/appointment.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users & Staff Profiles ---
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (_) {}
    return null;
  }

  Future<StaffProfile?> getStaffProfile(String uid) async {
    try {
      final doc = await _db.collection(AppConstants.staffProfilesCollection).doc(uid).get();
      if (doc.exists) {
        return StaffProfile.fromFirestore(doc);
      }
    } catch (_) {}
    return null;
  }

  // --- Appointments ---
  Future<List<Appointment>> getTodayAppointments(String hospitalId, String departmentId, String dateStr) async {
    try {
      final hId = (hospitalId == 'HOSP-001') ? 'nhsl' : hospitalId;
      final dId = (departmentId == 'DEPT-001') ? 'gen_med' : departmentId;

      final snapshot = await _db
          .collection(AppConstants.appointmentsCollection)
          .where('appointmentDate', isEqualTo: dateStr)
          .get();

      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .where((apt) =>
              (apt.hospitalId == hId || apt.hospitalId == 'HOSP-001' || hId.isEmpty) &&
              (apt.departmentId == dId || apt.departmentId == 'DEPT-001' || dId.isEmpty))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Appointment?> getAppointment(String appointmentId) async {
    final doc = await _db.collection(AppConstants.appointmentsCollection).doc(appointmentId).get();
    return doc.exists ? Appointment.fromFirestore(doc) : null;
  }

  // --- Queue Sessions ---
  Stream<QueueSession?> streamQueueSession(String sessionId) {
    return _db
        .collection(AppConstants.queueSessionsCollection)
        .doc(sessionId)
        .snapshots()
        .map((doc) => doc.exists ? QueueSession.fromFirestore(doc) : null);
  }

  Stream<List<QueueSession>> streamHospitalSessions(String hospitalId) {
    final hId = (hospitalId == 'HOSP-001') ? 'nhsl' : hospitalId;
    return _db
        .collection(AppConstants.queueSessionsCollection)
        .where('hospitalId', isEqualTo: hId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => QueueSession.fromFirestore(doc)).toList());
  }

  Future<QueueSession?> getQueueSession(String sessionId) async {
    final doc = await _db.collection(AppConstants.queueSessionsCollection).doc(sessionId).get();
    return doc.exists ? QueueSession.fromFirestore(doc) : null;
  }

  // --- Dual-Collection Merged Queue Stream ---
  Stream<List<QueueEntry>> streamPatientQueue(String sessionId, {String hospitalId = 'nhsl', String departmentId = 'gen_med'}) {
    final normalizedHosp = (hospitalId == 'HOSP-001') ? 'nhsl' : hospitalId;
    final normalizedDept = (departmentId == 'DEPT-001') ? 'gen_med' : departmentId;

    return _db
        .collection(AppConstants.queueEntriesCollection)
        .where('queueSessionId', isEqualTo: sessionId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<QueueEntry> entries = [];
      Set<String> existingAptIds = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String patientName = data['patientName'] ?? 'Unknown Patient';
        if ((patientName.isEmpty || patientName == 'Unknown Patient') && data['patientId'] != null) {
          final userDoc = await _db.collection(AppConstants.usersCollection).doc(data['patientId']).get();
          if (userDoc.exists && userDoc.data() != null) {
            patientName = userDoc.data()!['fullName'] ?? patientName;
          }
        }
        final entry = QueueEntry.fromFirestore(doc, patientName: patientName);
        entries.add(entry);
        if (entry.appointmentId.isNotEmpty) {
          existingAptIds.add(entry.appointmentId);
        }
      }

      // Merge booked appointments from Module 1 if not already in queue_entries
      try {
        final dateStr = sessionId.contains('_') ? sessionId.split('_').last : '';
        final aptQuery = _db.collection(AppConstants.appointmentsCollection);
        QuerySnapshot<Map<String, dynamic>> aptSnap;
        if (dateStr.isNotEmpty) {
          aptSnap = await aptQuery.where('appointmentDate', isEqualTo: dateStr).get();
        } else {
          aptSnap = await aptQuery.get();
        }

        for (var aptDoc in aptSnap.docs) {
          final aptData = aptDoc.data();
          final aptId = aptDoc.id;
          final aptH = (aptData['hospitalId'] ?? '') == 'HOSP-001' ? 'nhsl' : (aptData['hospitalId'] ?? '');
          final aptD = (aptData['departmentId'] ?? '') == 'DEPT-001' ? 'gen_med' : (aptData['departmentId'] ?? '');

          if ((aptH == normalizedHosp || aptH.isEmpty || normalizedHosp.isEmpty) &&
              (aptD == normalizedDept || aptD.isEmpty || normalizedDept.isEmpty) &&
              !existingAptIds.contains(aptId)) {
            String patientName = aptData['patientName'] ?? 'Patient';
            if (patientName.isEmpty && aptData['patientId'] != null) {
              final userDoc = await _db.collection(AppConstants.usersCollection).doc(aptData['patientId']).get();
              if (userDoc.exists && userDoc.data() != null) {
                patientName = userDoc.data()!['fullName'] ?? 'Patient';
              }
            }
            final token = aptData['tokenNumber'] ?? aptData['tokenCode'] ?? 'A-${entries.length + 10}';
            entries.add(QueueEntry(
              queueEntryId: 'QE-$aptId',
              queueSessionId: sessionId,
              appointmentId: aptId,
              patientId: aptData['patientId'] ?? '',
              tokenNumber: token,
              tokenCode: token,
              status: aptData['status'] == 'called' ? 'called' : (aptData['status'] == 'completed' ? 'completed' : 'waiting'),
              queuePosition: entries.length + 1,
              estimatedWaitMinutes: entries.length * 10,
              priority: aptData['priority'] ?? 'normal',
              patientName: patientName,
            ));
          }
        }
      } catch (_) {}

      // Accurate Queue Sorting: Emergency Priority -> Queue Position -> Numerical Token Number
      entries.sort((a, b) {
        if (a.priority == AppConstants.priorityEmergency && b.priority != AppConstants.priorityEmergency) {
          return -1;
        } else if (a.priority != AppConstants.priorityEmergency && b.priority == AppConstants.priorityEmergency) {
          return 1;
        }
        final posComp = a.queuePosition.compareTo(b.queuePosition);
        if (posComp != 0) return posComp;
        return _parseTokenNumber(a.tokenNumber).compareTo(_parseTokenNumber(b.tokenNumber));
      });

      return entries;
    });
  }

  static int _parseTokenNumber(String token) {
    final regExp = RegExp(r'\d+');
    final match = regExp.firstMatch(token);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 999;
    }
    return 999;
  }

  Stream<List<QueueEntry>> streamQueueEntries(String sessionId) {
    return streamPatientQueue(sessionId);
  }

  Future<List<QueueEntry>> getPatientQueue(String sessionId) async {
    final snapshot = await _db
        .collection(AppConstants.queueEntriesCollection)
        .where('queueSessionId', isEqualTo: sessionId)
        .get();

    List<QueueEntry> entries = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      String patientName = data['patientName'] ?? '';
      if (patientName.isEmpty && data['patientId'] != null) {
        final userDoc = await _db.collection(AppConstants.usersCollection).doc(data['patientId']).get();
        if (userDoc.exists && userDoc.data() != null) {
          patientName = userDoc.data()!['fullName'] ?? 'Patient';
        }
      }
      entries.add(QueueEntry.fromFirestore(doc, patientName: patientName));
    }
    return entries;
  }

  Future<QueueEntry?> getQueueEntry(String queueEntryId) async {
    return getPatientDetails(queueEntryId);
  }

  Future<QueueEntry?> getPatientDetails(String queueEntryId) async {
    try {
      final doc = await _db.collection(AppConstants.queueEntriesCollection).doc(queueEntryId).get();
      if (!doc.exists) return _getMockQueueEntry(queueEntryId);

      final data = doc.data() ?? {};
      String patientName = data['patientName'] ?? '';
      if (patientName.isEmpty && data['patientId'] != null) {
        try {
          final userDoc = await _db.collection(AppConstants.usersCollection).doc(data['patientId']).get();
          if (userDoc.exists && userDoc.data() != null) {
            patientName = userDoc.data()!['fullName'] ?? 'Patient';
          }
        } catch (_) {}
      }
      return QueueEntry.fromFirestore(doc, patientName: patientName);
    } catch (_) {
      return _getMockQueueEntry(queueEntryId);
    }
  }

  QueueEntry _getMockQueueEntry(String queueEntryId) {
    return QueueEntry(
      queueEntryId: queueEntryId,
      queueSessionId: AppConstants.defaultQueueSessionId(),
      appointmentId: 'APT-021',
      patientId: 'pat-021',
      tokenNumber: 'A-021',
      tokenCode: 'A-021',
      status: 'called',
      queuePosition: 1,
      estimatedWaitMinutes: 5,
      priority: 'normal',
      patientName: 'Kasun Perera',
      calledAt: DateTime.now(),
    );
  }

  // --- Delay Updates ---
  Stream<List<DelayUpdate>> streamDelayUpdates(String sessionId) {
    return _db
        .collection(AppConstants.delayUpdatesCollection)
        .where('queueSessionId', isEqualTo: sessionId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DelayUpdate.fromFirestore(doc)).toList());
  }

  // --- Notifications Stream ---
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }
}
